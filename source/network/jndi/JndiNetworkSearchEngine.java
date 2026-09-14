package network.jndi;

import javax.naming.*;
import javax.naming.directory.*;
import javax.naming.ldap.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * JndiNetworkSearchEngine — JNDI-based network service discovery and stability lookups.
 *
 * Uses Java Naming and Directory Interface for:
 *   - DNS SRV record lookups (service discovery)
 *   - DNS MX record lookups (mail server routing)
 *   - DNS A/AAAA record lookups (host resolution with redundancy check)
 *   - DNS TXT record lookups (SPF, DKIM, service metadata)
 *   - DNS NS record lookups (authoritative nameserver discovery)
 *   - DNS PTR lookups (reverse DNS for connection identity)
 *   - LDAP directory searches (enterprise service registry)
 *   - Network service health via DNS response timing
 *   - Multi-resolver stability assessment
 *
 * JNDI is built into the JDK (javax.naming / jakarta.naming).
 * No external JAR required.
 *
 * Usage:
 *   JndiNetworkSearchEngine engine = new JndiNetworkSearchEngine();
 *   List<ServiceRecord> services = engine.discoverServices("_http._tcp.example.com");
 *   DnsStabilityReport stability = engine.assessDnsStability("example.com");
 *
 * @author Max Rupplin — MEARVK LLC
 * @since Galactic Cherry Marvell Edition 98
 */
public class JndiNetworkSearchEngine {

    // ═══ Constants ═══════════════════════════════════════════════════════════
    private static final String DNS_PROVIDER     = "dns:";
    private static final String DNS_FACTORY      = "com.sun.jndi.dns.DnsContextFactory";
    private static final String LDAP_FACTORY     = "com.sun.jndi.ldap.LdapCtxFactory";
    private static final int    DEFAULT_TIMEOUT  = 5000; // ms
    private static final int    STABILITY_ROUNDS = 10;   // number of queries for stability check

    // ═══ DNS Resolvers (fallback chain) ═════════════════════════════════════
    private static final String[] PUBLIC_RESOLVERS = {
            "dns://8.8.8.8",            // Google Public DNS
            "dns://8.8.4.4",            // Google Public DNS (secondary)
            "dns://1.1.1.1",            // Cloudflare
            "dns://1.0.0.1",            // Cloudflare (secondary)
            "dns://9.9.9.9",            // Quad9
            "dns://208.67.222.222",     // OpenDNS
    };

    private final int timeoutMs;
    private final ExecutorService executor;

    // ═══ Constructors ════════════════════════════════════════════════════════

    public JndiNetworkSearchEngine() {
        this(DEFAULT_TIMEOUT);
    }

    public JndiNetworkSearchEngine(int timeoutMs) {
        this.timeoutMs = timeoutMs;
        this.executor = Executors.newFixedThreadPool(4,
                r -> { Thread t = new Thread(r, "JNDI-Search"); t.setDaemon(true); return t; });
    }

    // ═══ DNS Service Discovery ═══════════════════════════════════════════════

    /**
     * Discover services via DNS SRV records.
     * Example: discoverServices("_http._tcp.example.com")
     */
    public List<ServiceRecord> discoverServices(String serviceName) {
        List<ServiceRecord> results = new ArrayList<>();
        try {
            DirContext ctx = createDnsContext(null);
            Attributes attrs = ctx.getAttributes(serviceName, new String[]{"SRV"});
            Attribute srvAttr = attrs.get("SRV");

            if (srvAttr != null) {
                NamingEnumeration<?> values = srvAttr.getAll();
                while (values.hasMore()) {
                    String record = (String) values.next();
                    ServiceRecord sr = parseSrvRecord(record, serviceName);
                    if (sr != null) results.add(sr);
                }
                values.close();
            }
            ctx.close();
        } catch (NamingException e) {
            System.err.println("[JndiNetworkSearchEngine] SRV lookup failed for "
                    + serviceName + ": " + e.getMessage());
        }
        // Sort by priority (lower = better), then by weight (higher = preferred)
        results.sort(Comparator.comparingInt((ServiceRecord s) -> s.priority)
                .thenComparingInt(s -> -s.weight));
        return results;
    }

