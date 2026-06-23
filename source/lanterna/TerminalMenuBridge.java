package lanterna;


import com.googlecode.lanterna.terminal.ansi.TelnetTerminal;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Field;
import java.net.Socket;

/**
 * TerminalMenuBridge — after a port is selected in TerminalMenu, bridges
 * the client's telnet socket to the selected service port so the user
 * interacts with that service as though directly connected.
 */
public class TerminalMenuBridge
{
    /**
     * Extracts the underlying Socket from a TelnetTerminal via reflection.
     */
    public static class SocketExtractor
    {
        public static Socket extract(TelnetTerminal terminal) throws ReflectiveOperationException
        {
            Field f = TelnetTerminal.class.getDeclaredField("socket");
            f.setAccessible(true);
            return (Socket) f.get(terminal);
        }
    }

    /**
     * Relay — bidirectional byte pump between two sockets.
     * Spawns two daemon threads: client→service and service→client.
     * Closes both sockets when either direction ends.
     */
    public static class Relay
    {
        private final Socket clientSocket;
        private final Socket serviceSocket;

        public Relay(Socket clientSocket, Socket serviceSocket)
        {
            this.clientSocket = clientSocket;
            this.serviceSocket = serviceSocket;
        }

        public void start()
        {
            Thread c2s = new Thread(() -> pump(clientSocket, serviceSocket), "Relay-C2S");
            Thread s2c = new Thread(() -> pump(serviceSocket, clientSocket), "Relay-S2C");
            c2s.setDaemon(true);
            s2c.setDaemon(true);
            c2s.start();
            s2c.start();
        }

        private void pump(Socket from, Socket to)
        {
            try
            {
                InputStream in = from.getInputStream();
                OutputStream out = to.getOutputStream();
                byte[] buf = new byte[4096];
                int n;
                while ((n = in.read(buf)) != -1)
                {
                    out.write(buf, 0, n);
                    out.flush();
                }
            }
            catch (IOException ignored) {}
            finally
            {
                close(clientSocket);
                close(serviceSocket);
            }
        }

        private static void close(Socket s)
        {
            try { if (!s.isClosed()) s.close(); } catch (IOException ignored) {}
        }
    }

    /**
     * ServiceConnector — opens a TCP connection to a target service port on localhost.
     */
    public static class ServiceConnector
    {
        public static final String HOST = "127.0.0.1";

        public static Socket connect(int port) throws IOException
        {
            return new Socket(HOST, port);
        }
    }

    /**
     * Bridges the given TelnetTerminal client to the service running on the specified port.
     * The Lanterna screen/terminal must already be closed before calling this.
     */
    public static void bridge(TelnetTerminal terminal, int port)
    {
        try
        {
            Socket clientSocket = SocketExtractor.extract(terminal);
            Socket serviceSocket = ServiceConnector.connect(port);
            new Relay(clientSocket, serviceSocket).start();
        }
        catch (ReflectiveOperationException e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }
        catch (IOException e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }
    }
}
