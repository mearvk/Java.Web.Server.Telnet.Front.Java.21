/**
 * HeuristicClassifier — multi-port, extensible traffic classifier.
 *
 * Analyses inbound connection events across any of the server's public ports
 * and produces a Classification with a threat score (0–100) and findings list.
 *
 * Extensibility model:
 *   • Extend  AbstractHeuristic   to add new scoring rules (inherits port-set, findings API).
 *   • Implement IHeuristicModule  to plug in entirely independent classification modules.
 *   • Register both kinds via HeuristicClassifier.register(…).
 *
 * Built-in rules:
 *   • Repetition / rapid connection from a single IP (rate heuristic).
 *   • Geo-location concentration — many connections from same country.
 *   • Port scan detection — same IP hitting multiple distinct ports.
 *   • Basic payload pattern flags (known bad keywords).
 *
 * @author Max Rupplin
 * @date June 08 2026 EST
 */
package heuristics;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

public class HeuristicClassifier
{
    // ── Known public ports ────────────────────────────────────────────────────
    public static final Set<Integer> PUBLIC_PORTS = Set.of(
        49152,  // NitroWebExpress base / telnet proxy
        5512,   // AES2 WebExpress (EncryptionModule)
        6682,   // Bitcoin WebExpress (TraderModule)
        7743,   // RSACompliant
        7744,   // DSACompliant
        49111,  // AIProctorModule
        49122,  // WhiteAuditorTasking
        49133,  // WeatherServer
        49144,  // BinaryHttpServer
        49155,  // ConnectionStatusServer
        49166,  // ModuleInstallationService
        49177,  // ASCIICreatorServer
        49188,  // ModuleLoaderDaemon
        49199,  // Communicator
        49200   // TerminalMenu (Lanterna)
    );

    // ── Thresholds ────────────────────────────────────────────────────────────
    private static final int    RATE_WINDOW_SECS   = 60;
    private static final int    RATE_LIMIT          = 20;   // connections / window / IP
    private static final int    GEO_CONCENTRATION   = 30;   // % of total before flagging
    private static final int    PORT_SCAN_THRESHOLD = 3;    // distinct ports before flagging

    // ── Registered extension modules ──────────────────────────────────────────
    private static final List<IHeuristicModule> modules = new CopyOnWriteArrayList<>();

    // ── Per-IP & per-country connection tracking (in-memory, rolling) ─────────
    // Structure: IP -> list of epoch-second timestamps
    private final Map<String, List<Long>> ipTimestamps      = new ConcurrentHashMap<>();
    // Structure: IP -> set of ports seen
    private final Map<String, Set<Integer>> ipPorts         = new ConcurrentHashMap<>();
    // Structure: countryCode -> count
    private final Map<String, Integer> countryCount         = new ConcurrentHashMap<>();
    private int totalConnections = 0;

    // ─────────────────────────────────────────────────────────────────────────
    // Extensibility model
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Implement this interface (keyword: implements IHeuristicModule) to register
     * a fully independent scoring module that receives every connection event.
     */
    public interface IHeuristicModule
    {
        /** Called once per inbound connection event; add findings and return score delta (0–100). */
        int evaluate(ConnectionEvent event, List<String> findings);
        String moduleName();
    }

    /**
     * Extend this class (keyword: extends AbstractHeuristic) to build a reusable
     * heuristic that has built-in access to port membership helpers and the findings API.
     */
    public static abstract class AbstractHeuristic implements IHeuristicModule
    {
        /** Returns true if the event arrived on one of the known public ports. */
        protected boolean isPublicPort(final ConnectionEvent event)
        {
            return PUBLIC_PORTS.contains(event.port);
        }

        /** Convenience: add a WARNING finding and return a score penalty. */
        protected int warn(final String message, final int penalty, final List<String> findings)
        {
            findings.add("WARN  " + message);
            return penalty;
        }

        /** Convenience: add a PASS finding with zero penalty. */
        protected int pass(final String message, final List<String> findings)
        {
            findings.add("PASS  " + message);
            return 0;
        }
    }