    /**
     * Look up MX records for email routing.
     */
    public List<MailExchangeRecord> lookupMX(String domain) {
        List<MailExchangeRecord> results = new ArrayList<>();
        try {
            DirContext ctx = createDnsContext(null);
            Attributes attrs = ctx.getAttributes(domain, new String[]{"MX"});
            Attribute mxAttr = attrs.get("MX");

            if (mxAttr != null) {
                NamingEnumeration<?> values = mxAttr.getAll();
                while (values.hasMore()) {
                    String record = (String) values.next();
                    MailExchangeRecord mx = parseMxRecord(record, domain);
                    if (mx != null) results.add(mx);
                }
                values.close();
            }
            ctx.close();
        } catch (NamingException e) {
            System.err.println("[JndiNetworkSearchEngine] MX lookup failed for "
                    + domain + ": " + e.getMessage());
        }
        results.sort(Comparator.comparingInt(m -> m.priority));
        return results;
    }

    /**
     * Resolve A records (IPv4 addresses) for a hostname.
     */
    public List<String> resolveA(String hostname) {
        return resolveRecordType(hostname, "A");
    }

    /**
     * Resolve AAAA records (IPv6 addresses) for a hostname.
     */
    public List<String> resolveAAAA(String hostname) {
        return resolveRecordType(hostname, "AAAA");
    }

    /**
     * Look up TXT records (SPF, DKIM, service metadata).
     */
    public List<String> lookupTXT(String domain) {
        return resolveRecordType(domain, "TXT");
    }

    /**
     * Look up NS records (authoritative nameservers).
     */
    public List<String> lookupNS(String domain) {
        return resolveRecordType(domain, "NS");
    }

    /**
     * Reverse DNS lookup (PTR record).
     */
    public String reverseLookup(String ipAddress) {
        try {
            String reverseName = buildReverseName(ipAddress);
            DirContext ctx = createDnsContext(null);
            Attributes attrs = ctx.getAttributes(reverseName, new String[]{"PTR"});
            Attribute ptrAttr = attrs.get("PTR");
            if (ptrAttr != null) {
                String result = (String) ptrAttr.get();
                ctx.close();
                return result;
            }
            ctx.close();
        } catch (NamingException e) {
            // PTR not found — common
        }
        return null;
    }

    /**
     * Comprehensive DNS lookup — all record types at once.
     */
    public DnsLookupResult fullLookup(String domain) {
        DnsLookupResult result = new DnsLookupResult();
        result.domain = domain;
        result.timestamp = System.currentTimeMillis();

        long start = System.nanoTime();
        result.aRecords = resolveA(domain);
        result.aaaaRecords = resolveAAAA(domain);
        result.mxRecords = lookupMX(domain);
        result.nsRecords = lookupNS(domain);
        result.txtRecords = lookupTXT(domain);
        result.srvRecords = discoverServices(domain);
        result.queryTimeMs = (System.nanoTime() - start) / 1_000_000;

        return result;
    }

    // ═══ DNS Stability Assessment ════════════════════════════════════════════

