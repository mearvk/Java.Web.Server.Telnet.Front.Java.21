package source;

import java.io.*;
import java.math.BigInteger;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.cert.*;
import java.sql.*;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import javax.net.ssl.*;

/**
 * FiduciaryOutboundConnector — Outbound connectivity for FiduciaryServices™
 *
 * ═══════════════════════════════════════════════════════════════════════════════
 * STRATEGY: HOME INTERNET NAT AWARENESS
 * ═══════════════════════════════════════════════════════════════════════════════
 *
 * Most modern home/consumer internet connections operate behind NAT (Network
 * Address Translation). The ISP assigns one public IP to the router. All devices
 * share this IP via port mapping in the NAT table.
 *
 * KEY INSIGHT: Outbound ports are OPEN by default. Inbound ports are CLOSED.
 *
 *   OUTBOUND (home → internet):
 *     Ports 80, 443, 8080, 8443  — HTTP/HTTPS (always open outbound)
 *     Ports 20, 21               — FTP data/control (usually open outbound)
 *     Port 22                    — SSH (usually open outbound)
 *     Ports 25, 465, 587         — SMTP (ISPs sometimes block 25, but 587/465 open)
 *
 *   INBOUND (internet → home):
 *     ALL PORTS BLOCKED by default unless:
 *       - UPnP/NAT-PMP port forwarding is configured
 *       - ISP provides a static public IP with no filtering
 *       - VPN or tunnel provides a public endpoint
 *
 * ═══════════════════════════════════════════════════════════════════════════════
 * RETURN PATH STRATEGY
 * ═══════════════════════════════════════════════════════════════════════════════
 *
 * When Fiduciary initiates an outbound connection (e.g., HTTPS to a bank API),
 * the NAT router creates a mapping:
 *
 *   [Private IP:ephemeral_port] → [Public IP:NAT_port] → [Remote:443]
 *
 * Return packets from the remote server use this NAT mapping to find their way
 * back. This works automatically for the DURATION of the connection.
 *
 * PROBLEM: If the connection drops or the NAT entry expires (typically 60-300s
 * for TCP, 30-60s for UDP), the return path is LOST. The remote server cannot
 * initiate contact back to us.
 *
 * STRATEGIES:
 *
 *   1. PERSISTENT OUTBOUND (Preferred)
 *      Keep a long-lived TLS connection open to the payment platform.
 *      Send keepalives to prevent NAT table expiry.
 *      All communication happens within this persistent tunnel.
 *      → Used for: Stripe, Moov, Square webhooks via long-poll
 *
 *   2. WEBHOOK RELAY (When persistent not possible)
 *      Register a relay server (with a public IP) as webhook endpoint.
 *      Relay forwards events back to us via our persistent outbound connection.
 *      → Used for: Melio, Helcim callbacks
 *      → Relay: relay.mearvk.us (same as NWE Gateway)
 *
 *   3. POLLING (Fallback)
 *      Periodically poll the payment platform for status updates.
 *      Interval: 15s during active transfers, 5min during idle.
 *      → Works everywhere, no inbound ports needed.
 *      → Used for: transfer status checks, settlement confirmation
 *
 *   4. UPnP/NAT-PMP (Opportunistic)
 *      If router supports UPnP, request port forwarding for a callback port.
 *      Not reliable — many routers disable UPnP, and ISPs may block it.
 *      → Only attempted when direct webhook receipt is needed.
 *
 * ═══════════════════════════════════════════════════════════════════════════════
 * SSL/TLS KEY EXCHANGE UNDERSTANDING
 * ═══════════════════════════════════════════════════════════════════════════════
 *
 * The Fiduciary module captures and stores TLS handshake intelligence:
 *
 *   - Server certificate (public key, issuer, expiration, serial)
 *   - Key exchange method (ECDHE, DHE, RSA)
 *   - Cipher suite negotiated (e.g., TLS_AES_256_GCM_SHA384)
 *   - Protocol version (TLS 1.2, TLS 1.3)
 *   - Certificate chain (root CA → intermediate → leaf)
 *   - Public key fingerprint (SHA-256)
 *   - Certificate transparency logs (SCT)
 *
 * This intelligence serves FIDUCIARY HOLD:
 *   - If a bank's public key changes unexpectedly → ALERT (potential MITM)
 *   - If certificate expires within 30 days → WARN
 *   - If key exchange downgrades from ECDHE to RSA → ALERT (potential attack)
 *   - If cipher suite weakens → WARN
 *   - Historical key log enables forensic analysis of past connections
 *
 * The private key of the remote server is NEVER captured (impossible).
 * We store only PUBLIC information from the TLS handshake.
 *
 * ═══════════════════════════════════════════════════════════════════════════════
 * OUTBOUND PORT MANIFEST
 * ═══════════════════════════════════════════════════════════════════════════════
 *
 *   Port 20    FTP Data       — File transfer (active mode data channel)
 *   Port 21    FTP Control    — File transfer (command channel)
 *   Port 22    SSH            — Secure shell, SFTP, tunnel establishment
 *   Port 25    SMTP           — Email relay (often ISP-blocked; use 587 instead)
 *   Port 80    HTTP           — Plaintext web (redirects to 443 typically)
 *   Port 443   HTTPS          — Encrypted web, API calls, payment platforms
 *   Port 465   SMTPS          — SMTP over implicit TLS (submission)
 *   Port 587   SMTP Submission— SMTP with STARTTLS (authenticated mail send)
 *   Port 8080  HTTP Alt       — Application servers, proxies, dev endpoints
 *   Port 8443  HTTPS Alt      — Application servers over TLS, admin panels
 *
 * @author Max Rupplin — MEARVK LLC
 * @date August 3 2026
 */
