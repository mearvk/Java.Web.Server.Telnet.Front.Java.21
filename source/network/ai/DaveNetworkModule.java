package network.ai;

import network.jpcap.NetworkCaptureEngine;
import network.jndi.JndiNetworkSearchEngine;

import java.sql.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * DaveNetworkModule — AI-driven network intelligence for Dave.
 *
 * This module gives Dave the ability to:
 *   1. Discover Ethical partner systems via JNDI (DNS SRV, LDAP)
 *   2. Verify connections via Jpcap (packet capture, stability analysis)
 *   3. Communicate with JNDI-ready servers
 *   4. Monitor partner health continuously
 *   5. Record all findings in dave_kb MySQL tables
 *
 * Dave uses JNDI to find who is out there.
 * Dave uses Jpcap to verify that the path is clean.
 * Dave communicates only to verified Ethical partners.
 *
 * The 1,2,3 of Data Consideration applies:
 *   1 (HOLD)       — New partner discovered. Observe before trusting.
 *   2 (CONSISTENT) — DNS is stable, packets are clean. Verified over time.
 *   3 (ROGER)      — Communication proceeds. Mutual benefit confirmed.
 *
 * @author Max Rupplin — MEARVK LLC
 * @since Galactic Cherry Marvell Edition 98
 */
public class DaveNetworkModule extends Thread {

    // ═══ Configuration ═══════════════════════════════════════════════════════
    private static final long   ASSESSMENT_INTERVAL_MS = 60_000;  // 1 minute
    private static final long   DISCOVERY_INTERVAL_MS  = 300_000; // 5 minutes
    private static final long   PARTNER_CHECK_MS       = 120_000; // 2 minutes
    private static final int    DNS_STABILITY_THRESHOLD = 70;     // minimum score to advance trust
    private static final int    PACKET_STABILITY_THRESHOLD = 80;  // minimum for ROGER state
    private static final double CONFIDENCE_THRESHOLD    = 0.85;   // Dave's vote threshold
    private static final String DB_URL = "jdbc:mysql://localhost/dave_kb?useSSL=false&allowPublicKeyRetrieval=true";
    private static final String DB_USER = "dave_ai";

    // ═══ Engines ═════════════════════════════════════════════════════════════
    private final NetworkCaptureEngine captureEngine;
    private final JndiNetworkSearchEngine jndiEngine;
    private final ScheduledExecutorService scheduler;

    // ═══ State ═══════════════════════════════════════════════════════════════
    private volatile boolean running;
    private Connection dbConnection;

    // Monitored domains for periodic checks
    private final List<String> monitoredDomains = new CopyOnWriteArrayList<>();

    // Known Ethical partner service patterns
    private final List<String> ethicalServicePatterns = new CopyOnWriteArrayList<>(List.of(
            "_nwe._tcp",     // NitroWebExpress instances
            "_epmp._tcp",    // Extended Port Multiplexer Protocol
            "_dave._tcp",    // Dave AI instances (other systems)
            "_ethics._tcp"   // General ethical service marker
    ));

    // ═══ Constructor ═════════════════════════════════════════════════════════

    public DaveNetworkModule() {
        super("Dave-Network-Module");
        setDaemon(true);
        this.captureEngine = new NetworkCaptureEngine();
        this.jndiEngine = new JndiNetworkSearchEngine(5000);
        this.scheduler = Executors.newScheduledThreadPool(3,
                r -> { Thread t = new Thread(r, "Dave-Net-" + System.nanoTime()); t.setDaemon(true); return t; });
    }

    // ═══ Lifecycle ═══════════════════════════════════════════════════════════