    /**
     * Assess DNS resolution stability by querying multiple resolvers
     * and measuring consistency and response times.
     */
    public DnsStabilityReport assessDnsStability(String domain) {
        DnsStabilityReport report = new DnsStabilityReport();
        report.domain = domain;
        report.timestamp = System.currentTimeMillis();

        List<ResolverResult> resolverResults = new ArrayList<>();

        for (String resolver : PUBLIC_RESOLVERS) {
            ResolverResult rr = new ResolverResult();
            rr.resolver = resolver;

            long[] responseTimes = new long[STABILITY_ROUNDS];
            Set<String> answers = new HashSet<>();
            int failures = 0;

            for (int i = 0; i < STABILITY_ROUNDS; i++) {
                long start = System.nanoTime();
                try {
                    DirContext ctx = createDnsContext(resolver);
                    Attributes attrs = ctx.getAttributes(domain, new String[]{"A"});
                    Attribute aAttr = attrs.get("A");
                    if (aAttr != null) {
                        NamingEnumeration<?> values = aAttr.getAll();
                        while (values.hasMore()) {
                            answers.add((String) values.next());
                        }
                        values.close();
                    }
                    ctx.close();
                    responseTimes[i] = (System.nanoTime() - start) / 1_000_000;
                } catch (NamingException e) {
                    failures++;
                    responseTimes[i] = timeoutMs; // timeout
                }
            }

            rr.answers = new ArrayList<>(answers);
            rr.failures = failures;
            rr.avgResponseMs = Arrays.stream(responseTimes).average().orElse(0);
            rr.minResponseMs = Arrays.stream(responseTimes).min().orElse(0);
            rr.maxResponseMs = Arrays.stream(responseTimes).max().orElse(0);

            // Jitter = stddev of response times
            double mean = rr.avgResponseMs;
            double variance = Arrays.stream(responseTimes)
                    .mapToDouble(t -> (t - mean) * (t - mean))
                    .average().orElse(0);
            rr.jitterMs = Math.sqrt(variance);

            resolverResults.add(rr);
        }

        report.resolverResults = resolverResults;

        // Check consistency across resolvers
        Set<String> allAnswers = new HashSet<>();
        for (ResolverResult rr : resolverResults) {
            allAnswers.addAll(rr.answers);
        }
        report.consistentAnswers = allAnswers.size() <= (resolverResults.isEmpty() ? 0 :
                resolverResults.stream().mapToInt(r -> r.answers.size()).max().orElse(0) + 1);

        // Overall stability score
        int score = 100;
        for (ResolverResult rr : resolverResults) {
            if (rr.failures > 0) score -= (rr.failures * 5);
            if (rr.jitterMs > 100) score -= 10;
            if (rr.avgResponseMs > 500) score -= 5;
        }
        if (!report.consistentAnswers) score -= 20;
        report.stabilityScore = Math.max(0, Math.min(100, score));

        return report;
    }

    // ═══ LDAP Directory Search ═══════════════════════════════════════════════

    /**
     * Search an LDAP directory for services or resources.
     *
     * @param ldapUrl    e.g. "ldap://ldap.example.com:389"
     * @param baseDn     e.g. "dc=example,dc=com"
     * @param filter     LDAP filter, e.g. "(objectClass=nweService)"
     * @param attributes attributes to retrieve, e.g. ["cn", "host", "port"]
     */
    public List<Map<String, String>> searchLdap(String ldapUrl, String baseDn,
                                                 String filter, String[] attributes) {
        List<Map<String, String>> results = new ArrayList<>();
        Hashtable<String, String> env = new Hashtable<>();
        env.put(Context.INITIAL_CONTEXT_FACTORY, LDAP_FACTORY);
        env.put(Context.PROVIDER_URL, ldapUrl);
        env.put("com.sun.jndi.ldap.connect.timeout", String.valueOf(timeoutMs));
        env.put("com.sun.jndi.ldap.read.timeout", String.valueOf(timeoutMs));

        try {
            DirContext ctx = new InitialDirContext(env);
            SearchControls controls = new SearchControls();
            controls.setSearchScope(SearchControls.SUBTREE_SCOPE);
            controls.setReturningAttributes(attributes);
            controls.setTimeLimit(timeoutMs);

            NamingEnumeration<SearchResult> searchResults = ctx.search(baseDn, filter, controls);
            while (searchResults.hasMore()) {
                SearchResult sr = searchResults.next();
                Attributes attrs = sr.getAttributes();
                Map<String, String> entry = new LinkedHashMap<>();
                entry.put("dn", sr.getNameInNamespace());

                NamingEnumeration<? extends Attribute> attrEnum = attrs.getAll();
                while (attrEnum.hasMore()) {
                    Attribute attr = attrEnum.next();
                    entry.put(attr.getID(), attr.get().toString());
                }
                attrEnum.close();
                results.add(entry);
            }
            searchResults.close();
            ctx.close();
        } catch (NamingException e) {
            System.err.println("[JndiNetworkSearchEngine] LDAP search failed: " + e.getMessage());
        }
        return results;
    }