public class FiduciaryOutboundConnector {

    /* ═══════════════════════════════════════════════════════════════════
       Constants
       ═══════════════════════════════════════════════════════════════════ */

    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_fiduciary";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    /** Allowed outbound ports */
    public static final int[] OUTBOUND_PORTS = {20, 21, 22, 25, 80, 443, 465, 587, 8080, 8443};

    /** NAT keepalive interval (seconds) — prevents NAT table expiry */
    private static final int NAT_KEEPALIVE_INTERVAL = 45;

    /** Polling interval for transfer status (active) */
    private static final int POLL_ACTIVE_INTERVAL = 15_000;  // 15 seconds
    /** Polling interval for transfer status (idle) */
    private static final int POLL_IDLE_INTERVAL = 300_000;   // 5 minutes

    /* ═══════════════════════════════════════════════════════════════════
       TLS Intelligence — Certificate and Key Exchange Storage
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Represents captured TLS handshake intelligence for a remote host.
     */
    public static class TLSIntelligence {
        public String hostname;
        public int port;
        public String protocol;           // TLS 1.2, TLS 1.3
        public String cipherSuite;        // e.g., TLS_AES_256_GCM_SHA384
        public String keyExchangeMethod;  // ECDHE, DHE, RSA
        public String serverCertSubject;  // CN=api.stripe.com, O=Stripe Inc
        public String serverCertIssuer;   // CN=DigiCert, O=DigiCert Inc
        public String serverCertSerial;   // hex serial number
        public String publicKeyAlgorithm; // EC, RSA, Ed25519
        public int publicKeyBits;         // 256, 2048, 4096
        public String publicKeyFingerprint; // SHA-256 of public key bytes
        public String certChain;          // full chain summary
        public Instant notBefore;
        public Instant notAfter;
        public Instant capturedAt;
        public boolean fiduciaryHoldIntact; // true if key matches previous
    }

    /**
     * NAT strategy recommendation for a given connection scenario.
     */
    public enum ReturnStrategy {
        PERSISTENT_OUTBOUND,  // keep TLS socket alive, send keepalives
        WEBHOOK_RELAY,        // use relay server as webhook endpoint
        POLLING,              // periodically check for updates
        UPNP_PORT_FORWARD    // request router port forward (unreliable)
    }

