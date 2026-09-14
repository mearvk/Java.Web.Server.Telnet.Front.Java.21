package modules.Defined.source.protocol;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;

/**
 * SMTPHandler — Protocol handler for SMTP (port 25).
 * Outbound mail with STARTTLS upgrade capability.
 * Multiple credentials for admins and capitalists.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class SMTPHandler extends ProtocolHandler
{
    private boolean starttls = true;
    private String defaultFrom = "defined@nwe.mearvk.us";

    public SMTPHandler()
    {
        super(25, "SMTP", "SMTP — Simple Mail Transfer Protocol");
    }

    /**
     * Send a basic SMTP message (for report delivery, alerts).
     */
    public boolean sendMail(String host, String from, String to, String subject, String body, Credential cred)
    {
        try (Socket socket = new Socket())
        {
            socket.connect(new InetSocketAddress(host, port), 10000);
            socket.setSoTimeout(15000);

            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            PrintWriter out = new PrintWriter(new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8), true);

            // Read greeting
            String greeting = in.readLine();
            logConnection("SMTP greeting: " + greeting);

            // EHLO
            out.println("EHLO nwe.mearvk.us");
            readResponse(in);

            // STARTTLS if enabled (note: actual TLS upgrade would need SSLSocket)
            if (starttls)
            {
                out.println("STARTTLS");
                readResponse(in);
                // In production: upgrade to SSLSocket here
            }

            // AUTH if credential provided
            if (cred != null)
            {
                out.println("AUTH LOGIN");
                readResponse(in);
                out.println(java.util.Base64.getEncoder().encodeToString(cred.username.getBytes()));
                readResponse(in);
                out.println(java.util.Base64.getEncoder().encodeToString(cred.resolvePassword().getBytes()));
                readResponse(in);
            }

            // MAIL FROM
            out.println("MAIL FROM:<" + from + ">");
            readResponse(in);

            // RCPT TO
            out.println("RCPT TO:<" + to + ">");
            readResponse(in);

            // DATA
            out.println("DATA");
            readResponse(in);

            // Message
            out.println("From: " + from);
            out.println("To: " + to);
            out.println("Subject: " + subject);
            out.println("Content-Type: text/plain; charset=UTF-8");
            out.println("");
            out.println(body);
            out.println(".");
            readResponse(in);

            // QUIT
            out.println("QUIT");

            logConnection("MAIL-SENT: " + to + " subject=\"" + subject + "\"");
            return true;
        }
        catch (Exception e)
        {
            logConnection("MAIL-ERROR: " + e.getMessage());
            return false;
        }
    }

    private String readResponse(BufferedReader in) throws IOException
    {
        String line = in.readLine();
        return line != null ? line : "";
    }

    public void setStarttls(boolean enabled) { this.starttls = enabled; }
    public boolean isStarttls() { return starttls; }
    public void setDefaultFrom(String from) { this.defaultFrom = from; }
    public String getDefaultFrom() { return defaultFrom; }

    @Override
    public void start()
    {
        active = true;
        logConnection("SMTP handler started (STARTTLS=" + starttls + ")");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("SMTP handler stopped");
    }
}
