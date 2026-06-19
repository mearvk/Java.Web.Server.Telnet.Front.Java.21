/**
 * KnownUSServerFlag — Output flag for posting to a known US server
 * between AES2 cipher passes. Coordinates with US Calendar module
 * and future US Communications Modules.
 *
 * @author Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.flags;

import java.io.OutputStream;
import java.net.Socket;
import javax.net.ssl.SSLSocketFactory;
import java.nio.charset.StandardCharsets;

public class KnownUSServerFlag
{
    private final String destination;
    private final int port;
    private final String protocol;
    private final String authorityLevel;
    private final String message;

    public KnownUSServerFlag(String destination, int port, String protocol, String authorityLevel, String message)
    {
        this.destination = destination;
        this.port = port;
        this.protocol = protocol;
        this.authorityLevel = authorityLevel;
        this.message = message;
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
            String payload = "FLAG|KNOWN_US|" + authorityLevel + "|" + message;
            out.write(payload.getBytes(StandardCharsets.UTF_8));
            out.flush();
            socket.close();
            return true;
        }
        catch (Exception e)
        {
            System.err.println("[KnownUSServerFlag] Failed to post to " + destination + ":" + port + " — " + e.getMessage());
            return false;
        }
    }
}
