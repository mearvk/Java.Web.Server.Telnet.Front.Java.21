package source;

import java.io.*;
import java.net.*;

/**
 * SpectrumTandem™ — Protocol Handler
 * Handles incoming telnet protocol commands for the SpectrumTandem module.
 *
 * Protocol Format:
 *   COMMAND|ARG1|ARG2|...
 *
 * Supported Commands:
 *   DEFINE|<term>                         — Get full definition of a term
 *   LOOKUP|<term>                         — Search by spelling/radix variant
 *   RADIX|<radix>                         — Search by radix root
 *   SPECTRUM|<term>                       — Get dolyene spectrum (int discipline graph)
 *   COUNTY|<county>                       — Query county precedent (full caps)
 *   REVISE|<term>|<definition>|<authorId> — Revise a term's definition
 *   ADD|<term>|<def>|<specialness>|<auth> — Add new term to word bank
 *   HISTORY|<term>                        — Get revision history for a term
 *   WORDBANK                              — List all terms in word bank
 *   SEARCH|<keyword>                      — AI-assisted search via Strernary™
 *   STATUS                                — Module status
 *   HELP                                  — Show command list
 *   QUIT                                  — Close session
 *
 * Response Format:
 *   COMMAND|STATUS|field=value|field=value|...
 *
 * Installer Tech ID: Max Rupplin
 * MEARVK LLC — NitroWebExpress™ 2026
 */
public class SpectrumTandemProtocolHandler {

    private static final int PORT = 49222;
    private static final int TIMEOUT_MS = 10000;

    /**
     * Send a command to the SpectrumTandem backend and return the response.
     */
    public static String sendCommand(String command) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", PORT), TIMEOUT_MS);
            socket.setSoTimeout(TIMEOUT_MS);

            PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));

            // Read the READY banner
            String banner = in.readLine();

            // Send command
            out.println(command);
            String response = in.readLine();

            // Close gracefully
            out.println("QUIT");
            in.readLine(); // BYE response

            return response != null ? response : "ERROR|No response";
        } catch (Exception e) {
            return "ERROR|Connection failed: " + e.getMessage();
        }
    }

    /**
     * Define a term — DEFINE|<term>
     */
    public static String define(String term) {
        return sendCommand("DEFINE|" + term);
    }

    /**
     * Lookup by spelling — LOOKUP|<term>
     */
    public static String lookup(String term) {
        return sendCommand("LOOKUP|" + term);
    }

    /**
     * Search by radix — RADIX|<radix>
     */
    public static String radix(String radix) {
        return sendCommand("RADIX|" + radix);
    }

    /**
     * Get dolyene spectrum — SPECTRUM|<term>
     */
    public static String spectrum(String term) {
        return sendCommand("SPECTRUM|" + term);
    }

    /**
     * Query county precedent — COUNTY|<county>
     */
    public static String county(String county) {
        return sendCommand("COUNTY|" + county);
    }

    /**
     * Revise a term — REVISE|<term>|<definition>|<authorId>
     */
    public static String revise(String term, String definition, String authorId) {
        return sendCommand("REVISE|" + term + "|" + definition + "|" + authorId);
    }

    /**
     * Add a term — ADD|<term>|<definition>|<specialness>|<authorId>
     */
    public static String add(String term, String definition, String specialness, String authorId) {
        return sendCommand("ADD|" + term + "|" + definition + "|" + specialness + "|" + authorId);
    }

    /**
     * Get revision history — HISTORY|<term>
     */
    public static String history(String term) {
        return sendCommand("HISTORY|" + term);
    }

    /**
     * List word bank — WORDBANK
     */
    public static String wordBank() {
        return sendCommand("WORDBANK");
    }

    /**
     * AI search — SEARCH|<keyword>
     */
    public static String search(String keyword) {
        return sendCommand("SEARCH|" + keyword);
    }

    /**
     * Status check — STATUS
     */
    public static String status() {
        return sendCommand("STATUS");
    }
}
