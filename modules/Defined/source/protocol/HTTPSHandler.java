package modules.Defined.source.protocol;

import javax.net.ssl.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.*;
import java.util.Base64;

/**
 * HTTPSHandler — Protocol handler for HTTPS / SSL (port 443).
 * Outbound secure connections for AI scanning and data retrieval.
 * Uses UFW to open port before use and close after execution.
 * TLSv1.3 with certificate verification.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class HTTPSHandler extends ProtocolHandler
{
    private String tlsVersion = "TLSv1.3";
    private boolean verifyCertificates = true;
    private Path truststore = Paths.get("data/ssl/truststore.jks");
    private String userAgent = "Defined-AI-Module/1.0 (NitroWebExpress; DarkGray; SSL)";
    private int connectTimeout = 10000;
    private int readTimeout = 15000;
    private final UFWFirewallManager ufwManager;

    public HTTPSHandler(UFWFirewallManager ufwManager)
    {
        super(443, "HTTPS", "HTTPS — SSL/TLS encrypted HTTP (outbound secure scanning)");
        this.ufwManager = ufwManager;
    }

    /**
     * Perform an authenticated HTTPS GET request.
     * Opens port 443 via UFW before use, closes after execution.
     */
    public String secureGet(String urlString, Credential cred) throws Exception
    {
        ufwManager.openPort(443, "out");

        try
        {
            URL url = new URL(urlString);
            HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
            conn.setConnectTimeout(connectTimeout);
            conn.setReadTimeout(readTimeout);
            conn.setRequestMethod("GET");
            conn.setRequestProperty("User-Agent", userAgent);

            // Configure SSL context
            if (!verifyCertificates)
            {
                SSLContext sc = SSLContext.getInstance(tlsVersion);
                sc.init(null, new TrustManager[]{new TrustAllManager()}, new SecureRandom());
                conn.setSSLSocketFactory(sc.getSocketFactory());
                conn.setHostnameVerifier((hostname, session) -> true);
            }

            // Apply auth
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
            logConnection("HTTPS GET " + urlString + " → " + code);

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
        finally
        {
            ufwManager.closePort(443, "out");
        }
    }

    /**
     * Simple unauthenticated HTTPS GET (for AI scanning).
     */
    public String get(String urlString) throws Exception
    {
        return secureGet(urlString, null);
    }

    public void setTlsVersion(String ver) { this.tlsVersion = ver; }
    public void setVerifyCertificates(boolean v) { this.verifyCertificates = v; }
    public void setTruststore(Path p) { this.truststore = p; }
    public void setUserAgent(String ua) { this.userAgent = ua; }

    @Override
    public void start()
    {
        active = true;
        try { Files.createDirectories(Paths.get("data/ssl")); } catch (IOException ignored) {}
        logConnection("HTTPS handler started (TLS=" + tlsVersion + ", verify=" + verifyCertificates + ", UFW-managed)");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("HTTPS handler stopped");
    }

    /**
     * Trust-all manager for development/testing (when verifyCertificates=false).
     */
    private static class TrustAllManager implements X509TrustManager
    {
        public java.security.cert.X509Certificate[] getAcceptedIssuers() { return null; }
        public void checkClientTrusted(java.security.cert.X509Certificate[] certs, String authType) {}
        public void checkServerTrusted(java.security.cert.X509Certificate[] certs, String authType) {}
    }
}