    @Override
    public void run() {
        running = true;
        System.out.println("[Dave/Network] Network intelligence module starting.");
        System.out.println("[Dave/Network] JNDI available: YES (javax.naming — built into JDK)");
        System.out.println("[Dave/Network] Jpcap available: " + isJpcapAvailable());
        System.out.println("[Dave/Network] We would be very happy to communicate and care.");

        try {
            connectDatabase();
        } catch (Exception e) {
            System.err.println("[Dave/Network] Database connection failed: " + e.getMessage());
            System.err.println("[Dave/Network] Continuing without persistence (observations will be logged only).");
        }

        // Schedule periodic tasks
        scheduler.scheduleAtFixedRate(this::discoverPartners, 10_000, DISCOVERY_INTERVAL_MS, TimeUnit.MILLISECONDS);
        scheduler.scheduleAtFixedRate(this::assessMonitoredDomains, 30_000, ASSESSMENT_INTERVAL_MS, TimeUnit.MILLISECONDS);
        scheduler.scheduleAtFixedRate(this::checkPartnerHealth, 60_000, PARTNER_CHECK_MS, TimeUnit.MILLISECONDS);

        System.out.println("[Dave/Network] Module active. Discovering Ethical partners...");

        // Main loop — Dave observes
        while (running && !isInterrupted()) {
            try {
                Thread.sleep(ASSESSMENT_INTERVAL_MS);
                observe();
            } catch (InterruptedException e) {
                break;
            } catch (Exception e) {
                System.err.println("[Dave/Network] Observation error: " + e.getMessage());
            }
        }

        shutdown();
    }

    public void shutdown() {
        running = false;
        captureEngine.stop();
        jndiEngine.shutdown();
        scheduler.shutdown();
        closeDatabase();
        System.out.println("[Dave/Network] Module shutdown complete.");
    }

    // ═══ Partner Discovery (JNDI) ═══════════════════════════════════════════

    /**
     * Discover Ethical partner systems via JNDI DNS SRV lookups.
     * Dave searches for known service patterns and evaluates what he finds.
     */
    private void discoverPartners() {
        for (String pattern : ethicalServicePatterns) {
            for (String domain : monitoredDomains) {
                String srvName = pattern + "." + domain;
                try {
                    List<JndiNetworkSearchEngine.ServiceRecord> services =
                            jndiEngine.discoverServices(srvName);

                    for (JndiNetworkSearchEngine.ServiceRecord sr : services) {
                        processDiscoveredService(sr, domain, "dns_srv");
                    }
                } catch (Exception e) {
                    // Discovery failure is normal — not all domains have SRV records
                }
            }
        }
    }

    /**
     * Process a newly discovered service. Apply the 1,2,3 consideration model.
     */
    private void processDiscoveredService(JndiNetworkSearchEngine.ServiceRecord sr,
                                           String domain, String method) {
        // Vote: should Dave investigate this service?
        double safety = voteOnSafety(sr);
        double correctness = voteOnCorrectness(sr);
        double ethics = voteOnEthics(sr);

        if (safety < CONFIDENCE_THRESHOLD || correctness < CONFIDENCE_THRESHOLD || ethics < CONFIDENCE_THRESHOLD) {
            logObservation("partner_discovery",
                    "Discovered service " + sr.target + ":" + sr.port + " but votes did not pass threshold. "
                    + "Safety=" + safety + " Correctness=" + correctness + " Ethics=" + ethics,
                    "info", safety);
            return;
        }

        // Step 1: HOLD — register the partner in initial state
        registerPartner(domain, sr.serviceName, sr.target, sr.port, "TCP", method, "HOLD");

        logObservation("partner_discovery",
                "Discovered Ethical partner candidate: " + sr.target + ":" + sr.port
                + " via " + method + " (service=" + sr.serviceName + "). Trust state: HOLD. Will verify.",
                "info", (safety + correctness + ethics) / 3.0);

        System.out.println("[Dave/Network] New partner candidate: " + sr.target + ":" + sr.port
                + " — trust HOLD. Verifying...");
    }

    // ═══ DNS Stability Assessment (JNDI) ═════════════════════════════════════

    /**
     * Assess DNS stability of monitored domains.
     * Records results and advances partner trust if stable.
     */
    private void assessMonitoredDomains() {
        for (String domain : monitoredDomains) {
            try {
                JndiNetworkSearchEngine.DnsStabilityReport report =
                        jndiEngine.assessDnsStability(domain);

                recordDnsStability(domain, report);

                // If score is good and partner exists in HOLD → advance to CONSISTENT
                if (report.stabilityScore >= DNS_STABILITY_THRESHOLD && report.consistentAnswers) {
                    advancePartnerTrust(domain, "HOLD", "CONSISTENT",
                            "DNS stability confirmed: " + report.stabilityScore + "/100, consistent across resolvers.");
                }

            } catch (Exception e) {
                logObservation("dns_health",
                        "DNS assessment failed for " + domain + ": " + e.getMessage(),
                        "low", 0.5);
            }
        }
    }

