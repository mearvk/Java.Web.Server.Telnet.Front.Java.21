package connections;

import commons.CommonRails;
import commons.EnglishArithemeter;
import messaging.MessageQueue;
import server.BaseServer;
import server.WebExpress;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.SocketTimeoutException;
import java.util.Date;

public class ConnectionPoller extends Thread
{
    protected BaseServer base_server;

    protected WebExpress web_express;

    protected ServerSocket server_socket;

    protected String host;

    protected Integer port;

    protected final Integer SOCKET_TIMEOUT = 20*1000;

    public ConnectionPoller(WebExpress web_express, BaseServer base_server, String host, Integer port)
    {
        this.web_express = web_express;

        this.base_server = base_server;

        this.host = host;

        this.port = port;

        this.setName("ConnectionPoller");
    }

    public ConnectionPoller(WebExpress web_express, BaseServer base_server)
    {
        this.web_express = web_express;

        this.base_server = base_server;

        this.setName("ConnectionPoller");
    }

    @Override
    public void run()
    {
        MessageQueue.Message message = new MessageQueue.Message();

        Connection connection = null;

        CurrentConnections current_connections = null;

        try
        {
            current_connections = this.base_server.current_connections;

            for(int i=0; i<current_connections.size(); i++)
            {
                connection = current_connections.current_connections.get(i);

                Integer size = current_connections.size();

                EnglishArithemeter meter = new EnglishArithemeter();

                String conversion = meter.convert(size);

                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> new connection from ["+connection.socket.toString()+"].");

                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> new connection count ["+conversion+" "+size+"].");

                message.connection = connection;

                message.socket = connection.socket;

                message.internet_address = connection.socket.getInetAddress();

                message.time_stamp = new Date(System.currentTimeMillis());

                BufferedReader reader = new BufferedReader(new InputStreamReader(connection.socket.getInputStream()));

                StringBuffer buffer = new StringBuffer();

                String line = null;

                try
                {
                    while ((line=reader.readLine())!=null)
                    {
                        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> reading in input ["+message.socket+"] for Telnet Proxy message ["+line+"].");

                        message.socket.setSoTimeout(60*1000);

                        buffer.append(line);
                    }

                    message.message_buffer = new StringBuffer(buffer);

                    this.web_express.message_queue.add(message);
                }
                catch (SocketTimeoutException ste)
                {
                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> graceful shutdown ["+message.socket+"] ["+ste.getMessage()+"].");
                }
                catch (Exception e)
                {
                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> socket exception ["+e.getMessage()+"].");
                }
                finally
                {
                    for(int k=0; k<current_connections.size(); k++)
                    {
                        Connection latent = current_connections.current_connections.get(k);

                        if(CommonRails.SocketUtils.isSocketClosed(latent.socket))
                        {
                            current_connections.remove(latent);

                            CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> closed a turtle ["+latent.socket+"].");
                        }
                    }

                    if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                    {
                        message.socket.setSoTimeout(SOCKET_TIMEOUT);
                    }
                }
            }
        }
        catch (SocketTimeoutException ste)
        {
            CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> closing socket due to timeout ["+message.socket+"].");

            current_connections.current_connections.remove(connection);

            if(message.message_buffer.length()>0)
            {
                this.web_express.message_queue.add(message);
            }

            CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> new connection count ["+current_connections.current_connections.size()+"].");

            try
            {
                if(connection!=null)
                {
                    connection.socket.close();
                }
            }
            catch (Exception e)
            {
                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> closed connection close.");
            }
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}