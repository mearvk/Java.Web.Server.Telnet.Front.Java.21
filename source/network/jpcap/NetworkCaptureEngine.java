package network.jpcap;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

/**
 * NetworkCaptureEngine — Jpcap-based packet capture and network stability analysis.
 *
 * Provides:
 *   - Real-time packet capture on any interface
 *   - Connection stability metrics (packet loss, jitter, reordering)
 *   - Interface enumeration and health
 *   - Protocol-level traffic statistics
 *   - BPF filter support for targeted capture
 *
 * Requires: jpcap JAR on classpath + libpcap native library installed.
 *
 * Usage:
 *   NetworkCaptureEngine engine = new NetworkCaptureEngine();
 *   engine.start("eth0", "tcp port 80");
 *   // ... collect metrics ...
 *   StabilityReport report = engine.getStabilityReport();
 *   engine.stop();
 *
 * @author Max Rupplin — MEARVK LLC
 * @since Galactic Cherry Marvell Edition 98
 */
public class NetworkCaptureEngine {

    // ═══ Constants ═══════════════════════════════════════════════════════════
    private static final int    CAPTURE_SNAPLEN     = 65535;
    private static final int    CAPTURE_TIMEOUT_MS  = 1000;
    private static final int    STATS_WINDOW_SEC    = 60;
    private static final int    MAX_PACKET_QUEUE    = 10000;
    private static final long   JITTER_SAMPLE_MAX   = 1000;

    // ═══ State ═══════════════════════════════════════════════════════════════
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final AtomicLong    totalPackets = new AtomicLong(0);
    private final AtomicLong    totalBytes = new AtomicLong(0);
    private final AtomicLong    droppedPackets = new AtomicLong(0);
    private final AtomicLong    tcpPackets = new AtomicLong(0);
    private final AtomicLong    udpPackets = new AtomicLong(0);
    private final AtomicLong    icmpPackets = new AtomicLong(0);
    private final AtomicLong    arpPackets = new AtomicLong(0);
    private final AtomicLong    otherPackets = new AtomicLong(0);

    private volatile Thread captureThread;
    private volatile String activeInterface;
    private volatile String activeFilter;
    private volatile long   captureStartTime;

    // Jitter tracking (inter-arrival times in microseconds)
    private final ConcurrentLinkedDeque<Long> interArrivalTimes = new ConcurrentLinkedDeque<>();
    private volatile long lastPacketTimestamp = 0;

    // Per-source connection tracking
    private final ConcurrentHashMap<String, ConnectionMetrics> connectionMap = new ConcurrentHashMap<>();

    // Packet listeners
    private final List<PacketListener> listeners = new CopyOnWriteArrayList<>();

    // ═══ Public API ═════════════════════════════════════════════════════════

    /**
     * Enumerate available network interfaces.
     */
    public List<InterfaceInfo> listInterfaces() {
        List<InterfaceInfo> result = new ArrayList<>();
        try {
            Enumeration<NetworkInterface> ifaces = NetworkInterface.getNetworkInterfaces();
            while (ifaces.hasMoreElements()) {
                NetworkInterface ni = ifaces.nextElement();
                if (ni.isUp()) {
                    InterfaceInfo info = new InterfaceInfo();
                    info.name = ni.getName();
                    info.displayName = ni.getDisplayName();
                    info.mtu = ni.getMTU();
                    info.isLoopback = ni.isLoopback();
                    info.isPointToPoint = ni.isPointToPoint();
                    info.supportsMulticast = ni.supportsMulticast();

                    List<String> addrs = new ArrayList<>();
                    Enumeration<InetAddress> iaddrs = ni.getInetAddresses();
                    while (iaddrs.hasMoreElements()) {
                        addrs.add(iaddrs.nextElement().getHostAddress());
                    }
                    info.addresses = addrs;

                    byte[] hw = ni.getHardwareAddress();
                    if (hw != null) {
                        StringBuilder sb = new StringBuilder();
                        for (int i = 0; i < hw.length; i++) {
                            if (i > 0) sb.append(':');
                            sb.append(String.format("%02x", hw[i]));
                        }
                        info.macAddress = sb.toString();
                    }
                    result.add(info);
                }
            }
        } catch (Exception e) {
            System.err.println("[NetworkCaptureEngine] Interface enumeration error: " + e.getMessage());
        }
        return result;
    }