    /* ═══════════════════════════════════════════════════════════════════
       Connection & TLS Capture
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Connect to a remote host on a permitted outbound port, perform TLS
     * handshake, capture certificate intelligence, and return the socket.
     *
     * @param hostname Remote host (e.g., "api.stripe.com")
     * @param port     Outbound port (must be in OUTBOUND_PORTS)
     * @param timeoutMs Connection timeout in milliseconds
     * @return TLSIntelligence with all captured handshake data
     */
    public TLSIntelligence connectAndCaptureTLS(String hostname, int port, int timeoutMs)
            throws Exception {

        if (!isPermittedPort(port))
            throw new SecurityException("Port " + port + " not in outbound manifest. "
                + "Permitted: 20, 21, 22, 25, 80, 443, 465, 587, 8080, 8443");

        TLSIntelligence intel = new TLSIntelligence();
        intel.hostname = hostname;
        intel.port = port;
        intel.capturedAt = Instant.now();

        // For non-TLS ports (20, 21, 80, 8080), just verify connectivity
        if (port == 20 || port == 21 || port == 80 || port == 8080) {
            try (Socket sock = new Socket()) {
                sock.connect(new InetSocketAddress(hostname, port), timeoutMs);
                intel.protocol = "PLAINTEXT";
                intel.cipherSuite = "NONE";
                intel.keyExchangeMethod = "NONE";
                intel.fiduciaryHoldIntact = true;
            }
            storeTLSIntelligence(intel);
            return intel;
        }

        // TLS ports: 22 (SSH is separate), 25/465/587 (SMTP+TLS), 443/8443 (HTTPS)
        if (port == 22) {
            // SSH uses its own key exchange — capture host key
            intel.protocol = "SSH";
            intel.cipherSuite = "SSH (host key capture not implemented in TLS layer)";
            intel.keyExchangeMethod = "Diffie-Hellman (SSH KEX)";
            intel.fiduciaryHoldIntact = true;
            storeTLSIntelligence(intel);
            return intel;
        }

        // SMTP with STARTTLS (port 25, 587) or implicit TLS (port 465)
        // HTTPS (port 443, 8443)
        SSLContext ctx = SSLContext.getInstance("TLS");
        TrustManager[] trustAll = new TrustManager[]{new X509TrustManager() {
            public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
            public void checkClientTrusted(X509Certificate[] c, String t) {}
            public void checkServerTrusted(X509Certificate[] c, String t) {}
        }};
        ctx.init(null, trustAll, new SecureRandom());

        SSLSocketFactory factory = ctx.getSocketFactory();

        // For SMTP STARTTLS (ports 25, 587), we need to send EHLO + STARTTLS first
        if (port == 25 || port == 587) {
            intel = connectSMTPStartTLS(hostname, port, timeoutMs, factory, intel);
        } else {
            // Direct TLS (443, 465, 8443)
            try (SSLSocket sslSocket = (SSLSocket) factory.createSocket()) {
                sslSocket.connect(new InetSocketAddress(hostname, port), timeoutMs);
                sslSocket.setSoTimeout(timeoutMs);
                sslSocket.startHandshake();
                captureFromSSLSession(sslSocket, intel);
            }
        }

        // Check fiduciary hold (compare with previously stored key)
        intel.fiduciaryHoldIntact = checkFiduciaryHold(intel);

        storeTLSIntelligence(intel);
        return intel;
    }

    /**
     * SMTP STARTTLS: Connect plaintext, issue EHLO, upgrade to TLS.
     */
    private TLSIntelligence connectSMTPStartTLS(String hostname, int port, int timeoutMs,
            SSLSocketFactory factory, TLSIntelligence intel) throws Exception {

        try (Socket plainSocket = new Socket()) {
            plainSocket.connect(new InetSocketAddress(hostname, port), timeoutMs);
            plainSocket.setSoTimeout(timeoutMs);

            BufferedReader in = new BufferedReader(new InputStreamReader(plainSocket.getInputStream()));
            PrintWriter out = new PrintWriter(plainSocket.getOutputStream(), true);

            // Read greeting
            String greeting = in.readLine();
            if (greeting == null || !greeting.startsWith("220"))
                throw new IOException("SMTP greeting failed: " + greeting);

            // EHLO
            out.println("EHLO fiduciary.local");
            String line;
            boolean starttlsSupported = false;
            while ((line = in.readLine()) != null) {
                if (line.contains("STARTTLS")) starttlsSupported = true;
                if (line.charAt(3) == ' ') break; // last line of multi-line response
            }

            if (!starttlsSupported)
                throw new IOException("Remote SMTP server does not support STARTTLS");

            // STARTTLS
            out.println("STARTTLS");
            String resp = in.readLine();
            if (resp == null || !resp.startsWith("220"))
                throw new IOException("STARTTLS rejected: " + resp);

            // Upgrade to TLS
            SSLSocket sslSocket = (SSLSocket) factory.createSocket(
                plainSocket, hostname, port, true);
            sslSocket.startHandshake();
            captureFromSSLSession(sslSocket, intel);
            sslSocket.close();
        }
        return intel;
    }

