package commons;

import java.io.*;
import java.net.*;

/**
 * StrernaryConnector — Reusable utility for querying Strernary™ on port 20000.
 *
 * Provides a simple interface for any NWE module to send an ASK|<text> query
 * to the Strernary inference server and get a response. Handles connection
 * timeouts, read timeouts, and graceful fallback when Strernary is offline.
 *
 * Usage:
 *   String answer = StrernaryConnector.ask("What is the capital of Japan?");
 *   // returns null if Strernary is offline
 *
 *   String answer = StrernaryConnector.askOrDefault("...", "No AI inference available");
 *   // returns default if Strernary is offline
 *
 *   boolean online = StrernaryConnector.isOnline();
 *
 * MEARVK LLC — 2026
 */
public class StrernaryConnector
{
    public static final int PORT = 20000;
    public static final String HOST = "127.0.0.1";
    private static final int CONNECT_TIMEOUT = 3000;  // 3s connect
    private static final int READ_TIMEOUT = 25000;    // 25s read

    /**
     * Send an ASK query to Strernary™ and return the response.
     *
     * @param query The question or text to send
     * @return The inference response, or null if Strernary is offline/unavailable
     */
    public static String ask(String query) {
        try {
            Socket sock = new Socket();
            sock.connect(new InetSocketAddress(HOST, PORT), CONNECT_TIMEOUT);
            sock.setSoTimeout(READ_TIMEOUT);

            PrintWriter out = new PrintWriter(sock.getOutputStream(), true);
            BufferedReader in = new BufferedReader(new InputStreamReader(sock.getInputStream()));

            out.println("ASK|" + query);

            StringBuilder response = new StringBuilder();
            String line;
            long deadline = System.currentTimeMillis() + READ_TIMEOUT;
            while ((line = in.readLine()) != null && System.currentTimeMillis() < deadline) {
                if (line.isEmpty()) break;
                response.append(line).append("\n");
            }

            sock.close();
            return response.length() > 0 ? response.toString().trim() : null;

        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Send an ASK query to Strernary™, returning a default value if offline.
     *
     * @param query        The question or text to send
     * @param defaultValue Returned if Strernary is offline or returns empty
     * @return The inference response, or defaultValue
     */
    public static String askOrDefault(String query, String defaultValue) {
        String result = ask(query);
        return result != null ? result : defaultValue;
    }

    /**
     * Check if Strernary™ is reachable on port 20000.
     *
     * @return true if a TCP connection can be established within timeout
     */
    public static boolean isOnline() {
        try (Socket sock = new Socket()) {
            sock.connect(new InetSocketAddress(HOST, PORT), CONNECT_TIMEOUT);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Send a RELAY command (for cross-module routing).
     *
     * @param text The text to relay
     * @return Response from Strernary relay, or null
     */
    public static String relay(String text) {
        try {
            Socket sock = new Socket();
            sock.connect(new InetSocketAddress(HOST, PORT), CONNECT_TIMEOUT);
            sock.setSoTimeout(READ_TIMEOUT);

            PrintWriter out = new PrintWriter(sock.getOutputStream(), true);
            BufferedReader in = new BufferedReader(new InputStreamReader(sock.getInputStream()));

            out.println("RELAY|" + text);

            StringBuilder response = new StringBuilder();
            String line;
            long deadline = System.currentTimeMillis() + READ_TIMEOUT;
            while ((line = in.readLine()) != null && System.currentTimeMillis() < deadline) {
                if (line.isEmpty()) break;
                response.append(line).append("\n");
            }

            sock.close();
            return response.length() > 0 ? response.toString().trim() : null;

        } catch (Exception e) {
            return null;
        }
    }
}
