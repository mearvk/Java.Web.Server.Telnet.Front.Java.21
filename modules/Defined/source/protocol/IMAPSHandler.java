package modules.Defined.source.protocol;

/**
 * IMAPSHandler — Protocol handler for IMAPS (port 993).
 * SSL-encrypted IMAP mail retrieval. Outbound only.
 * Uses UFW to open port before use and close after execution.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class IMAPSHandler extends ProtocolHandler
{
    private String tlsVersion = "TLSv1.3";
    private final UFWFirewallManager ufwManager;

    public IMAPSHandler(UFWFirewallManager ufwManager)
    {
        super(993, "IMAPS", "IMAPS — SSL-encrypted IMAP mail retrieval");
        this.ufwManager = ufwManager;
    }

    /**
     * Retrieve mail headers from an IMAPS server.
     * Opens port 993 via UFW, fetches, closes port.
     */
    public String fetchHeaders(String host, Credential cred) throws Exception
    {
        ufwManager.openPort(993, "out");
        try
        {
            // IMAPS connection via javax.net.ssl
            javax.net.ssl.SSLSocketFactory factory = (javax.net.ssl.SSLSocketFactory)
                javax.net.ssl.SSLSocketFactory.getDefault();
            try (javax.net.ssl.SSLSocket socket = (javax.net.ssl.SSLSocket) factory.createSocket(host, 993))
            {
                socket.setSoTimeout(15000);
                socket.setEnabledProtocols(new String[]{tlsVersion});

                java.io.BufferedReader in = new java.io.BufferedReader(
                    new java.io.InputStreamReader(socket.getInputStream()));
                java.io.PrintWriter out = new java.io.PrintWriter(socket.getOutputStream(), true);

                // Read greeting
                String greeting = in.readLine();
                logConnection("IMAPS greeting from " + host + ": " + greeting);

                // Login
                out.println("a1 LOGIN " + cred.username + " " + cred.resolvePassword());
                String loginResp = in.readLine();

                if (loginResp != null && loginResp.contains("OK"))
                {
                    // Select INBOX
                    out.println("a2 SELECT INBOX");
                    StringBuilder headers = new StringBuilder();
                    String line;
                    while ((line = in.readLine()) != null)
                    {
                        headers.append(line).append("\n");
                        if (line.startsWith("a2 ")) break;
                    }

                    // Logout
                    out.println("a3 LOGOUT");
                    logConnection("IMAPS fetch from " + host + " OK");
                    return headers.toString();
                }
                else
                {
                    logConnection("IMAPS login failed: " + loginResp);
                    return "";
                }
            }
        }
        finally
        {
            ufwManager.closePort(993, "out");
        }
    }

    @Override
    public void start()
    {
        active = true;
        logConnection("IMAPS handler started (TLS=" + tlsVersion + ", UFW-managed)");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("IMAPS handler stopped");
    }
}
