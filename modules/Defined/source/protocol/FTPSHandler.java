package modules.Defined.source.protocol;

/**
 * FTPSHandler — Protocol handler for FTPS (port 990).
 * SSL-encrypted FTP with implicit TLS. Outbound only.
 * Uses UFW to open port before use and close after execution.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class FTPSHandler extends ProtocolHandler
{
    private String tlsVersion = "TLSv1.3";
    private final UFWFirewallManager ufwManager;

    public FTPSHandler(UFWFirewallManager ufwManager)
    {
        super(990, "FTPS", "FTPS — SSL-encrypted FTP (implicit TLS)");
        this.ufwManager = ufwManager;
    }

    /**
     * Download a file from FTPS server.
     * Opens port 990 via UFW, retrieves, closes port.
     */
    public String retrieveFile(String host, String remotePath, Credential cred) throws Exception
    {
        ufwManager.openPort(990, "out");
        try
        {
            javax.net.ssl.SSLSocketFactory factory = (javax.net.ssl.SSLSocketFactory)
                javax.net.ssl.SSLSocketFactory.getDefault();
            try (javax.net.ssl.SSLSocket socket = (javax.net.ssl.SSLSocket) factory.createSocket(host, 990))
            {
                socket.setSoTimeout(15000);
                socket.setEnabledProtocols(new String[]{tlsVersion});

                java.io.BufferedReader in = new java.io.BufferedReader(
                    new java.io.InputStreamReader(socket.getInputStream()));
                java.io.PrintWriter out = new java.io.PrintWriter(socket.getOutputStream(), true);

                // FTP greeting
                String greeting = in.readLine();
                logConnection("FTPS greeting: " + greeting);

                // Login
                out.println("USER " + cred.username);
                in.readLine();
                out.println("PASS " + cred.resolvePassword());
                String loginResp = in.readLine();

                if (loginResp == null || !loginResp.startsWith("230"))
                {
                    logConnection("FTPS login failed: " + loginResp);
                    return "";
                }

                // PASV + RETR would follow in full implementation
                out.println("TYPE I");
                in.readLine();
                out.println("QUIT");

                logConnection("FTPS connected to " + host + " OK");
                return "FTPS-CONNECTED:" + host;
            }
        }
        finally
        {
            ufwManager.closePort(990, "out");
        }
    }

    @Override
    public void start()
    {
        active = true;
        logConnection("FTPS handler started (implicit TLS, port 990, UFW-managed)");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("FTPS handler stopped");
    }
}
