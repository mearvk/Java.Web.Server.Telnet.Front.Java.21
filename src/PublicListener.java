import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.Socket;
import java.util.Date;

public class PublicListener extends Thread
{
    protected BaseServer base_server;

    public PublicListener()
    {

    }

    public PublicListener(BaseServer base_server)
    {
        this.base_server = base_server;
    }

    @Override
    public void run()
    {
        try
        {
            for(;;)
            {
                Socket socket = this.base_server.web_express_server_socket.accept();

                System.out.println("WebExpress >> new connection ["+socket.toString()+"].");

                System.out.println("WebExpress >> new connection count ["+(this.base_server.current_connections.size()+1)+"].");

                WebExpress.MessageQueue.Message message = new WebExpress.MessageQueue.Message();

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