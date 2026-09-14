package modules.Defined.source.protocol;

/**
 * SMTPSHandler — Protocol handler for SMTPS (port 465).
 * SSL-encrypted SMTP with implicit TLS. Outbound only.
 * Uses UFW to open port before use and close after execution.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class SMTPSHandler extends ProtocolHandler
{
    private String tlsVersion = "TLSv1.3";
    private final UFWFirewallManager ufwManager;

    public SMTPSHandler(UFWFirewallManager ufwManager)
    {
        super(465, "SMTPS", "SMTPS — SSL-encrypted SMTP (implicit TLS)");
        this.ufwManager = ufwManager;
    }

    /**
     * Send mail via SMTPS (implicit TLS on port 465).
     * Opens port via UFW, sends, closes port.
     */
    public boolean sendSecureMail(String host, String from, String to, String subject, String body, Credential cred) throws Exception
    {
        ufwManager.openPort(465, "out");
        try
        {
            javax.net.ssl.SSLSocketFactory factory = (javax.net.ssl.SSLSocketFactory)
                javax.net.ssl.SSLSocketFactory.getDefault();
            try (javax.net.ssl.SSLSocket socket = (javax.net.ssl.SSLSocket) factory.createSocket(host, 465))
            {
                socket.setSoTimeout(15000);
                socket.setEnabledProtocols(new String[]{tlsVersion});

                java.io.BufferedReader in = new java.io.BufferedReader(
                    new java.io.InputStreamReader(socket.getInputStream()));
                java.io.PrintWriter out = new java.io.PrintWriter(socket.getOutputStream(), true);

                // Read greeting
                in.readLine();

                // EHLO
                out.println("EHLO nwe.mearvk.us");
                readAllResponses(in);

                // AUTH LOGIN
                out.println("AUTH LOGIN");
                in.readLine();
                out.println(java.util.Base64.getEncoder().encodeToString(cred.username.getBytes()));
                in.readLine();
                out.println(java.util.Base64.getEncoder().encodeToString(cred.resolvePassword().getBytes()));
                String authResp = in.readLine();

                if (authResp == null || !authResp.startsWith("235"))
                {
                    logConnection("SMTPS auth failed: " + authResp);
                    return false;
                }

                // MAIL FROM, RCPT TO, DATA
                out.println("MAIL FROM:<" + from + ">");
                in.readLine();
                out.println("RCPT TO:<" + to + ">");
                in.readLine();
                out.println("DATA");
                in.readLine();
                out.println("From: " + from);
                out.println("To: " + to);
                out.println("Subject: " + subject);
                out.println("Content-Type: text/plain; charset=UTF-8");
                out.println("");
                out.println(body);
                out.println(".");
                in.readLine();
                out.println("QUIT");

                logConnection("SMTPS sent to " + to + " via " + host);
                return true;
            }
        }
        finally
        {
            ufwManager.closePort(465, "out");
        }
    }

    private void readAllResponses(java.io.BufferedReader in) throws java.io.IOException
    {
        // Read multi-line SMTP response
        String line;
        while ((line = in.readLine()) != null)
        {
            if (line.length() >= 4 && line.charAt(3) == ' ') break;
        }
    }

    @Override
    public void start()
    {
        active = true;
        logConnection("SMTPS handler started (implicit TLS, port 465, UFW-managed)");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("SMTPS handler stopped");
    }
}
