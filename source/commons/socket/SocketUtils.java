package commons.socket;

import java.io.BufferedWriter;
import java.net.Proxy;
import java.net.Socket;

public final class SocketUtils {

    private SocketUtils() {}

    public static boolean isConnected(Socket s) {
        return s != null && s.isConnected() && !s.isClosed();
    }

    public static boolean isConnected(BufferedWriter writer)
    {
        try
        {
            writer.write("");

            return true;
        }
        catch (Exception e)
        {
            return false;
        }
    }

    public static boolean isClosed(Socket s) {
        return s == null || s.isClosed();
    }
}
