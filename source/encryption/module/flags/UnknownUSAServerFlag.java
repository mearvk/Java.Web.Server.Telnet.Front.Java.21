/**
 * UnknownUSAServerFlag — Output flag for posting to an unknown/unverified
 * USA server between AES2 cipher passes. Includes additional caution fields.
 * Coordinates with US Calendar module and future US Communications Modules.
 *
 * @author Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.flags;

import java.io.OutputStream;
import java.net.Socket;
import javax.net.ssl.SSLSocketFactory;
import java.nio.charset.StandardCharsets;

public class UnknownUSAServerFlag
{
    private final String destination;
    private final int port;
    private final String protocol;
    private final String authorityLevel;
    private final String message;
    private final boolean requireAck;

    public UnknownUSAServerFlag(String destination, int port, String protocol, String authorityLevel, String message, boolean requireAck)
    {
        this.destination = destination;
        this.port = port;
        this.protocol = protocol;
        this.authorityLevel = authorityLevel;
        this.message = message;
        this.requireAck = requireAck;
    }

    public boolean post()
    {
        try
        {
            Socket socket;
            if ("TLS".equalsIgnoreCase(protocol) || "HTTPS".equalsIgnoreCase(protocol))
            {
                socket = SSLSocketFactory.getDefault().createSocket(destination, port);
            }
            else
            {
                socket = new Socket(destination, port);
            }

            OutputStream out = socket.getOutputStream();
            String payload = "FLAG|UNKNOWN_USA|" + authorityLevel + "|" + message;
            out.write(payload.getBytes(StandardCharsets.UTF_8));
            out.flush();

            if (requireAck)
            {
                socket.setSoTimeout(5000);
                byte[] buf = new byte[3];
                int read = socket.getInputStream().read(buf);
                socket.close();
                return read == 3 && new String(buf).equals("ACK");
            }

            socket.close();
            return true;
        }
        catch (Exception e)
        {
            System.err.println("[UnknownUSAServerFlag] Failed to post to " + destination + ":" + port + " — " + e.getMessage());
            return false;
        }
    }
}
