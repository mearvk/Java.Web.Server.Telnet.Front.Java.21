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

    public ConnectionPoller thread;

    ArrayList<Connection> current_connections = new ArrayList<Connection>();

    public void add(Connection connection)
    {
        this.current_connections.add(connection);
    }

    public void remove(Socket socket)
    {
        for(int i=0; i<this.current_connections.size(); i++)
        {
            Socket _socket = this.current_connections.get(i).socket;

            if(_socket==socket)
            {
                Connection connection = this.current_connections.get(i);

                this.current_connections.remove(connection);
            }
        }
    }

    public void remove(Connection connection)
    {
        this.current_connections.remove(connection);
    }

    public Integer size()
    {
        return this.current_connections.size();
    }
}
