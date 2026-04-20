import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Date;

public class PublicListener extends Thread
{
    protected BaseServer base_server;

    protected ServerSocket server_socket;

    protected String host;

    protected Integer port;

    public PublicListener(String host, Integer port)
    {
        this.host = host;

        this.port = port;

        try
        {
            this.server_socket = new ServerSocket(port, 4096, InetAddress.getByName(host));
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }

    public PublicListener(BaseServer base_server)
    {
        this.base_server = base_server;

        try
        {
            this.server_socket = new ServerSocket(this.base_server.port, 4096, this.base_server.address);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }

    @Override
    public void run()
    {
        try
        {
            for(;;)
            {
                Socket socket = this.server_socket.accept();

                System.out.println("WebExpress >> new connection ["+socket.toString()+"].");

                System.out.println("WebExpress >> new connection count ["+(this.base_server.current_connections.size()+1)+"].");

                MessageQueue.Message message = new MessageQueue.Message();

                message.socket = socket;

                message.internet_address = socket.getInetAddress();

                message.time_stamp = new Date(System.currentTimeMillis());

                BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));

                StringBuffer buffer = new StringBuffer();

                String line = null;

                while ((line=reader.readLine())!=null)
                {
                    System.out.println("WebExpress::Public::Socket >> reading in input for Telnet Proxy ["+line+"].");

                    buffer.append(line);
                }

                message.message_buffer = new StringBuffer(buffer);

                this.base_server.addMessage(message);

                Thread.sleep(100);
            }
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}