    /** Register an IHeuristicModule or AbstractHeuristic (both implement the interface). */
    public static void register(final IHeuristicModule module)
    {
        if (module == null) throw new IllegalArgumentException("null module");
        modules.add(module);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Public API
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Classify a single inbound connection event.
     *
     * @param event  the connection to analyse
     * @return       Classification with threat score and findings
     */
    public Classification classify(final ConnectionEvent event)
    {
        Objects.requireNonNull(event, "event must not be null");

        List<String> findings = new ArrayList<>();
        int score = 0;

        // ── 1. Port membership check ──────────────────────────────────────────
        if (!PUBLIC_PORTS.contains(event.port))
        {
            findings.add("INFO  port " + event.port + " not in known public-port set");
        }
        else
        {
            findings.add("PASS  recognised public port " + event.port);
        }

        // ── 2. IP repetition / rate heuristic ────────────────────────────────
        score += checkIpRate(event, findings);

        // ── 3. Port-scan detection ────────────────────────────────────────────
        score += checkPortScan(event, findings);

        // ── 4. Geo-location concentration ────────────────────────────────────
        score += checkGeoConcentration(event, findings);

        // ── 5. Payload keyword scan ───────────────────────────────────────────
        score += checkPayload(event, findings);

        // ── 6. Extension modules ──────────────────────────────────────────────
        for (IHeuristicModule module : modules)
        {
            try
            {
                int delta = module.evaluate(event, findings);

                score += Math.max(0, Math.min(delta, 100));

                findings.add("MOD   [" + module.moduleName() + "] returned delta=" + delta);
            }
            catch (Exception e)
            {
                findings.add("ERR   [" + module.moduleName() + "] threw: " + e.getMessage());
            }
        }

        // Update tracking state
        recordConnection(event);

        return new Classification(event, Math.min(score, 100), List.copyOf(findings));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Built-in heuristic rules
    // ─────────────────────────────────────────────────────────────────────────

    /** IP rate: count connections from this IP within the last RATE_WINDOW_SECS. */
    private int checkIpRate(final ConnectionEvent event, final List<String> findings)
    {
        long now = Instant.now().getEpochSecond();
        long cutoff = now - RATE_WINDOW_SECS;

        List<Long> times = ipTimestamps.computeIfAbsent(event.ip, k -> new ArrayList<>());
        synchronized (times)
        {
            times.removeIf(t -> t < cutoff);
            int count = times.size();

            if (count >= RATE_LIMIT)
            {
                findings.add("WARN  IP " + event.ip + " made " + count + " connections in the last " + RATE_WINDOW_SECS + "s (threshold=" + RATE_LIMIT + ") — rate limited");

                return 40;
            }
            else if (count >= RATE_LIMIT / 2)
            {
                findings.add("INFO  IP " + event.ip + " connection count approaching limit (" + count + "/" + RATE_LIMIT + ")");

                return 15;
            }
        }
        findings.add("PASS  IP " + event.ip + " within connection rate");
        return 0;
    }

    /** Port scan: same IP connecting to multiple distinct ports. */
    private int checkPortScan(final ConnectionEvent event, final List<String> findings)
    {
        Set<Integer> ports = ipPorts.computeIfAbsent(event.ip, k -> ConcurrentHashMap.newKeySet());

        ports.add(event.port);

        int distinct = ports.size();

        if (distinct >= PORT_SCAN_THRESHOLD)
        {
            findings.add("WARN  IP " + event.ip + " has probed " + distinct + " distinct ports " + ports + " — possible port scan");

            return 30;
        }

        findings.add("PASS  IP " + event.ip + " port probe count normal (" + distinct + ")");

        return 0;
    }

    /** Geo concentration: flag when one country makes up > GEO_CONCENTRATION % of all connections. */
    private int checkGeoConcentration(final ConnectionEvent event, final List<String> findings)
    {
        if (event.countryCode == null || event.countryCode.isBlank())
        {
            findings.add("INFO  no geo-location data available for " + event.ip);

            return 0;
        }

        int total = totalConnections + 1; // +1 for current event

        int fromCountry = countryCount.getOrDefault(event.countryCode, 0) + 1;

        int pct = (fromCountry * 100) / total;

        if (pct >= GEO_CONCENTRATION && total > 5) // require minimum sample
        {
            findings.add("WARN  " + pct + "% of connections originate from " + event.countryCode + " (" + fromCountry + "/" + total + ") — geo concentration flag");

            return 20;
        }

        findings.add("PASS  geo distribution normal for " + event.countryCode + " (" + pct + "%)");

        return 0;
    }

    /** Payload scan: flag known dangerous keywords in the request payload. */
    private static final List<String> BAD_KEYWORDS = List.of(
        "exec(", "Runtime.getRuntime", "ProcessBuilder", "../", "passwd", "shadow",
        "<script>", "SELECT ", "DROP TABLE", "UNION SELECT"
    );

    // Patterns indicating large memory allocation attempts in submitted source/payload
    private static final List<String> LARGE_ALLOC_PATTERNS = List.of(
        "new byte[", "new int[", "new long[", "new char[", "new Object[",
        "Integer.MAX_VALUE", "Long.MAX_VALUE", "1<<30", "1 << 30", "1<<31", "1 << 31"
    );

    // Patterns indicating spin loops
    private static final List<String> SPIN_LOOP_PATTERNS = List.of(
        "while(true)", "while (true)", "for(;;)", "for ( ; ; )", "for(; ;)",
        "}while(true)", "} while (true)"
    );

    // System binary execution paths
    private static final List<String> SYS_BINARY_PATTERNS = List.of(
        "\"/usr/bin/", "\"/bin/", "\"/sbin/", "\"/usr/sbin/", "\"/usr/local/bin/", "exec(\"/"
    );

    private int checkPayload(final ConnectionEvent event, final List<String> findings)
    {
        if (event.payload == null || event.payload.isBlank())
        {
            findings.add("INFO  no payload to inspect for " + event.ip);
            return 0;
        }

        String lower = event.payload.toLowerCase();
        int penalty = 0;

        // ── Standard bad keywords ─────────────────────────────────────────────
        for (String kw : BAD_KEYWORDS)
        {
            if (lower.contains(kw.toLowerCase()))
            {
                findings.add("WARN  payload contains flagged keyword: [" + kw + "]");
                penalty += 15;
            }
        }

        // ── Large memory allocation ───────────────────────────────────────────
        for (String pat : LARGE_ALLOC_PATTERNS)
        {
            if (event.payload.contains(pat))
            {
                findings.add("WARN  payload contains large-allocation pattern: [" + pat + "] — possible memory exhaustion");
                penalty += 20;
                break;
            }
        }

        // ── Spin loop ─────────────────────────────────────────────────────────
        for (String pat : SPIN_LOOP_PATTERNS)
        {
            if (event.payload.contains(pat))
            {
                findings.add("WARN  payload contains spin-loop pattern: [" + pat + "] — possible CPU exhaustion");
                penalty += 25;
                break;
            }
        }

        // ── System binary execution ───────────────────────────────────────────
        for (String pat : SYS_BINARY_PATTERNS)
        {
            if (event.payload.contains(pat))
            {
                findings.add("WARN  payload references system binary path: [" + pat + "] — possible privilege escalation");
                penalty += 30;
                break;
            }
        }

        // ── Constructor with loop (source-level pattern in payload) ───────────
        if (event.payload.matches("(?s).*public\\s+\\w+\\s*\\([^)]*\\)\\s*\\{[^}]*(while|for\\s*\\(|do\\s*\\{)[^}]*\\}.*")
            && !event.payload.contains("break") && !event.payload.contains("return"))
        {
            findings.add("WARN  payload contains a constructor with a loop and no visible exit — possible constructor hang");
            penalty += 20;
        }

        if (penalty == 0) findings.add("PASS  payload keyword scan clean");
        return penalty;
    }

    /** Update tracking structures after a connection has been classified. */
    private void recordConnection(final ConnectionEvent event)
    {
        long now = Instant.now().getEpochSecond();
        ipTimestamps.computeIfAbsent(event.ip, k -> new ArrayList<>()).add(now);
        totalConnections++;
        if (event.countryCode != null && !event.countryCode.isBlank())
            countryCount.merge(event.countryCode, 1, Integer::sum);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Data types
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Describes a single inbound connection event on any public port.
     * Build with the constructor or the fluent Builder.
     */
    public static final class ConnectionEvent
    {
        public final String  ip;
        public final int     port;
        public final String  countryCode;  // ISO-3166 alpha-2, e.g. "US", "CN" — may be null
        public final String  payload;      // raw request snippet — may be null

        public ConnectionEvent(final String ip, final int port, final String countryCode, final String payload)
        {
            this.ip          = Objects.requireNonNull(ip, "ip");
            this.port        = port;
            this.countryCode = countryCode;
            this.payload     = payload;
        }

        /** Fluent builder for ConnectionEvent. */
        public static final class Builder
        {
            private String ip;
            private int    port;
            private String countryCode;
            private String payload;

            public Builder ip(final String ip)                  { this.ip = ip;                  return this; }
            public Builder port(final int port)                 { this.port = port;               return this; }
            public Builder countryCode(final String code)       { this.countryCode = code;        return this; }
            public Builder payload(final String payload)        { this.payload = payload;          return this; }
            public ConnectionEvent build()                      { return new ConnectionEvent(ip, port, countryCode, payload); }
        }
    }

    /**
     * Result of classifying a single connection event.
     * score 0–100: higher means greater threat likelihood.
     */
    public static final class Classification
    {
        public static final int THREAT_THRESHOLD = 40;

        public final ConnectionEvent event;
        public final int             score;
        public final List<String>    findings;
        public final boolean         threat;

        Classification(final ConnectionEvent event, final int score, final List<String> findings)
        {
            this.event    = event;
            this.score    = score;
            this.findings = findings;
            this.threat   = score >= THREAT_THRESHOLD;
        }

        public String summary()
        {
            StringBuilder sb = new StringBuilder();
            sb.append("HEURISTICCLASSIFIER [IP=").append(event.ip)
              .append(" port=").append(event.port)
              .append(" country=").append(event.countryCode)
              .append("] score=").append(score).append("/100 — ")
              .append(threat ? "THREAT" : "CLEAR");
            return sb.toString();
        }

        /** Returns the individual finding lines (PASS / INFO / FAIL). */
        public java.util.List<String> findings() { return findings; }
    }
}