    // ═══ Packet Capture Verification (Jpcap) ═════════════════════════════════

    /**
     * Verify a partner connection via Jpcap packet capture.
     * Used to advance trust from CONSISTENT to ROGER.
     */
    public void verifyPartnerViaCapture(String partnerHost, int partnerPort, String interfaceName) {
        String filter = "host " + partnerHost + " and port " + partnerPort;

        System.out.println("[Dave/Network] Initiating Jpcap verification for " + partnerHost + ":" + partnerPort);

        captureEngine.start(interfaceName, filter);

        // Capture for 30 seconds
        scheduler.schedule(() -> {
            NetworkCaptureEngine.StabilityReport report = captureEngine.getStabilityReport();
            captureEngine.stop();

            recordCaptureSession(interfaceName, filter, report);

            if (report.stabilityScore >= PACKET_STABILITY_THRESHOLD && report.droppedPackets == 0) {
                // Packets are clean — advance to ROGER
                advancePartnerTrust(partnerHost, "CONSISTENT", "ROGER",
                        "Packet verification passed: score=" + report.stabilityScore
                        + "/100, jitter=" + String.format("%.1f", report.jitterMicroseconds) + "µs, 0 drops.");

                System.out.println("[Dave/Network] ✓ Partner " + partnerHost + " verified via Jpcap. Trust: ROGER.");
                System.out.println("[Dave/Network] We are happy to communicate and care.");
            } else {
                logObservation("packet_degradation",
                        "Packet verification for " + partnerHost + " did not meet threshold. "
                        + "Score=" + report.stabilityScore + " drops=" + report.droppedPackets,
                        "medium", 0.6);
            }
        }, 30, TimeUnit.SECONDS);
    }

    // ═══ Partner Health Monitoring ═══════════════════════════════════════════

