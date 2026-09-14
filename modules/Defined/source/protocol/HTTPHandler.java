package modules.Defined.source.protocol;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * HTTPHandler — Protocol handler for HTTP (port 80).
 * Used by the AI module for internet scanning.
 * Supports Basic and Bearer auth for admins and capitalists.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class HTTPHandler extends ProtocolHandler
{
    private String userAgent = "Defined-AI-Module/1.0 (NitroWebExpress; DarkGray)";
    private int connectTimeout = 10000;
    private int readTimeout = 15000;

    public HTTPHandler()
    {
        super(80, "HTTP", "HTTP — Internet access for AI scanning");
    }

    /**
     * Perform an authenticated HTTP GET request.
     * Uses the specified credential for auth header.
     */
    public String authenticatedGet(String urlString, Credential cred) throws IOException
    {
        URL url = new URL(urlString);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setConnectTimeout(connectTimeout);
        conn.setReadTimeout(readTimeout);
        conn.setRequestMethod("GET");
        conn.setRequestProperty("User-Agent", userAgent);

        // Apply auth based on credential type
        if (cred != null)
        {
            String pass = cred.resolvePassword();
            if ("Basic".equalsIgnoreCase(cred.authType))
            {
                String encoded = Base64.getEncoder().encodeToString(
                    (cred.username + ":" + pass).getBytes(StandardCharsets.UTF_8));
                conn.setRequestProperty("Authorization", "Basic " + encoded);
            }
            else if ("Bearer".equalsIgnoreCase(cred.authType))
            {
                conn.setRequestProperty("Authorization", "Bearer " + pass);
            }
        }

        int code = conn.getResponseCode();
        logConnection("GET " + urlString + " → HTTP " + code);

        if (code == 200)
        {
            try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
            {
                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) sb.append(line).append("\n");
                return sb.toString();
            }
        }

        conn.disconnect();
        return "";
    }

    /**
     * Simple unauthenticated GET (for AI scanning).
     */
    public String get(String urlString) throws IOException
    {
        return authenticatedGet(urlString, null);
    }

    public void setUserAgent(String ua) { this.userAgent = ua; }
    public void setConnectTimeout(int ms) { this.connectTimeout = ms; }
    public void setReadTimeout(int ms) { this.readTimeout = ms; }

    @Override
    public void start()
    {
        active = true;
        logConnection("HTTP handler started (outbound, scan-enabled)");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("HTTP handler stopped");
    }
}