    /**
     * Register a service in LDAP directory.
     */
    public boolean registerService(String ldapUrl, String baseDn,
                                   String serviceName, String host, int port,
                                   String bindDn, String bindPassword) {
        Hashtable<String, String> env = new Hashtable<>();
        env.put(Context.INITIAL_CONTEXT_FACTORY, LDAP_FACTORY);
        env.put(Context.PROVIDER_URL, ldapUrl);
        env.put(Context.SECURITY_AUTHENTICATION, "simple");
        env.put(Context.SECURITY_PRINCIPAL, bindDn);
        env.put(Context.SECURITY_CREDENTIALS, bindPassword);
        env.put("com.sun.jndi.ldap.connect.timeout", String.valueOf(timeoutMs));

        try {
            DirContext ctx = new InitialDirContext(env);

            BasicAttributes attrs = new BasicAttributes(true);
            attrs.put("objectClass", "nweService");
            attrs.put("cn", serviceName);
            attrs.put("host", host);
            attrs.put("port", String.valueOf(port));
            attrs.put("registeredAt", String.valueOf(System.currentTimeMillis()));
            attrs.put("status", "active");

            String dn = "cn=" + serviceName + "," + baseDn;
            ctx.createSubcontext(dn, attrs);
            ctx.close();
            return true;
        } catch (NamingException e) {
            System.err.println("[JndiNetworkSearchEngine] Service registration failed: " + e.getMessage());
            return false;
        }
    }

    // ═══ JNDI Context Lookups (for application servers) ═════════════════════

    /**
     * Look up a resource in a JNDI naming context (e.g., DataSource, JMS queue).
     */
    public Object lookupResource(String jndiName) {
        try {
            Context ctx = new InitialContext();
            Object result = ctx.lookup(jndiName);
            ctx.close();
            return result;
        } catch (NamingException e) {
            System.err.println("[JndiNetworkSearchEngine] JNDI lookup failed for "
                    + jndiName + ": " + e.getMessage());
            return null;
        }
    }

    /**
     * List all bindings in a JNDI context.
     */
    public Map<String, String> listBindings(String contextPath) {
        Map<String, String> bindings = new LinkedHashMap<>();
        try {
            Context ctx = new InitialContext();
            NamingEnumeration<Binding> ne = ctx.listBindings(contextPath);
            while (ne.hasMore()) {
                Binding b = ne.next();
                bindings.put(b.getName(), b.getClassName());
            }
            ne.close();
            ctx.close();
        } catch (NamingException e) {
            System.err.println("[JndiNetworkSearchEngine] listBindings failed: " + e.getMessage());
        }
        return bindings;
    }

    // ═══ Shutdown ════════════════════════════════════════════════════════════

    public void shutdown() {
        executor.shutdown();
        try { executor.awaitTermination(5, TimeUnit.SECONDS); } catch (InterruptedException ignored) {}
    }

    // ═══ Internal Helpers ════════════════════════════════════════════════════

    private DirContext createDnsContext(String resolverUrl) throws NamingException {
        Hashtable<String, String> env = new Hashtable<>();
        env.put(Context.INITIAL_CONTEXT_FACTORY, DNS_FACTORY);
        if (resolverUrl != null) {
            env.put(Context.PROVIDER_URL, resolverUrl);
        }
        env.put("com.sun.jndi.dns.timeout.initial", String.valueOf(timeoutMs));
        env.put("com.sun.jndi.dns.timeout.retries", "2");
        return new InitialDirContext(env);
    }

    private List<String> resolveRecordType(String name, String type) {
        List<String> results = new ArrayList<>();
        try {
            DirContext ctx = createDnsContext(null);
            Attributes attrs = ctx.getAttributes(name, new String[]{type});
            Attribute attr = attrs.get(type);
            if (attr != null) {
                NamingEnumeration<?> values = attr.getAll();
                while (values.hasMore()) {
                    results.add(values.next().toString());
                }
                values.close();
            }
            ctx.close();
        } catch (NamingException e) {
            // Record type not found — not an error
        }
        return results;
    }

    private ServiceRecord parseSrvRecord(String record, String serviceName) {
        // SRV format: priority weight port target
        String[] parts = record.trim().split("\\s+");
        if (parts.length >= 4) {
            ServiceRecord sr = new ServiceRecord();
            sr.serviceName = serviceName;
            sr.priority = Integer.parseInt(parts[0]);
            sr.weight = Integer.parseInt(parts[1]);
            sr.port = Integer.parseInt(parts[2]);
            sr.target = parts[3];
            return sr;
        }
        return null;
    }