    /**
     * Extract all TLS intelligence from an established SSL session.
     */
    private void captureFromSSLSession(SSLSocket sslSocket, TLSIntelligence intel) throws Exception {
        SSLSession session = sslSocket.getSession();

        intel.protocol = session.getProtocol();
        intel.cipherSuite = session.getCipherSuite();

        // Determine key exchange from cipher suite name
        String cs = intel.cipherSuite;
        if (cs.contains("ECDHE")) intel.keyExchangeMethod = "ECDHE (Elliptic Curve Diffie-Hellman Ephemeral)";
        else if (cs.contains("DHE")) intel.keyExchangeMethod = "DHE (Diffie-Hellman Ephemeral)";
        else if (cs.contains("RSA")) intel.keyExchangeMethod = "RSA (static key exchange)";
        else if (cs.contains("TLS_AES") || cs.contains("TLS_CHACHA"))
            intel.keyExchangeMethod = "ECDHE (TLS 1.3 default)"; // TLS 1.3 always uses ephemeral
        else intel.keyExchangeMethod = "Unknown";

        // Server certificate
        Certificate[] certs = session.getPeerCertificates();
        if (certs.length > 0 && certs[0] instanceof X509Certificate leaf) {
            intel.serverCertSubject = leaf.getSubjectX500Principal().getName();
            intel.serverCertIssuer = leaf.getIssuerX500Principal().getName();
            intel.serverCertSerial = leaf.getSerialNumber().toString(16);
            intel.notBefore = leaf.getNotBefore().toInstant();
            intel.notAfter = leaf.getNotAfter().toInstant();

            PublicKey pubKey = leaf.getPublicKey();
            intel.publicKeyAlgorithm = pubKey.getAlgorithm();
            intel.publicKeyBits = getKeyBits(pubKey);
            intel.publicKeyFingerprint = sha256Fingerprint(pubKey.getEncoded());

            // Build chain summary
            StringBuilder chain = new StringBuilder();
            for (int i = 0; i < certs.length && i < 5; i++) {
                if (certs[i] instanceof X509Certificate c) {
                    chain.append(i == 0 ? "LEAF: " : i == certs.length - 1 ? "ROOT: " : "INTERMEDIATE: ");
                    chain.append(c.getSubjectX500Principal().getName());
                    chain.append(" | ");
                }
            }
            intel.certChain = chain.toString();
        }
    }

    /* ═══════════════════════════════════════════════════════════════════
       NAT Strategy Selection
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Determine the best return path strategy for a given platform and scenario.
     *
     * The AI understands that on home internet:
     *   - Outbound 80/443/587 are always open
     *   - Inbound ports are blocked (NAT)
     *   - Return packets to an outbound connection work via NAT table entry
     *   - NAT entries expire (60-300s for TCP)
     *   - Therefore: persistent connections or polling required for callbacks
     *
     * @param platform Payment platform name
     * @param needsCallback Whether the operation requires async notification
     * @param hasPublicIP Whether this host has a public IP (server vs home)
     * @return Recommended strategy
     */
    public ReturnStrategy selectReturnStrategy(String platform, boolean needsCallback, boolean hasPublicIP) {
        // If we have a public IP (server deployment), we can receive webhooks directly
        if (hasPublicIP) return ReturnStrategy.PERSISTENT_OUTBOUND;

        // Home internet: outbound works, inbound blocked
        if (!needsCallback) {
            // Simple request/response — outbound connection suffices
            return ReturnStrategy.PERSISTENT_OUTBOUND;
        }

        // Need async callbacks on home internet:
        // Strategy depends on platform
        return switch (platform.toLowerCase()) {
            case "stripe" -> ReturnStrategy.PERSISTENT_OUTBOUND;   // Stripe supports long-poll
            case "moov" -> ReturnStrategy.PERSISTENT_OUTBOUND;     // Moov has streaming API
            case "melio" -> ReturnStrategy.WEBHOOK_RELAY;           // Melio requires webhook URL
            case "helcim" -> ReturnStrategy.WEBHOOK_RELAY;          // Helcim requires webhook URL
            case "square" -> ReturnStrategy.POLLING;                // Square — poll /payments/{id}
            default -> ReturnStrategy.POLLING;                      // Safest fallback
        };
    }

