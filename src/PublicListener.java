import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Date;

public class PublicListener extends Thread
{
    protected WebExpress web_express;

    protected Connections network_context;

    public PublicListener(Connections network_context)
    {
        this.network_context = network_context;
    }

    public PublicListener(WebExpress web_express)
    {
        this.web_express = web_express;
    }

    @Override
    public void run()
    {
        try
        {
            for(;;)
            {
                //Socket socket = this.web_express.web_express_server_socket.accept();

                System.out.println("WebExpress >> new connection ["+socket.toString()+"].");

                System.out.println("WebExpress >> new connection count ["+(this.web_express.current_connections.size()+1)+"].");

                this.web_express.current_connections.add(socket);

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

                this.web_express.addMessage(message);

                Thread.sleep(100);
            }
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}