    /**
     * Start packet capture on the given interface with optional BPF filter.
     *
     * @param interfaceName e.g. "eth0", "wlan0", "lo"
     * @param bpfFilter     BPF filter string, e.g. "tcp port 80", "host 10.0.0.1", or null for all
     */
    public void start(final String interfaceName, final String bpfFilter) {
        if (running.compareAndSet(false, true)) {
            activeInterface = interfaceName;
            activeFilter = bpfFilter;
            captureStartTime = System.currentTimeMillis();
            lastPacketTimestamp = 0;

            captureThread = new Thread(() -> captureLoop(interfaceName, bpfFilter),
                    "Jpcap-Capture-" + interfaceName);
            captureThread.setDaemon(true);
            captureThread.start();

            System.out.println("[NetworkCaptureEngine] Started capture on " + interfaceName
                    + (bpfFilter != null ? " filter=[" + bpfFilter + "]" : ""));
        }
    }

    /**
     * Stop capture.
     */
    public void stop() {
        if (running.compareAndSet(true, false)) {
            if (captureThread != null) {
                captureThread.interrupt();
                try { captureThread.join(3000); } catch (InterruptedException ignored) {}
            }
            System.out.println("[NetworkCaptureEngine] Stopped capture on " + activeInterface);
        }
    }

    /**
     * Get current stability report for all tracked connections.
     */
    public StabilityReport getStabilityReport() {
        StabilityReport report = new StabilityReport();
        report.interfaceName = activeInterface;
        report.filter = activeFilter;
        report.uptimeSeconds = (System.currentTimeMillis() - captureStartTime) / 1000;
        report.totalPackets = totalPackets.get();
        report.totalBytes = totalBytes.get();
        report.droppedPackets = droppedPackets.get();
        report.tcpPackets = tcpPackets.get();
        report.udpPackets = udpPackets.get();
        report.icmpPackets = icmpPackets.get();
        report.arpPackets = arpPackets.get();
        report.otherPackets = otherPackets.get();

        // Calculate jitter (standard deviation of inter-arrival times)
        report.jitterMicroseconds = calculateJitter();

        // Per-connection metrics
        report.connections = new ArrayList<>(connectionMap.values());

        // Overall stability score (0-100)
        report.stabilityScore = calculateStabilityScore(report);

        return report;
    }

    /**
     * Register a packet listener for real-time inspection.
     */
    public void addPacketListener(PacketListener listener) {
        listeners.add(listener);
    }

    /**
     * Remove a packet listener.
     */
    public void removePacketListener(PacketListener listener) {
        listeners.remove(listener);
    }

    /**
     * Check if capture is running.
     */
    public boolean isRunning() {
        return running.get();
    }

    /**
     * Get per-second packet rate.
     */
    public double getPacketsPerSecond() {
        long elapsed = (System.currentTimeMillis() - captureStartTime) / 1000;
        return elapsed > 0 ? (double) totalPackets.get() / elapsed : 0;
    }

    /**
     * Get per-second byte rate.
     */
    public double getBytesPerSecond() {
        long elapsed = (System.currentTimeMillis() - captureStartTime) / 1000;
        return elapsed > 0 ? (double) totalBytes.get() / elapsed : 0;
    }

    /**
     * Reset all statistics.
     */
    public void resetStats() {
        totalPackets.set(0);
        totalBytes.set(0);
        droppedPackets.set(0);
        tcpPackets.set(0);
        udpPackets.set(0);
        icmpPackets.set(0);
        arpPackets.set(0);
        otherPackets.set(0);
        interArrivalTimes.clear();
        connectionMap.clear();
        lastPacketTimestamp = 0;
        captureStartTime = System.currentTimeMillis();
    }

    // ═══ Capture Loop ════════════════════════════════════════════════════════