    private MailExchangeRecord parseMxRecord(String record, String domain) {
        // MX format: priority host
        String[] parts = record.trim().split("\\s+");
        if (parts.length >= 2) {
            MailExchangeRecord mx = new MailExchangeRecord();
            mx.domain = domain;
            mx.priority = Integer.parseInt(parts[0]);
            mx.host = parts[1];
            return mx;
        }
        return null;
    }

    private String buildReverseName(String ipAddress) {
        // For IPv4: reverse octets and append .in-addr.arpa
        String[] octets = ipAddress.split("\\.");
        if (octets.length == 4) {
            return octets[3] + "." + octets[2] + "." + octets[1] + "." + octets[0] + ".in-addr.arpa";
        }
        // IPv6: not implemented here (use full nibble format)
        return ipAddress;
    }

    // ═══ Data Classes ════════════════════════════════════════════════════════

    /**
     * DNS SRV service record.
     */
    public static class ServiceRecord {
        public String serviceName;
        public int priority;
        public int weight;
        public int port;
        public String target;

        @Override
        public String toString() {
            return target + ":" + port + " (pri=" + priority + " w=" + weight + ")";
        }
    }

    /**
     * Mail exchange record.
     */
    public static class MailExchangeRecord {
        public String domain;
        public int priority;
        public String host;

        @Override
        public String toString() {
            return host + " (pri=" + priority + ")";
        }
    }

    /**
     * Full DNS lookup result for a domain.
     */
    public static class DnsLookupResult {
        public String domain;
        public long timestamp;
        public long queryTimeMs;
        public List<String> aRecords;
        public List<String> aaaaRecords;
        public List<MailExchangeRecord> mxRecords;
        public List<String> nsRecords;
        public List<String> txtRecords;
        public List<ServiceRecord> srvRecords;

        @Override
        public String toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("DNS Lookup: ").append(domain).append(" (").append(queryTimeMs).append("ms)\n");
            if (!aRecords.isEmpty()) sb.append("  A:    ").append(aRecords).append("\n");
            if (!aaaaRecords.isEmpty()) sb.append("  AAAA: ").append(aaaaRecords).append("\n");
            if (!mxRecords.isEmpty()) sb.append("  MX:   ").append(mxRecords).append("\n");
            if (!nsRecords.isEmpty()) sb.append("  NS:   ").append(nsRecords).append("\n");
            if (!txtRecords.isEmpty()) sb.append("  TXT:  ").append(txtRecords).append("\n");
            if (!srvRecords.isEmpty()) sb.append("  SRV:  ").append(srvRecords).append("\n");
            return sb.toString();
        }
    }

    /**
     * Per-resolver result in stability assessment.
     */
    public static class ResolverResult {
        public String resolver;
        public List<String> answers;
        public int failures;
        public double avgResponseMs;
        public long minResponseMs;
        public long maxResponseMs;
        public double jitterMs;

        @Override
        public String toString() {
            return resolver + " — avg=" + String.format("%.1f", avgResponseMs)
                    + "ms jitter=" + String.format("%.1f", jitterMs)
                    + "ms failures=" + failures;
        }
    }

    /**
     * DNS stability report across multiple resolvers.
     */
    public static class DnsStabilityReport {
        public String domain;
        public long timestamp;
        public int stabilityScore;
        public boolean consistentAnswers;
        public List<ResolverResult> resolverResults;

        @Override
        public String toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("╔══════════════════════════════════════════════════╗\n");
            sb.append("║  DNS Stability Report                           ║\n");
            sb.append("╠══════════════════════════════════════════════════╣\n");
            sb.append(String.format("║  Domain:      %-34s║\n", domain));
            sb.append(String.format("║  Score:       %-34s║\n", stabilityScore + "/100"));
            sb.append(String.format("║  Consistent:  %-34s║\n", consistentAnswers ? "YES" : "NO"));
            sb.append("╠══════════════════════════════════════════════════╣\n");
            for (ResolverResult rr : resolverResults) {
                sb.append(String.format("║  %-46s  ║\n", rr.toString()));
            }
            sb.append("╚══════════════════════════════════════════════════╝\n");
            return sb.toString();
        }
    }
}
