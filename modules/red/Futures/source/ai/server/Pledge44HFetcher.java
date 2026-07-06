package red.Futures.source.ai.server;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.*;

/**
 * Pledge44HFetcher — fetches the 44H document from:
 * https://github.com/mearvk/Senior.Senate.Attorney.E44Hrs/blob/main/44H
 *
 * D44/N44 — University of North Carolina at Chapel Hill (UNC)
 * Proof of living consciousness and One Contract.
 * Eternal pledge of a Good Player, Max Rupplin, MEARVK LLC.
 *
 * Safety: validates the file is simply formatted plain text —
 * NOT an executable, install script, SQL script, or similar.
 * Only stores if safe. All attempts logged.
 *
 * Authenticity guaranteed by Max Rupplin, Senior Honest.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class Pledge44HFetcher
{
    private static final String SOURCE_URL =
        "https://raw.githubusercontent.com/mearvk/Senior.Senate.Attorney.E44Hrs/main/44H";
    private static final String DB_URL = "jdbc:mysql://localhost:3306/pledge_44h";
    private static final int MAX_SAFE_BYTES = 65536;

    // Dangerous patterns that indicate this is NOT a simple text file
    private static final String[] UNSAFE_PATTERNS = {
        "#!/",              // shebang (executable script)
        "#!/bin/bash",      // bash script
        "#!/usr/bin/env",   // env script
        "DROP TABLE",       // SQL injection
        "DROP DATABASE",    // SQL injection
        "CREATE TABLE",     // SQL script
        "INSERT INTO",      // SQL script
        "DELETE FROM",      // SQL script
        "ALTER TABLE",      // SQL script
        "<script",          // HTML/JS injection
        "import java.",     // Java source
        "package ",         // Java source
        "public class",     // Java source
        "sudo ",            // privilege escalation
        "rm -rf",           // destructive
        "curl ",            // network exec
        "wget ",            // network exec
        "exec(",            // execution
        "Runtime.getRuntime", // Java exec
        "ProcessBuilder",   // Java exec
        "\u0000",           // null bytes (binary)
        "\u007f",           // DEL (binary)
    };

    public static void main(String[] args) throws Exception
    {
        new Pledge44HFetcher().fetchAndStore();
    }

    public void fetchAndStore() throws Exception
    {
        System.out.println("[44H] Fetching pledge document from Senior.Senate.Attorney.E44Hrs...");

        HttpURLConnection conn = (HttpURLConnection) URI.create(SOURCE_URL).toURL().openConnection();
        conn.setConnectTimeout(10_000);
        conn.setReadTimeout(10_000);

        int httpCode = conn.getResponseCode();
        if (httpCode != 200)
        {
            logAttempt(httpCode, null, 0, false, "HTTP " + httpCode, false);
            System.out.println("[44H] FAILED — HTTP " + httpCode);
            return;
        }

        byte[] raw = conn.getInputStream().readAllBytes();
        conn.disconnect();

        String content = new String(raw, StandardCharsets.UTF_8);
        String hash = sha256(raw);
        int byteLen = raw.length;

        System.out.println("[44H] Received: " + byteLen + " bytes, SHA-256: " + hash);

        // Safety validation
        String rejection = validateSafety(content, byteLen);
        boolean safe = (rejection == null);

        if (!safe)
        {
            logAttempt(httpCode, hash, byteLen, false, rejection, false);
            System.out.println("[44H] REJECTED — " + rejection);
            return;
        }

        // Store in secondary database
        storeDocument(content, hash, byteLen);
        logAttempt(httpCode, hash, byteLen, true, "SAFE — plain text verified", true);

        System.out.println("[44H] STORED — authenticity guaranteed by Max Rupplin, Senior Honest");
    }

    /**
     * Validates the content is simply formatted plain text.
     * Returns null if safe, or a rejection reason if unsafe.
     */
    private String validateSafety(String content, int byteLen)
    {
        if (byteLen > MAX_SAFE_BYTES)
            return "exceeds max safe size (" + byteLen + " > " + MAX_SAFE_BYTES + ")";

        if (byteLen == 0)
            return "empty file";

        // Check for binary content (non-printable chars except newline/tab/cr)
        for (int i = 0; i < content.length(); i++)
        {
            char c = content.charAt(i);
            if (c < 0x20 && c != '\n' && c != '\r' && c != '\t')
                return "binary content detected at byte " + i;
        }

        // Check for dangerous patterns
        String lower = content.toLowerCase();
        for (String pattern : UNSAFE_PATTERNS)
        {
            if (lower.contains(pattern.toLowerCase()))
                return "unsafe pattern: " + pattern;
        }

        return null; // safe
    }

    private void storeDocument(String content, String hash, int byteLen) throws Exception
    {
        try (Connection conn = DriverManager.getConnection(DB_URL);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO document_versions (content, content_hash, byte_length, source_url) VALUES (?, ?, ?, ?)"))
        {
            ps.setString(1, content);
            ps.setString(2, hash);
            ps.setInt(3, byteLen);
            ps.setString(4, SOURCE_URL);
            ps.executeUpdate();
        }
    }

    private void logAttempt(int httpCode, String hash, int byteLen, boolean safe, String note, boolean stored) throws Exception
    {
        try (Connection conn = DriverManager.getConnection(DB_URL);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO fetch_attempts (http_code, content_hash, byte_length, safe, rejection_reason, stored) VALUES (?, ?, ?, ?, ?, ?)"))
        {
            ps.setInt(1, httpCode);
            ps.setString(2, hash);
            ps.setInt(3, byteLen);
            ps.setBoolean(4, safe);
            ps.setString(5, note);
            ps.setBoolean(6, stored);
            ps.executeUpdate();
        }
    }

    private String sha256(byte[] data) throws Exception
    {
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(data);
        StringBuilder sb = new StringBuilder();
        for (byte b : digest) sb.append(String.format("%02x", b));
        return sb.toString();
    }
}