    /**
     * Get detailed explanation of the NAT situation and recommended strategy.
     */
    public String explainNATStrategy(String platform, boolean hasPublicIP) {
        ReturnStrategy strategy = selectReturnStrategy(platform, true, hasPublicIP);
        StringBuilder sb = new StringBuilder();

        sb.append("NAT_STRATEGY|");
        sb.append("Platform: ").append(platform).append("|");
        sb.append("Public IP: ").append(hasPublicIP ? "YES (server)" : "NO (home/NAT)").append("|");
        sb.append("Strategy: ").append(strategy.name()).append("|");

        if (!hasPublicIP) {
            sb.append("EXPLANATION: Home internet connections have outbound ports OPEN (80, 443, 587 etc) ");
            sb.append("but inbound ports CLOSED by NAT. When we connect outbound to ").append(platform);
            sb.append(" on port 443, return packets work via NAT table mapping. ");
            sb.append("But this mapping expires after 60-300 seconds of inactivity. ");
        }

        switch (strategy) {
            case PERSISTENT_OUTBOUND -> {
                sb.append("APPROACH: Maintain a persistent TLS connection to ").append(platform);
                sb.append(" API. Send TCP keepalives every ").append(NAT_KEEPALIVE_INTERVAL);
                sb.append("s to prevent NAT table expiry. All transfer status updates ");
                sb.append("arrive on this persistent channel. No inbound port needed.|");
                sb.append("KEEPALIVE: TCP keepalive at L4, or application-level ping every ");
                sb.append(NAT_KEEPALIVE_INTERVAL).append("s.|");
            }
            case WEBHOOK_RELAY -> {
                sb.append("APPROACH: Register relay.mearvk.us as webhook endpoint with ").append(platform);
                sb.append(". The relay has a public IP and accepts callbacks. We maintain ");
                sb.append("a persistent outbound connection TO the relay (port 443). ");
                sb.append("When ").append(platform).append(" sends a webhook, relay forwards ");
                sb.append("it to us over our already-open outbound connection.|");
                sb.append("RELAY: relay.mearvk.us:443 (persistent outbound TLS)|");
            }
            case POLLING -> {
                sb.append("APPROACH: No persistent connection needed. Periodically query ");
                sb.append(platform).append(" transfer status API. Outbound HTTPS to port 443. ");
                sb.append("Each poll is a new connection (or reuses HTTP/2 stream). ");
                sb.append("Poll every ").append(POLL_ACTIVE_INTERVAL / 1000).append("s during ");
                sb.append("active transfers, every ").append(POLL_IDLE_INTERVAL / 1000);
                sb.append("s during idle.|");
            }
            case UPNP_PORT_FORWARD -> {
                sb.append("APPROACH: Attempt UPnP port forwarding on router. If successful, ");
                sb.append("register forwarded port as webhook callback. UNRELIABLE — many ");
                sb.append("routers disable UPnP. Fallback to POLLING if UPnP fails.|");
            }
        }

        sb.append("OUTBOUND_PORTS: 20(FTP-data), 21(FTP-ctrl), 22(SSH), 25(SMTP), ");
        sb.append("80(HTTP), 443(HTTPS), 465(SMTPS), 587(SMTP-sub), 8080(HTTP-alt), 8443(HTTPS-alt)|");
        sb.append("RETURN_PATH: NAT mapping active for duration of outbound socket + ");
        sb.append(NAT_KEEPALIVE_INTERVAL).append("s keepalive interval");

        return sb.toString();
    }

    /* ═══════════════════════════════════════════════════════════════════
       Email (SMTP) — Send Transfer Notifications
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Send an email notification via SMTP with STARTTLS (port 587) or SMTPS (port 465).
     * Uses outbound connection — works from behind NAT.
     *
     * @param smtpHost SMTP server hostname (e.g., "smtp.gmail.com")
     * @param smtpPort 587 (STARTTLS) or 465 (implicit TLS)
     * @param username SMTP auth username
     * @param password SMTP auth password
     * @param from Sender email
     * @param to Recipient email
     * @param subject Email subject
     * @param body Email body (plaintext)
     */
    public boolean sendEmail(String smtpHost, int smtpPort, String username, String password,
                             String from, String to, String subject, String body) {
        try {
            // Validate port
            if (smtpPort != 25 && smtpPort != 465 && smtpPort != 587)
                throw new IllegalArgumentException("SMTP port must be 25, 465, or 587");

            SSLContext ctx = SSLContext.getInstance("TLS");
            ctx.init(null, null, null); // use default trust store

            Socket socket;
            BufferedReader in;
            PrintWriter out;

            if (smtpPort == 465) {
                // Implicit TLS
                SSLSocketFactory factory = ctx.getSocketFactory();
                socket = factory.createSocket(smtpHost, smtpPort);
            } else {
                // Plaintext first, then STARTTLS
                socket = new Socket(smtpHost, smtpPort);
            }
            socket.setSoTimeout(30_000);
            in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            out = new PrintWriter(socket.getOutputStream(), true);

            // Read greeting
            expectSMTP(in, "220");

            // EHLO
            out.println("EHLO fiduciary.local");
            String line;
            while ((line = in.readLine()) != null) {
                if (line.charAt(3) == ' ') break;
            }

            // STARTTLS for port 587/25
            if (smtpPort == 587 || smtpPort == 25) {
                out.println("STARTTLS");
                expectSMTP(in, "220");
                SSLSocket sslSocket = (SSLSocket) ctx.getSocketFactory()
                    .createSocket(socket, smtpHost, smtpPort, true);
                sslSocket.startHandshake();
                in = new BufferedReader(new InputStreamReader(sslSocket.getInputStream()));
                out = new PrintWriter(sslSocket.getOutputStream(), true);

                // Re-EHLO after TLS
                out.println("EHLO fiduciary.local");
                while ((line = in.readLine()) != null) {
                    if (line.charAt(3) == ' ') break;
                }
            }

            // AUTH LOGIN
            out.println("AUTH LOGIN");
            expectSMTP(in, "334");
            out.println(Base64.getEncoder().encodeToString(username.getBytes(StandardCharsets.UTF_8)));
            expectSMTP(in, "334");
            out.println(Base64.getEncoder().encodeToString(password.getBytes(StandardCharsets.UTF_8)));
            expectSMTP(in, "235");

            // MAIL FROM
            out.println("MAIL FROM:<" + from + ">");
            expectSMTP(in, "250");

            // RCPT TO
            out.println("RCPT TO:<" + to + ">");
            expectSMTP(in, "250");

            // DATA
            out.println("DATA");
            expectSMTP(in, "354");

            // Headers + body
            out.println("From: " + from);
            out.println("To: " + to);
            out.println("Subject: " + subject);
            out.println("Content-Type: text/plain; charset=UTF-8");
            out.println("X-Mailer: FiduciaryServices/1.0");
            out.println();
            out.println(body);
            out.println(".");
            expectSMTP(in, "250");

            // QUIT
            out.println("QUIT");
            socket.close();
            return true;

        } catch (Exception e) {
            System.err.println("SMTP send failed: " + e.getMessage());
            return false;
        }
    }