    /**
     * Main capture loop. Uses Jpcap via reflection to avoid hard compile-time
     * dependency (graceful degradation if JAR not present).
     */
    private void captureLoop(String interfaceName, String bpfFilter) {
        try {
            // Attempt to load Jpcap via reflection
            Class<?> jpcapCaptor = Class.forName("jpcap.JpcapCaptor");
            Class<?> packetClass = Class.forName("jpcap.packet.Packet");

            // JpcapCaptor.openDevice(NetworkInterface, snaplen, promiscuous, timeout)
            // We need to find the right interface via Jpcap's own enumeration
            Class<?> networkIfClass = Class.forName("jpcap.NetworkInterface");

            java.lang.reflect.Method getDeviceList = jpcapCaptor.getMethod("getDeviceList");
            Object[] devices = (Object[]) getDeviceList.invoke(null);

            Object targetDevice = null;
            for (Object dev : devices) {
                java.lang.reflect.Field nameField = networkIfClass.getField("name");
                String devName = (String) nameField.get(dev);
                if (devName.equals(interfaceName)) {
                    targetDevice = dev;
                    break;
                }
            }

            if (targetDevice == null) {
                System.err.println("[NetworkCaptureEngine] Interface not found in Jpcap: " + interfaceName);
                running.set(false);
                return;
            }

            // Open device
            java.lang.reflect.Method openDevice = jpcapCaptor.getMethod("openDevice",
                    networkIfClass, int.class, boolean.class, int.class);
            Object captor = openDevice.invoke(null, targetDevice,
                    CAPTURE_SNAPLEN, true, CAPTURE_TIMEOUT_MS);

            // Set BPF filter
            if (bpfFilter != null && !bpfFilter.isEmpty()) {
                java.lang.reflect.Method setFilter = jpcapCaptor.getMethod("setFilter",
                        String.class, boolean.class);
                setFilter.invoke(captor, bpfFilter, true);
            }

            // Get the getPacket method
            java.lang.reflect.Method getPacket = jpcapCaptor.getMethod("getPacket");

            // Capture loop
            while (running.get() && !Thread.currentThread().isInterrupted()) {
                Object packet = getPacket.invoke(captor);
                if (packet != null) {
                    processPacketReflective(packet, packetClass);
                }
            }

            // Close
            java.lang.reflect.Method close = jpcapCaptor.getMethod("close");
            close.invoke(captor);

        } catch (ClassNotFoundException e) {
            System.err.println("[NetworkCaptureEngine] Jpcap not on classpath. "
                    + "Run: jars/jpcap/fetch-jpcap.sh to obtain the library.");
            System.err.println("[NetworkCaptureEngine] Falling back to passive socket monitoring.");
            fallbackMonitor();
        } catch (Exception e) {
            if (running.get()) {
                System.err.println("[NetworkCaptureEngine] Capture error: " + e.getMessage());
            }
        } finally {
            running.set(false);
        }
    }

    /**
     * Process a captured packet via reflection (avoids compile-time Jpcap dependency).
     */
    private void processPacketReflective(Object packet, Class<?> packetClass) {
        try {
            long now = System.nanoTime() / 1000; // microseconds

            // Track inter-arrival
            if (lastPacketTimestamp > 0) {
                long delta = now - lastPacketTimestamp;
                interArrivalTimes.addLast(delta);
                while (interArrivalTimes.size() > JITTER_SAMPLE_MAX) {
                    interArrivalTimes.pollFirst();
                }
            }
            lastPacketTimestamp = now;

            // Get packet length
            java.lang.reflect.Field lenField = packetClass.getField("len");
            int len = lenField.getInt(packet);

            totalPackets.incrementAndGet();
            totalBytes.addAndGet(len);

            // Determine protocol
            String protocol = classifyPacket(packet);
            switch (protocol) {
                case "TCP" -> tcpPackets.incrementAndGet();
                case "UDP" -> udpPackets.incrementAndGet();
                case "ICMP" -> icmpPackets.incrementAndGet();
                case "ARP" -> arpPackets.incrementAndGet();
                default -> otherPackets.incrementAndGet();
            }

            // Track per-source connection
            String srcIp = extractSourceIP(packet);
            if (srcIp != null) {
                connectionMap.computeIfAbsent(srcIp, k -> new ConnectionMetrics(k))
                        .recordPacket(len, now);
            }

            // Notify listeners
            if (!listeners.isEmpty()) {
                PacketInfo info = new PacketInfo();
                info.timestamp = now;
                info.length = len;
                info.protocol = protocol;
                info.sourceIP = srcIp;
                info.destIP = extractDestIP(packet);
                for (PacketListener listener : listeners) {
                    try { listener.onPacket(info); } catch (Exception ignored) {}
                }
            }

        } catch (Exception e) {
            droppedPackets.incrementAndGet();
        }
    }

