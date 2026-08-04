package network;

import network.jpcap.NetworkCaptureEngine;
import network.jndi.JndiNetworkSearchEngine;

import java.util.*;
import java.util.concurrent.*;

/**
 * NetworkStabilityService — Unified network monitoring combining Jpcap capture
 * and JNDI directory lookups for comprehensive network health and stability.
 *
 * Provides:
 *   - Packet-level stability (via Jpcap): jitter, loss, throughput
 *   - DNS-level stability (via JNDI): resolver consistency, response times
 *   - Service discovery: SRV records, LDAP registries
 *   - Combined health score for system-level decision making
 *
 * Integrated with NitroWebExpress telnet interface:
 *   - "netstability"  — show combined stability report
 *   - "netstability dns <domain>" — DNS stability check
 *   - "netstability capture <iface>" — start packet capture
 *   - "netstability services <name>" — discover services
 *   - "netstability interfaces" — list network interfaces
 *
 * @author Max Rupplin — MEARVK LLC
 * @since Galactic Cherry Marvell Edition 98
 */
public class NetworkStabilityService implements Runnable {

    private final NetworkCaptureEngine captureEngine;
    private final JndiNetworkSearchEngine jndiEngine;
    private final ScheduledExecutorService scheduler;

    private volatile boolean running;
    private volatile int combinedScore = 100;
    private volatile long lastAssessment;

    // Monitored domains for periodic DNS stability checks
    private final List<String> monitoredDomains = new CopyOnWriteArrayList<>();

    // History of stability reports
    private final ConcurrentLinkedDeque<StabilitySnapshot> history = new ConcurrentLinkedDeque<>();
    private static final int MAX_HISTORY = 1440; // 24 hours at 1-minute intervals

    public NetworkStabilityService() {
        this.captureEngine = new NetworkCaptureEngine();
        this.jndiEngine = new JndiNetworkSearchEngine();
        this.scheduler = Executors.newScheduledThreadPool(2,
                r -> { Thread t = new Thread(r, "NetStability"); t.setDaemon(true); return t; });
    }

    // ═══ Lifecycle ═══════════════════════════════════════════════════════════

    @Override
    public void run() {
        running = true;
        System.out.println("[NetworkStabilityService] Started. Monitoring network health.");

        // Schedule periodic stability assessment every 60 seconds
        scheduler.scheduleAtFixedRate(this::periodicAssessment, 10, 60, TimeUnit.SECONDS);
    }

    public void shutdown() {
        running = false;
        captureEngine.stop();
        jndiEngine.shutdown();
        scheduler.shutdown();
        System.out.println("[NetworkStabilityService] Shutdown complete.");
    }

    // ═══ Public Commands (for telnet integration) ════════════════════════════

    /**
     * Process a command from the NWE telnet interface.
     * Returns formatted response string.
     */
    public String processCommand(String input) {
        if (input == null || input.isBlank()) return getOverview();

        String[] parts = input.trim().split("\\s+", 3);
        String subcommand = parts.length > 0 ? parts[0].toLowerCase() : "";

        return switch (subcommand) {
            case "dns" -> {
                String domain = parts.length > 1 ? parts[1] : "google.com";
                yield dnsStabilityCommand(domain);
            }
            case "capture" -> {
                String iface = parts.length > 1 ? parts[1] : "eth0";
                String filter = parts.length > 2 ? parts[2] : null;
                yield captureCommand(iface, filter);
            }
            case "stop" -> stopCaptureCommand();
            case "services" -> {
                String name = parts.length > 1 ? parts[1] : "_http._tcp.local";
                yield discoverServicesCommand(name);
            }
            case "interfaces" -> listInterfacesCommand();
            case "lookup" -> {
                String domain = parts.length > 1 ? parts[1] : "google.com";
                yield fullLookupCommand(domain);
            }
            case "monitor" -> {
                String domain = parts.length > 1 ? parts[1] : null;
                yield monitorCommand(domain);
            }
            case "report" -> captureReportCommand();
            case "history" -> historyCommand();
            case "help" -> helpCommand();
            default -> "Unknown subcommand: " + subcommand + "\n" + helpCommand();
        };
    }

    // ═══ Command Implementations ════════════════════════════════════════════

    private String getOverview() {
        StringBuilder sb = new StringBuilder();
        sb.append("╔══════════════════════════════════════════════════╗\n");
        sb.append("║  Network Stability Service                      ║\n");
        sb.append("║  Jpcap + JNDI — Galactic Cherry Marvell 98     ║\n");
        sb.append("╠══════════════════════════════════════════════════╣\n");
        sb.append(String.format("║  Combined Score:  %-30s║\n", combinedScore + "/100"));
        sb.append(String.format("║  Capture Active:  %-30s║\n", captureEngine.isRunning() ? "YES" : "NO"));
        sb.append(String.format("║  Monitored DNS:   %-30s║\n", monitoredDomains.size() + " domains"));
        sb.append(String.format("║  History:         %-30s║\n", history.size() + " snapshots"));
        sb.append(String.format("║  Last Check:      %-30s║\n",
                lastAssessment > 0 ? ((System.currentTimeMillis() - lastAssessment) / 1000) + "s ago" : "never"));
        sb.append("╠══════════════════════════════════════════════════╣\n");
        sb.append("║  Type 'help' for commands                       ║\n");
        sb.append("╚══════════════════════════════════════════════════╝\n");
        return sb.toString();
    }

    private String dnsStabilityCommand(String domain) {
        JndiNetworkSearchEngine.DnsStabilityReport report = jndiEngine.assessDnsStability(domain);
        return report.toString();
    }

