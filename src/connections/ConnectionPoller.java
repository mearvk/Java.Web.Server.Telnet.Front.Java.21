package connections;

import commons.CommonRails;
import commons.EnglishArithemeter;
import messaging.MessageQueue;
import server.BaseServer;
import server.WebExpress;
import telnet.TelnetMessageQueue;

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

    protected final String LINE_FEED = "\n";

    protected static final Integer READ_WRITE_STANDARD_SOCKET_TIMEOUT = 60*2*1000;

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

        while(true)
        {
            try
            {
                current_connections = this.base_server.current_connections;

                for(int i=0; i<current_connections.size(); i++)
                {
                    CurrentConnections connections = this.web_express.current_connections;

                    connection = current_connections.current_connections.get(i);

                    if(!connection.IS_TELNET_EXCELSIOR_CONNECTED)
                    {
                        EnglishArithemeter arithemeter = new EnglishArithemeter(connections.size());

                        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> new connection from ["+connection.socket.getRemoteSocketAddress()+"] total connection count ["+arithemeter.result.arithemetic+" : "+arithemeter.result.numeral+"].");

                        TelnetMessageQueue.Message telnet_message = new TelnetMessageQueue.Message();

                        telnet_message.port = Integer.parseInt(WebExpress.REMOTE_PORT);

                        telnet_message.socket = this.web_express.telnet_communication_proxy.socket;

                        telnet_message.time_stamp = new Date();

                        telnet_message.message_buffer = new StringBuffer("US6");

                        this.web_express.telnet_communication_proxy.output_builder.telnet_message_queue.add(telnet_message);

                        connection.IS_TELNET_EXCELSIOR_CONNECTED = Boolean.TRUE;
                    }

                    if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                    {
                        message.connection = connection;

                        message.socket = connection.socket;

                        message.internet_address = connection.socket.getInetAddress();

                        message.time_stamp = new Date(System.currentTimeMillis());

                        message.message_buffer = new StringBuffer("US22.09");

                        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.socket.getInputStream()));

                        StringBuilder buffer = new StringBuilder();

                        String line = null;

                        try
                        {
                            if ((line=reader.readLine())!=null)
                            {
                                String local_tmp = line;

                                buffer.append(local_tmp);

                                for(line=null;(line=reader.readLine())!=null;)
                                {
                                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> reading in input ["+message.socket+"] for Telnet Proxy message ["+line+"].");

                                    message.socket.setSoTimeout(ConnectionPoller.READ_WRITE_STANDARD_SOCKET_TIMEOUT);

                                    buffer.append(line).append(LINE_FEED);
                                }
                            }

                            message.message_buffer = new StringBuffer(buffer);

                            this.web_express.message_queue.add(message);
                        }
                        catch (SocketTimeoutException ste)
                        {
                            message.message_buffer = new StringBuffer(buffer);

                            this.web_express.message_queue.add(message);

                            connections.remove(connection);

                            CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> graceful disconnect ["+message.socket.getRemoteSocketAddress()+"] ["+ste.getMessage()+"] total connection count ["+connections.size()+"].");
                        }
                        catch (Exception e)
                        {
                            connections.remove(connection);

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

                                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> closed a sleeping turtle ["+latent.socket+"].");
                                }
                            }

                            if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                            {
                                message.socket.setSoTimeout(READ_WRITE_STANDARD_SOCKET_TIMEOUT);
                            }
                        }
                    }
                    else
                    {
                        try
                        {
                            if(connection.socket!=null)
                            {
                                connection.socket.close();
                            }
                        }
                        catch (Exception e)
                        {
                            CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> closed connection close.");
                        }
                    }
                }
            }
            catch (SocketTimeoutException ste)
            {
                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> closing socket due to timeout ["+message.socket+"].");

                current_connections.remove(connection);

                if(message.message_buffer.length()>0)
                {
                    this.web_express.message_queue.add(message);
                }

                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> new connection count ["+current_connections.size()+"].");

                try
                {
                    if(connection!=null && connection.socket!=null)
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
            finally
            {
                try
                {
                    Thread.sleep(1500);
                }
                catch (Exception e)
                {
                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::ConnectionPoller >> closed connection on main polling thread sleep.");
                }
            }


        }
    }
}