    /**
     * Classify packet protocol via reflection.
     */
    private String classifyPacket(Object packet) {
        String className = packet.getClass().getSimpleName();
        return switch (className) {
            case "TCPPacket" -> "TCP";
            case "UDPPacket" -> "UDP";
            case "ICMPPacket" -> "ICMP";
            case "ARPPacket" -> "ARP";
            default -> "OTHER";
        };
    }

    /**
     * Extract source IP from packet (reflection-based).
     */
    private String extractSourceIP(Object packet) {
        try {
            // IPPacket has src_ip field
            java.lang.reflect.Field srcField = packet.getClass().getField("src_ip");
            Object addr = srcField.get(packet);
            if (addr instanceof InetAddress ia) {
                return ia.getHostAddress();
            }
        } catch (NoSuchFieldException ignored) {
            // Not an IP packet (e.g. ARP)
        } catch (Exception ignored) {}
        return null;
    }

    /**
     * Extract destination IP from packet (reflection-based).
     */
    private String extractDestIP(Object packet) {
        try {
            java.lang.reflect.Field dstField = packet.getClass().getField("dst_ip");
            Object addr = dstField.get(packet);
            if (addr instanceof InetAddress ia) {
                return ia.getHostAddress();
            }
        } catch (NoSuchFieldException ignored) {
        } catch (Exception ignored) {}
        return null;
    }

    /**
     * Fallback monitoring when Jpcap is not available.
     * Uses /proc/net/dev on Linux for basic statistics.
     */
    private void fallbackMonitor() {
        while (running.get() && !Thread.currentThread().isInterrupted()) {
            try {
                java.nio.file.Path procNet = java.nio.file.Path.of("/proc/net/dev");
                if (java.nio.file.Files.exists(procNet)) {
                    List<String> lines = java.nio.file.Files.readAllLines(procNet);
                    for (String line : lines) {
                        if (line.contains(activeInterface + ":")) {
                            String[] parts = line.trim().split("\\s+");
                            if (parts.length >= 11) {
                                long rxBytes = Long.parseLong(parts[1]);
                                long rxPackets = Long.parseLong(parts[2]);
                                long rxDropped = Long.parseLong(parts[4]);
                                totalBytes.set(rxBytes);
                                totalPackets.set(rxPackets);
                                droppedPackets.set(rxDropped);
                            }
                        }
                    }
                }
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                break;
            } catch (Exception e) {
                try { Thread.sleep(5000); } catch (InterruptedException ie) { break; }
            }
        }
    }

    // ═══ Metrics Calculations ════════════════════════════════════════════════

    private double calculateJitter() {
        if (interArrivalTimes.size() < 2) return 0;
        long[] times = interArrivalTimes.stream().mapToLong(Long::longValue).toArray();
        double mean = 0;
        for (long t : times) mean += t;
        mean /= times.length;

        double variance = 0;
        for (long t : times) variance += (t - mean) * (t - mean);
        variance /= times.length;

        return Math.sqrt(variance);
    }

    private int calculateStabilityScore(StabilityReport report) {
        int score = 100;

        // Penalize for dropped packets
        if (report.totalPackets > 0) {
            double dropRate = (double) report.droppedPackets / report.totalPackets;
            if (dropRate > 0.05) score -= 40;       // >5% loss = serious
            else if (dropRate > 0.01) score -= 20;  // >1% loss = concerning
            else if (dropRate > 0.001) score -= 5;  // >0.1% = minor
        }

        // Penalize for high jitter (>10ms is noticeable)
        if (report.jitterMicroseconds > 10000) score -= 20;
        else if (report.jitterMicroseconds > 5000) score -= 10;
        else if (report.jitterMicroseconds > 1000) score -= 5;

        return Math.max(0, Math.min(100, score));
    }

    // ═══ Inner Classes ═══════════════════════════════════════════════════════

    /**
     * Network interface information.
     */
    public static class InterfaceInfo {
        public String name;
        public String displayName;
        public String macAddress;
        public int mtu;
        public boolean isLoopback;
        public boolean isPointToPoint;
        public boolean supportsMulticast;
        public List<String> addresses;