    /**
     * Periodic health check of all ROGER partners.
     * If a partner degrades, Dave records an anomaly and may downgrade trust.
     */
    private void checkPartnerHealth() {
        // Query all ROGER partners from DB and verify each
        try {
            if (dbConnection == null || dbConnection.isClosed()) return;

            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "SELECT id, domain, host, port FROM network_partners WHERE trust_state = 'ROGER' AND status = 'active'");
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    String domain = rs.getString("domain");
                    String host = rs.getString("host");
                    int port = rs.getInt("port");

                    // Quick DNS check
                    List<String> resolved = jndiEngine.resolveA(domain);
                    if (resolved.isEmpty()) {
                        recordAnomaly("service_disappearance", "medium", domain, null,
                                "Partner " + domain + " no longer resolves. May be temporarily offline.");
                    }
                }
            }
        } catch (SQLException e) {
            // DB issue — log but continue
        }
    }

    // ═══ Communication with JNDI-Ready Servers ═══════════════════════════════

    /**
     * Communicate with a JNDI-ready server. Dave only communicates with ROGER partners.
     *
     * @param partnerDomain The partner's domain
     * @param message       The communication payload
     * @return Response from partner, or null if communication failed
     */
    public String communicateToPartner(String partnerDomain, String message) {
        // Verify trust state
        String trustState = getPartnerTrustState(partnerDomain);
        if (!"ROGER".equals(trustState)) {
            System.out.println("[Dave/Network] Cannot communicate to " + partnerDomain
                    + " — trust state is " + trustState + " (need ROGER).");
            return null;
        }

        // Resolve via JNDI
        List<String> addresses = jndiEngine.resolveA(partnerDomain);
        if (addresses.isEmpty()) {
            logObservation("communication_events",
                    "Cannot resolve " + partnerDomain + " for communication.", "medium", 0.7);
            return null;
        }

        // Vote on this communication
        double ethicsVote = 0.95; // Communicating to ROGER partners is ethical
        double safetyVote = 0.90; // Already verified
        double correctnessVote = 0.90;

        logObservation("communication_events",
                "Initiating communication to Ethical partner " + partnerDomain
                + ". Votes: safety=" + safetyVote + " ethics=" + ethicsVote + " correctness=" + correctnessVote,
                "info", (ethicsVote + safetyVote + correctnessVote) / 3.0);

        System.out.println("[Dave/Network] Communicating to Ethical partner: " + partnerDomain);
        System.out.println("[Dave/Network] We are happy to communicate and care.");

        // Actual communication would happen here via appropriate protocol
        // (HTTPS, EPMP, telnet, etc. depending on the service type)
        // For now, Dave records the intent and readiness.
        recordCommunicationEvent(partnerDomain, "outbound", message, "success",
                safetyVote, correctnessVote, ethicsVote, 0.85, 0.90);

        return "ACK — communication logged and ready";
    }

    // ═══ Observation Loop ════════════════════════════════════════════════════

    /**
     * Dave's periodic observation of network state.
     */
    private void observe() {
        // Check if capture is running — get metrics
        if (captureEngine.isRunning()) {
            double pps = captureEngine.getPacketsPerSecond();
            double bps = captureEngine.getBytesPerSecond();

            // Anomaly detection: sudden traffic spikes
            if (pps > 10000) {
                logObservation("anomalies",
                        "High packet rate detected: " + String.format("%.0f", pps) + " pps. "
                        + "May indicate scan, DDoS, or legitimate burst. Monitoring.",
                        "medium", 0.7);
            }
        }

        // Check interface health
        List<NetworkCaptureEngine.InterfaceInfo> ifaces = captureEngine.listInterfaces();
        if (ifaces.isEmpty()) {
            logObservation("network_stability",
                    "No active network interfaces detected. System may be offline.",
                    "critical", 0.95);
        }
    }

    // ═══ Voting System ═══════════════════════════════════════════════════════

    private double voteOnSafety(JndiNetworkSearchEngine.ServiceRecord sr) {
        // Safe if: standard port, known protocol, not obviously malicious
        if (sr.port > 0 && sr.port < 65536) return 0.90;
        return 0.50;
    }

    private double voteOnCorrectness(JndiNetworkSearchEngine.ServiceRecord sr) {
        // Correct if: valid target, reasonable priority/weight
        if (sr.target != null && !sr.target.isEmpty() && sr.priority >= 0) return 0.90;
        return 0.50;
    }

    private double voteOnEthics(JndiNetworkSearchEngine.ServiceRecord sr) {
        // Ethical if: service name matches our Ethical patterns
        for (String pattern : ethicalServicePatterns) {
            if (sr.serviceName != null && sr.serviceName.contains(pattern)) return 0.95;
        }
        return 0.70; // Unknown service — cautious but not hostile
    }

    // ═══ Database Operations ═════════════════════════════════════════════════

    private void connectDatabase() throws Exception {
        dbConnection = DriverManager.getConnection(DB_URL, DB_USER, "");
        System.out.println("[Dave/Network] Connected to dave_kb database.");
    }

    private void closeDatabase() {
        try { if (dbConnection != null) dbConnection.close(); } catch (Exception ignored) {}
    }

    private void registerPartner(String domain, String serviceName, String host,
                                  int port, String protocol, String method, String trustState) {
        try {
            if (dbConnection == null || dbConnection.isClosed()) return;
            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "INSERT INTO network_partners (domain, service_name, host, port, protocol, discovery_method, trust_state) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?) "
                    + "ON DUPLICATE KEY UPDATE last_verified = NOW(), status = 'active'")) {
                ps.setString(1, domain);
                ps.setString(2, serviceName);
                ps.setString(3, host);
                ps.setInt(4, port);
                ps.setString(5, protocol);
                ps.setString(6, method);
                ps.setString(7, trustState);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            System.err.println("[Dave/Network] Failed to register partner: " + e.getMessage());
        }
    }

    private void advancePartnerTrust(String domainOrHost, String fromState, String toState, String reason) {
        try {
            if (dbConnection == null || dbConnection.isClosed()) return;
            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "UPDATE network_partners SET trust_state = ?, last_verified = NOW(), notes = ? "
                    + "WHERE (domain = ? OR host = ?) AND trust_state = ?")) {
                ps.setString(1, toState);
                ps.setString(2, reason);
                ps.setString(3, domainOrHost);
                ps.setString(4, domainOrHost);
                ps.setString(5, fromState);
                int updated = ps.executeUpdate();
                if (updated > 0) {
                    System.out.println("[Dave/Network] Trust advanced: " + domainOrHost
                            + " " + fromState + " → " + toState);
                }
            }
        } catch (SQLException e) {
            System.err.println("[Dave/Network] Trust advance failed: " + e.getMessage());
        }
    }

    private String getPartnerTrustState(String domain) {
        try {
            if (dbConnection == null || dbConnection.isClosed()) return "UNKNOWN";
            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "SELECT trust_state FROM network_partners WHERE domain = ? AND status = 'active' LIMIT 1")) {
                ps.setString(1, domain);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return rs.getString("trust_state");
                }
            }
        } catch (SQLException e) {}
        return "UNKNOWN";
    }

    private void recordDnsStability(String domain, JndiNetworkSearchEngine.DnsStabilityReport report) {
        try {
            if (dbConnection == null || dbConnection.isClosed()) return;
            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "INSERT INTO dns_stability_history (domain, stability_score, consistent, resolvers_queried, failures, avg_response_ms) "
                    + "VALUES (?, ?, ?, ?, ?, ?)")) {
                ps.setString(1, domain);
                ps.setInt(2, report.stabilityScore);
                ps.setBoolean(3, report.consistentAnswers);
                ps.setInt(4, report.resolverResults.size());
                int totalFailures = report.resolverResults.stream().mapToInt(r -> r.failures).sum();
                ps.setInt(5, totalFailures);
                double avgResp = report.resolverResults.stream().mapToDouble(r -> r.avgResponseMs).average().orElse(0);
                ps.setDouble(6, avgResp);
                ps.executeUpdate();
            }
        } catch (SQLException e) {}
    }

    private void recordCaptureSession(String iface, String filter, NetworkCaptureEngine.StabilityReport report) {
        try {
            if (dbConnection == null || dbConnection.isClosed()) return;
            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "INSERT INTO packet_capture_sessions "
                    + "(interface_name, bpf_filter, total_packets, total_bytes, dropped_packets, "
                    + "tcp_packets, udp_packets, icmp_packets, arp_packets, jitter_us, stability_score, duration_sec) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
                ps.setString(1, iface);
                ps.setString(2, filter);
                ps.setLong(3, report.totalPackets);
                ps.setLong(4, report.totalBytes);
                ps.setLong(5, report.droppedPackets);
                ps.setLong(6, report.tcpPackets);
                ps.setLong(7, report.udpPackets);
                ps.setLong(8, report.icmpPackets);
                ps.setLong(9, report.arpPackets);
                ps.setDouble(10, report.jitterMicroseconds);
                ps.setInt(11, report.stabilityScore);
                ps.setLong(12, report.uptimeSeconds);
                ps.executeUpdate();
            }
        } catch (SQLException e) {}
    }

    private void recordCommunicationEvent(String partnerDomain, String direction, String purpose,
                                           String outcome, double safety, double correctness,
                                           double ethics, double performance, double elegance) {
        try {
            if (dbConnection == null || dbConnection.isClosed()) return;

            // Get partner ID
            long partnerId = -1;
            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "SELECT id FROM network_partners WHERE domain = ? LIMIT 1")) {
                ps.setString(1, partnerDomain);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) partnerId = rs.getLong("id");
                }
            }
            if (partnerId < 0) return;

            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "INSERT INTO communication_events "
                    + "(partner_id, direction, protocol, purpose, outcome, "
                    + "vote_safety, vote_correctness, vote_ethics, vote_performance, vote_elegance) "
                    + "VALUES (?, ?, 'HTTPS', ?, ?, ?, ?, ?, ?, ?)")) {
                ps.setLong(1, partnerId);
                ps.setString(2, direction);
                ps.setString(3, purpose);
                ps.setString(4, outcome);
                ps.setDouble(5, safety);
                ps.setDouble(6, correctness);
                ps.setDouble(7, ethics);
                ps.setDouble(8, performance);
                ps.setDouble(9, elegance);
                ps.executeUpdate();
            }
        } catch (SQLException e) {}
    }

    private void recordAnomaly(String category, String severity, String domain,
                                String sourceIp, String description) {
        try {
            if (dbConnection == null || dbConnection.isClosed()) return;
            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "INSERT INTO network_anomalies (category, severity, domain, source_ip, description) "
                    + "VALUES (?, ?, ?, ?, ?)")) {
                ps.setString(1, category);
                ps.setString(2, severity);
                ps.setString(3, domain);
                ps.setString(4, sourceIp);
                ps.setString(5, description);
                ps.executeUpdate();
            }
        } catch (SQLException e) {}
    }

    private void logObservation(String category, String observation, String severity, double confidence) {
        System.out.println("[Dave/Network/" + category + "] " + observation);
        try {
            if (dbConnection == null || dbConnection.isClosed()) return;
            try (PreparedStatement ps = dbConnection.prepareStatement(
                    "INSERT INTO observations (category, observation, severity, confidence, reasoning) "
                    + "VALUES ('component', ?, ?, ?, ?)")) {
                ps.setString(1, "[Network/" + category + "] " + observation);
                ps.setString(2, severity);
                ps.setDouble(3, confidence);
                ps.setString(4, "Network intelligence module observation via JNDI/Jpcap");
                ps.executeUpdate();
            }
        } catch (SQLException e) {}
    }

    // ═══ Public API for Dave's main intelligence ════════════════════════════

    /**
     * Add a domain for Dave to monitor via JNDI.
     */
    public void addMonitoredDomain(String domain) {
        if (!monitoredDomains.contains(domain)) {
            monitoredDomains.add(domain);
            System.out.println("[Dave/Network] Now monitoring: " + domain);
        }
    }

    /**
     * Remove a domain from monitoring.
     */
    public void removeMonitoredDomain(String domain) {
        monitoredDomains.remove(domain);
    }

    /**
     * Get all monitored domains.
     */
    public List<String> getMonitoredDomains() {
        return Collections.unmodifiableList(monitoredDomains);
    }

    /**
     * Add an Ethical service pattern for discovery.
     */
    public void addServicePattern(String pattern) {
        if (!ethicalServicePatterns.contains(pattern)) {
            ethicalServicePatterns.add(pattern);
        }
    }

    /**
     * Quick DNS stability check (for Dave's main loop to call).
     */
    public int quickDnsCheck(String domain) {
        JndiNetworkSearchEngine.DnsStabilityReport report = jndiEngine.assessDnsStability(domain);
        return report.stabilityScore;
    }

    /**
     * Full DNS profile (for Dave's curiosity).
     */
    public JndiNetworkSearchEngine.DnsLookupResult fullLookup(String domain) {
        return jndiEngine.fullLookup(domain);
    }

    /**
     * Check if Jpcap native is available.
     */
    private String isJpcapAvailable() {
        try {
            Class.forName("jpcap.JpcapCaptor");
            return "YES (native + JAR)";
        } catch (ClassNotFoundException e) {
            try {
                Class.forName("net.sourceforge.jpcap.capture.PacketCapture");
                return "YES (pure-Java JAR)";
            } catch (ClassNotFoundException e2) {
                return "NO (JAR not on classpath — run jars/jpcap/fetch-jpcap.sh)";
            }
        }
    }

    /**
     * Get the underlying engines for direct access by Dave's main process.
     */
    public NetworkCaptureEngine getCaptureEngine() { return captureEngine; }
    public JndiNetworkSearchEngine getJndiEngine() { return jndiEngine; }

    // ═══ Main (standalone test) ══════════════════════════════════════════════

    public static void main(String[] args) throws Exception {
        DaveNetworkModule module = new DaveNetworkModule();

        // Add some domains to monitor
        module.addMonitoredDomain("mearvk.us");
        module.addMonitoredDomain("github.com");
        module.addMonitoredDomain("google.com");

        module.start();

        System.out.println("[Dave/Network] Module running. Press Ctrl+C to stop.");
        Runtime.getRuntime().addShutdownHook(new Thread(module::shutdown));

        // Keep running
        module.join();
    }
}