    private String captureCommand(String iface, String filter) {
        if (captureEngine.isRunning()) {
            return "Capture already running. Use 'stop' first.";
        }
        captureEngine.start(iface, filter);
        return "Capture started on " + iface + (filter != null ? " filter=[" + filter + "]" : "");
    }

    private String stopCaptureCommand() {
        if (!captureEngine.isRunning()) {
            return "No capture running.";
        }
        NetworkCaptureEngine.StabilityReport report = captureEngine.getStabilityReport();
        captureEngine.stop();
        return "Capture stopped.\n\n" + report.toString();
    }

    private String discoverServicesCommand(String name) {
        List<JndiNetworkSearchEngine.ServiceRecord> services = jndiEngine.discoverServices(name);
        if (services.isEmpty()) {
            return "No services found for: " + name;
        }
        StringBuilder sb = new StringBuilder("Services for " + name + ":\n");
        for (JndiNetworkSearchEngine.ServiceRecord sr : services) {
            sb.append("  ").append(sr.toString()).append("\n");
        }
        return sb.toString();
    }

    private String listInterfacesCommand() {
        List<NetworkCaptureEngine.InterfaceInfo> ifaces = captureEngine.listInterfaces();
        if (ifaces.isEmpty()) return "No active network interfaces found.";

        StringBuilder sb = new StringBuilder("Network Interfaces:\n");
        for (NetworkCaptureEngine.InterfaceInfo info : ifaces) {
            sb.append("  ").append(info.toString()).append("\n");
        }
        return sb.toString();
    }

    private String fullLookupCommand(String domain) {
        JndiNetworkSearchEngine.DnsLookupResult result = jndiEngine.fullLookup(domain);
        return result.toString();
    }

    private String monitorCommand(String domain) {
        if (domain == null) {
            if (monitoredDomains.isEmpty()) return "No domains being monitored.";
            StringBuilder sb = new StringBuilder("Monitored domains:\n");
            for (String d : monitoredDomains) {
                sb.append("  • ").append(d).append("\n");
            }
            return sb.toString();
        }
        if (monitoredDomains.contains(domain)) {
            monitoredDomains.remove(domain);
            return "Removed " + domain + " from monitoring.";
        } else {
            monitoredDomains.add(domain);
            return "Added " + domain + " to monitoring.";
        }
    }

    private String captureReportCommand() {
        if (!captureEngine.isRunning()) return "No capture running. Use 'capture <iface>' first.";
        return captureEngine.getStabilityReport().toString();
    }

    private String historyCommand() {
        if (history.isEmpty()) return "No history yet. Service collects snapshots every 60 seconds.";
        StringBuilder sb = new StringBuilder("Recent stability history (last 10):\n");
        int count = 0;
        Iterator<StabilitySnapshot> it = history.descendingIterator();
        while (it.hasNext() && count < 10) {
            StabilitySnapshot snap = it.next();
            sb.append(String.format("  [%s] score=%d dns=%d capture=%d\n",
                    new java.text.SimpleDateFormat("HH:mm:ss").format(new Date(snap.timestamp)),
                    snap.combinedScore, snap.dnsScore, snap.captureScore));
            count++;
        }
        return sb.toString();
    }

    private String helpCommand() {
        return """
                Network Stability Commands:
                  (empty)                — Overview
                  dns <domain>           — DNS stability assessment
                  capture <iface> [filter] — Start packet capture
                  stop                   — Stop capture + show report
                  report                 — Show capture report (while running)
                  services <name>        — DNS SRV service discovery
                  interfaces             — List network interfaces
                  lookup <domain>        — Full DNS lookup (A, AAAA, MX, NS, TXT, SRV)
                  monitor [domain]       — Add/remove/list monitored domains
                  history                — Recent stability snapshots
                  help                   — This help
                """;
    }

    // ═══ Periodic Assessment ═════════════════════════════════════════════════

    private void periodicAssessment() {
        try {
            int dnsScore = 100;
            int captureScore = 100;

            // DNS stability for monitored domains
            if (!monitoredDomains.isEmpty()) {
                int totalDns = 0;
                for (String domain : monitoredDomains) {
                    try {
                        JndiNetworkSearchEngine.DnsStabilityReport report =
                                jndiEngine.assessDnsStability(domain);
                        totalDns += report.stabilityScore;
                    } catch (Exception e) {
                        totalDns += 50; // Partial score on failure
                    }
                }
                dnsScore = totalDns / monitoredDomains.size();
            }

            // Capture stability (if running)
            if (captureEngine.isRunning()) {
                NetworkCaptureEngine.StabilityReport report = captureEngine.getStabilityReport();
                captureScore = report.stabilityScore;
            }

            // Combined score (weighted average)
            combinedScore = (dnsScore + captureScore) / 2;
            lastAssessment = System.currentTimeMillis();

            // Store snapshot
            StabilitySnapshot snap = new StabilitySnapshot();
            snap.timestamp = lastAssessment;
            snap.combinedScore = combinedScore;
            snap.dnsScore = dnsScore;
            snap.captureScore = captureScore;
            history.addLast(snap);
            while (history.size() > MAX_HISTORY) history.pollFirst();

        } catch (Exception e) {
            System.err.println("[NetworkStabilityService] Assessment error: " + e.getMessage());
        }
    }

    // ═══ Getters ═════════════════════════════════════════════════════════════

    public int getCombinedScore() { return combinedScore; }
    public NetworkCaptureEngine getCaptureEngine() { return captureEngine; }
    public JndiNetworkSearchEngine getJndiEngine() { return jndiEngine; }
    public boolean isRunning() { return running; }

    // ═══ Data Classes ════════════════════════════════════════════════════════

    private static class StabilitySnapshot {
        long timestamp;
        int combinedScore;
        int dnsScore;
        int captureScore;
    }
}