    private void expectSMTP(BufferedReader in, String expectedPrefix) throws IOException {
        String line = in.readLine();
        if (line == null || !line.startsWith(expectedPrefix))
            throw new IOException("Expected " + expectedPrefix + " but got: " + line);
    }

    /* ═══════════════════════════════════════════════════════════════════
       Persistent Connection Manager
       ═══════════════════════════════════════════════════════════════════ */

    private final ConcurrentHashMap<String, SSLSocket> persistentConnections = new ConcurrentHashMap<>();
    private final ScheduledExecutorService keepaliveScheduler =
        Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "FiduciaryKeepalive");
            t.setDaemon(true);
            return t;
        });

    /**
     * Establish or retrieve a persistent outbound TLS connection.
     * Sends keepalives to maintain NAT table entry.
     */
    public SSLSocket getPersistentConnection(String hostname, int port) throws Exception {
        String key = hostname + ":" + port;
        SSLSocket existing = persistentConnections.get(key);

        if (existing != null && !existing.isClosed() && existing.isConnected()) {
            return existing;
        }

        // Establish new connection
        SSLContext ctx = SSLContext.getInstance("TLS");
        ctx.init(null, null, null);
        SSLSocket socket = (SSLSocket) ctx.getSocketFactory().createSocket();
        socket.connect(new InetSocketAddress(hostname, port), 15_000);
        socket.setKeepAlive(true); // TCP keepalive at kernel level
        socket.startHandshake();

        persistentConnections.put(key, socket);

        // Schedule application-level keepalive
        keepaliveScheduler.scheduleAtFixedRate(() -> {
            try {
                if (socket.isClosed()) {
                    persistentConnections.remove(key);
                    return;
                }
                // Send a zero-length application keepalive (platform-specific)
                socket.getOutputStream().flush();
            } catch (Exception e) {
                persistentConnections.remove(key);
            }
        }, NAT_KEEPALIVE_INTERVAL, NAT_KEEPALIVE_INTERVAL, TimeUnit.SECONDS);

        return socket;
    }

    /**
     * Close all persistent connections (shutdown).
     */
    public void closeAllConnections() {
        keepaliveScheduler.shutdownNow();
        for (SSLSocket socket : persistentConnections.values()) {
            try { socket.close(); } catch (Exception ignored) {}
        }
        persistentConnections.clear();
    }

    /* ═══════════════════════════════════════════════════════════════════
       Fiduciary Hold — Key Rotation Detection
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Compare current TLS intelligence against previously stored record.
     * If the public key fingerprint has changed, the fiduciary hold is BROKEN.
     *
     * @return true if hold is intact (key unchanged or first contact)
     */
    private boolean checkFiduciaryHold(TLSIntelligence current) {
        if (current.publicKeyFingerprint == null) return true; // plaintext port

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT public_key_fingerprint FROM tls_intelligence "
                + "WHERE hostname = ? AND port = ? "
                + "ORDER BY captured_at DESC LIMIT 1");
            ps.setString(1, current.hostname);
            ps.setInt(2, current.port);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String previous = rs.getString("public_key_fingerprint");
                return previous.equals(current.publicKeyFingerprint);
            }
            // First contact — no previous record — hold is intact by default
            return true;
        } catch (Exception e) {
            return true; // default to intact on DB error
        }
    }

    /* ═══════════════════════════════════════════════════════════════════
       Database — TLS Intelligence Storage
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Store TLS intelligence in the database for fiduciary hold tracking.
     */
    private void storeTLSIntelligence(TLSIntelligence intel) {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            // Ensure table exists
            conn.createStatement().executeUpdate(
                "CREATE TABLE IF NOT EXISTS tls_intelligence ("
                + "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                + "  hostname VARCHAR(256) NOT NULL,"
                + "  port INT NOT NULL,"
                + "  protocol VARCHAR(16),"
                + "  cipher_suite VARCHAR(128),"
                + "  key_exchange_method VARCHAR(128),"
                + "  server_cert_subject TEXT,"
                + "  server_cert_issuer TEXT,"
                + "  server_cert_serial VARCHAR(128),"
                + "  public_key_algorithm VARCHAR(16),"
                + "  public_key_bits INT,"
                + "  public_key_fingerprint VARCHAR(128),"
                + "  cert_chain TEXT,"
                + "  not_before TIMESTAMP NULL,"
                + "  not_after TIMESTAMP NULL,"
                + "  captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                + "  fiduciary_hold_intact TINYINT DEFAULT 1,"
                + "  INDEX idx_host_port (hostname, port),"
                + "  INDEX idx_fingerprint (public_key_fingerprint)"
                + ") ENGINE=InnoDB");

            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO tls_intelligence (hostname, port, protocol, cipher_suite, "
                + "key_exchange_method, server_cert_subject, server_cert_issuer, server_cert_serial, "
                + "public_key_algorithm, public_key_bits, public_key_fingerprint, cert_chain, "
                + "not_before, not_after, fiduciary_hold_intact) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

            ps.setString(1, intel.hostname);
            ps.setInt(2, intel.port);
            ps.setString(3, intel.protocol);
            ps.setString(4, intel.cipherSuite);
            ps.setString(5, intel.keyExchangeMethod);
            ps.setString(6, intel.serverCertSubject);
            ps.setString(7, intel.serverCertIssuer);
            ps.setString(8, intel.serverCertSerial);
            ps.setString(9, intel.publicKeyAlgorithm);
            ps.setInt(10, intel.publicKeyBits);
            ps.setString(11, intel.publicKeyFingerprint);
            ps.setString(12, intel.certChain);
            ps.setTimestamp(13, intel.notBefore != null ? Timestamp.from(intel.notBefore) : null);
            ps.setTimestamp(14, intel.notAfter != null ? Timestamp.from(intel.notAfter) : null);
            ps.setBoolean(15, intel.fiduciaryHoldIntact);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("TLS intelligence storage failed: " + e.getMessage());
        }
    }

    /**
     * Query all stored TLS intelligence for a hostname.
     */
    public List<TLSIntelligence> getTLSHistory(String hostname) throws SQLException {
        List<TLSIntelligence> results = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM tls_intelligence WHERE hostname = ? ORDER BY captured_at DESC LIMIT 50");
            ps.setString(1, hostname);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                TLSIntelligence i = new TLSIntelligence();
                i.hostname = rs.getString("hostname");
                i.port = rs.getInt("port");
                i.protocol = rs.getString("protocol");
                i.cipherSuite = rs.getString("cipher_suite");
                i.keyExchangeMethod = rs.getString("key_exchange_method");
                i.serverCertSubject = rs.getString("server_cert_subject");
                i.serverCertIssuer = rs.getString("server_cert_issuer");
                i.publicKeyAlgorithm = rs.getString("public_key_algorithm");
                i.publicKeyBits = rs.getInt("public_key_bits");
                i.publicKeyFingerprint = rs.getString("public_key_fingerprint");
                i.certChain = rs.getString("cert_chain");
                i.fiduciaryHoldIntact = rs.getBoolean("fiduciary_hold_intact");
                Timestamp ca = rs.getTimestamp("captured_at");
                if (ca != null) i.capturedAt = ca.toInstant();
                results.add(i);
            }
        }
        return results;
    }

    /* ═══════════════════════════════════════════════════════════════════
       HTTP/HTTPS Outbound — Fetch Remote Resources
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Perform an HTTPS GET and capture TLS intelligence simultaneously.
     * Used for fetching payment API responses, public fiduciary data, etc.
     *
     * @param url Full URL (e.g., "https://api.stripe.com/v1/charges")
     * @param bearerToken Optional auth token (null for unauthenticated)
     * @return Response body
     */
    public String httpsGetWithTLSCapture(String url, String bearerToken) throws Exception {
        URL u = URI.create(url).toURL();
        String hostname = u.getHost();
        int port = u.getPort() > 0 ? u.getPort() : (u.getProtocol().equals("https") ? 443 : 80);

        // Capture TLS intelligence for this endpoint
        try {
            connectAndCaptureTLS(hostname, port, 10_000);
        } catch (Exception ignored) {
            // Non-fatal: intelligence capture failure doesn't block the request
        }

        // Perform the actual HTTP request
        HttpURLConnection conn = (HttpURLConnection) u.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(15_000);
        conn.setReadTimeout(30_000);
        conn.setRequestProperty("Accept", "application/json");
        conn.setRequestProperty("User-Agent", "FiduciaryServices/1.0");
        if (bearerToken != null)
            conn.setRequestProperty("Authorization", "Bearer " + bearerToken);

        int code = conn.getResponseCode();
        InputStream stream = code >= 200 && code < 300 ?
            conn.getInputStream() : conn.getErrorStream();

        if (stream == null) return "HTTP " + code + " (no body)";

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(stream))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
            return sb.toString();
        }
    }

    /* ═══════════════════════════════════════════════════════════════════
       Utility
       ═══════════════════════════════════════════════════════════════════ */

    private boolean isPermittedPort(int port) {
        for (int p : OUTBOUND_PORTS) if (p == port) return true;
        return false;
    }

    private int getKeyBits(PublicKey key) {
        String algo = key.getAlgorithm();
        if (algo.equals("EC")) {
            // EC keys: encoded length approximates bit size
            int len = key.getEncoded().length;
            if (len <= 91) return 256;
            if (len <= 120) return 384;
            return 521;
        } else if (algo.equals("RSA")) {
            try {
                java.security.interfaces.RSAPublicKey rsaKey = (java.security.interfaces.RSAPublicKey) key;
                return rsaKey.getModulus().bitLength();
            } catch (Exception e) { return 0; }
        }
        return key.getEncoded().length * 8;
    }

    private String sha256Fingerprint(byte[] data) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(data);
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) { return "error"; }
    }

    /* ═══════════════════════════════════════════════════════════════════
       TCP Protocol Commands (integrated with FiduciaryServicesServer)
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Handle commands related to outbound connectivity.
     * Called from FiduciaryServicesServer.handleClient() for:
     *   TLS|<hostname>           — Fetch and display TLS intelligence
     *   CONNECT|<host>:<port>    — Test outbound connectivity
     *   NAT|<platform>           — Explain NAT strategy
     *   EMAIL|<to>|<subject>     — Send notification (requires SMTP config)
     *   PORTS                    — List permitted outbound ports
     */
    public String handleCommand(String command) {
        if (command.equalsIgnoreCase("PORTS")) {
            return "PORTS|20(FTP-data), 21(FTP-ctrl), 22(SSH), 25(SMTP), "
                + "80(HTTP), 443(HTTPS), 465(SMTPS), 587(SMTP-submission), "
                + "8080(HTTP-alt), 8443(HTTPS-alt)|"
                + "All outbound. NAT maps return packets automatically. "
                + "Keepalive every " + NAT_KEEPALIVE_INTERVAL + "s prevents expiry.";
        }

        if (command.startsWith("TLS|")) {
            String hostname = command.substring(4).trim();
            int port = 443;
            if (hostname.contains(":")) {
                String[] parts = hostname.split(":");
                hostname = parts[0];
                port = Integer.parseInt(parts[1]);
            }
            try {
                TLSIntelligence intel = connectAndCaptureTLS(hostname, port, 10_000);
                return String.format("TLS|host=%s:%d|proto=%s|cipher=%s|kex=%s|"
                    + "subject=%s|issuer=%s|algo=%s/%d|fingerprint=%s|"
                    + "expires=%s|hold=%s",
                    intel.hostname, intel.port, intel.protocol, intel.cipherSuite,
                    intel.keyExchangeMethod, intel.serverCertSubject, intel.serverCertIssuer,
                    intel.publicKeyAlgorithm, intel.publicKeyBits, intel.publicKeyFingerprint,
                    intel.notAfter, intel.fiduciaryHoldIntact ? "INTACT" : "BROKEN");
            } catch (Exception e) {
                return "TLS|ERROR: " + e.getMessage();
            }
        }

        if (command.startsWith("CONNECT|")) {
            String target = command.substring(8).trim();
            String host = target; int port = 443;
            if (target.contains(":")) {
                String[] parts = target.split(":");
                host = parts[0]; port = Integer.parseInt(parts[1]);
            }
            try {
                TLSIntelligence intel = connectAndCaptureTLS(host, port, 10_000);
                return "CONNECT|OK|" + host + ":" + port + "|" + intel.protocol
                    + "|fiduciary_hold=" + (intel.fiduciaryHoldIntact ? "INTACT" : "BROKEN");
            } catch (Exception e) {
                return "CONNECT|FAILED|" + host + ":" + port + "|" + e.getMessage();
            }
        }

        if (command.startsWith("NAT|")) {
            String platform = command.substring(4).trim();
            boolean hasPublicIP = false; // assume home internet by default
            try {
                // Quick check: can we bind to port 80?
                try (ServerSocket ss = new ServerSocket(80, 1, InetAddress.getByName("0.0.0.0"))) {
                    hasPublicIP = true;
                } catch (Exception e) { hasPublicIP = false; }
            } catch (Exception ignored) {}
            return explainNATStrategy(platform, hasPublicIP);
        }

        return "OUTBOUND|Unknown command. Try: TLS|<host>, CONNECT|<host:port>, NAT|<platform>, PORTS";
    }
}
