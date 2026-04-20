import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.util.Date;

public class ConnectionPoller extends Thread
{
    protected BaseServer base_server;

    protected ServerSocket server_socket;

    protected String host;

    protected Integer port;

    public ConnectionPoller(BaseServer base_server, String host, Integer port)
    {
        this.base_server = base_server;

        this.host = host;

        this.port = port;
    }

    public ConnectionPoller(BaseServer base_server)
    {
        this.base_server = base_server;
    }

    @Override
    public void run()
    {
        try
        {
            CurrentConnections current_connections = this.base_server.current_connections;

            for(int i=0; i<current_connections.size(); i++)
            {
                Connection connection = current_connections.current_connections.get(i);

                Integer size = current_connections.size();

                System.out.println("WebExpress::ConnectionPoller >> new connection from ["+connection.socket.toString()+"].");

                System.out.println("WebExpress::ConnectionPoller >> new connection count ["+size+"].");

                MessageQueue.Message message = new MessageQueue.Message();

                message.socket = connection.socket;

                message.internet_address = connection.socket.getInetAddress();

                message.time_stamp = new Date(System.currentTimeMillis());

                BufferedReader reader = new BufferedReader(new InputStreamReader(connection.socket.getInputStream()));

                StringBuffer buffer = new StringBuffer();

                String line = null;

                while ((line=reader.readLine())!=null)
                {
                    System.out.println("WebExpress::ConnectionPoller >> reading in input for Telnet Proxy ["+line+"].");

                    buffer.append(line);
                }

                message.message_buffer = new StringBuffer(buffer);

                this.base_server.message_queue.add(message);

                Thread.sleep(100);
            }
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}