        @Override
        public String toString() {
            return name + " [" + (macAddress != null ? macAddress : "no-hw")
                    + "] MTU=" + mtu + " " + addresses;
        }
    }

    /**
     * Per-connection metrics tracker.
     */
    public static class ConnectionMetrics {
        public final String sourceIP;
        private final AtomicLong packetCount = new AtomicLong(0);
        private final AtomicLong byteCount = new AtomicLong(0);
        private volatile long firstSeen;
        private volatile long lastSeen;
        private final ConcurrentLinkedDeque<Long> recentTimestamps = new ConcurrentLinkedDeque<>();

        public ConnectionMetrics(String sourceIP) {
            this.sourceIP = sourceIP;
            this.firstSeen = System.currentTimeMillis();
        }

        public void recordPacket(int bytes, long timestampMicros) {
            packetCount.incrementAndGet();
            byteCount.addAndGet(bytes);
            lastSeen = System.currentTimeMillis();
            recentTimestamps.addLast(timestampMicros);
            while (recentTimestamps.size() > 100) recentTimestamps.pollFirst();
        }

        public long getPacketCount() { return packetCount.get(); }
        public long getByteCount() { return byteCount.get(); }
        public long getDurationMs() { return lastSeen - firstSeen; }

        public double getPacketsPerSecond() {
            long dur = getDurationMs();
            return dur > 0 ? (packetCount.get() * 1000.0) / dur : 0;
        }

        @Override
        public String toString() {
            return sourceIP + " — " + packetCount.get() + " pkts, "
                    + byteCount.get() + " bytes, " + getPacketsPerSecond() + " pps";
        }
    }

    /**
     * Packet information passed to listeners.
     */
    public static class PacketInfo {
        public long timestamp;
        public int length;
        public String protocol;
        public String sourceIP;
        public String destIP;
    }

    /**
     * Listener interface for real-time packet events.
     */
    @FunctionalInterface
    public interface PacketListener {
        void onPacket(PacketInfo packet);
    }

    /**
     * Overall stability report.
     */
    public static class StabilityReport {
        public String interfaceName;
        public String filter;
        public long uptimeSeconds;
        public long totalPackets;
        public long totalBytes;
        public long droppedPackets;
        public long tcpPackets;
        public long udpPackets;
        public long icmpPackets;
        public long arpPackets;
        public long otherPackets;
        public double jitterMicroseconds;
        public int stabilityScore;
        public List<ConnectionMetrics> connections;

        @Override
        public String toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("╔══════════════════════════════════════════════════╗\n");
            sb.append("║  Network Stability Report                       ║\n");
            sb.append("╠══════════════════════════════════════════════════╣\n");
            sb.append(String.format("║  Interface:   %-34s║\n", interfaceName));
            sb.append(String.format("║  Filter:      %-34s║\n", filter != null ? filter : "(none)"));
            sb.append(String.format("║  Uptime:      %-34s║\n", uptimeSeconds + "s"));
            sb.append(String.format("║  Score:       %-34s║\n", stabilityScore + "/100"));
            sb.append("╠══════════════════════════════════════════════════╣\n");
            sb.append(String.format("║  Packets:     %-34s║\n", totalPackets));
            sb.append(String.format("║  Bytes:       %-34s║\n", totalBytes));
            sb.append(String.format("║  Dropped:     %-34s║\n", droppedPackets));
            sb.append(String.format("║  Jitter:      %-34s║\n", String.format("%.1f µs", jitterMicroseconds)));
            sb.append("╠══════════════════════════════════════════════════╣\n");
            sb.append(String.format("║  TCP:         %-34s║\n", tcpPackets));
            sb.append(String.format("║  UDP:         %-34s║\n", udpPackets));
            sb.append(String.format("║  ICMP:        %-34s║\n", icmpPackets));
            sb.append(String.format("║  ARP:         %-34s║\n", arpPackets));
            sb.append(String.format("║  Other:       %-34s║\n", otherPackets));
            sb.append("╠══════════════════════════════════════════════════╣\n");
            sb.append(String.format("║  Connections: %-34s║\n", connections != null ? connections.size() : 0));
            sb.append("╚══════════════════════════════════════════════════╝\n");
            return sb.toString();
        }
    }
}
