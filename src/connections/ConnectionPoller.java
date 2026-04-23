package connections;

import commons.CommonRails;
import messaging.MessageQueue;
import server.BaseServer;
import server.WebExpress;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.util.Date;

public class ConnectionPoller extends Thread
{
    protected BaseServer base_server;

    protected WebExpress web_express;

    protected ServerSocket server_socket;

    protected String host;

    protected Integer port;

    public ConnectionPoller(WebExpress web_express, BaseServer base_server, String host, Integer port)
    {
        this.web_express = web_express;

        this.base_server = base_server;

        this.host = host;

        this.port = port;
    }

    public ConnectionPoller(WebExpress web_express, BaseServer base_server)
    {
        this.web_express = web_express;

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

                CommonRails.printSystemComponent(this.hashCode(), "[Object ID: "+this.hashCode()+"] WebExpress::connections.ConnectionPoller >> new connection from ["+connection.socket.toString()+"].");

                CommonRails.printSystemComponent(this.hashCode(), "[Object ID: "+this.hashCode()+"] WebExpress::connections.ConnectionPoller >> new connection count ["+size+"].");

                MessageQueue.Message message = new MessageQueue.Message();

                message.socket = connection.socket;

                message.internet_address = connection.socket.getInetAddress();

                message.time_stamp = new Date(System.currentTimeMillis());

                BufferedReader reader = new BufferedReader(new InputStreamReader(connection.socket.getInputStream()));

                StringBuffer buffer = new StringBuffer();

                String line = null;

                while ((line=reader.readLine())!=null)
                {
                    CommonRails.printSystemComponent(this.hashCode(), "[Object ID: "+this.hashCode()+"] WebExpress::connections.ConnectionPoller >> reading in input ["+message.socket+"] for Telnet Proxy ["+line+"].");

                    buffer.append(line);
                }

                message.message_buffer = new StringBuffer(buffer);

                this.web_express.message_queue.add(message);

                Thread.sleep(100);
            }
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}