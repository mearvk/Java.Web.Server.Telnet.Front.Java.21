import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.util.ArrayList;

public class CurrentConnections
{
    public BaseServer server;

    public volatile Socket socket;

    public InputStream inputstream;

    public OutputStream outputstream;

    public String remote_address = null;

    public BufferedReader reader = null;

    public BufferedWriter writer = null;

    public PublicListener thread;

    ArrayList<Socket> current_connections = new ArrayList<>();

    public void add(Connection connection)
    {
        this.current_connections.add(socket);
    }

    public void remove(Connection connection)
    {
        this.current_connections.remove(socket);
    }

    public Integer size()
    {
        return this.current_connections.size();
    }
}
