import java.net.Socket;
import java.util.ArrayList;

public class CurrentConnections
{
    ArrayList<Socket> current_connections = new ArrayList<>();

    public void add(Socket socket)
    {
        this.current_connections.add(socket);
    }

    public void remove(Socket socket)
    {
        this.current_connections.remove(socket);
    }

    public Integer size()
    {
        return this.current_connections.size();
    }
}
