package connections;

import commons.CommonRails;
import commons.EnglishArithemeter;
import messaging.MessageQueue;
import server.base.BaseServer;
import server.nitro.WebExpress;
import telnet.TelnetMessageQueue;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.SocketTimeoutException;
import java.util.Date;

public class ConnectionPoller extends Thread
{
    protected String hash = "0xDA717018470E213F";

    protected BaseServer BASESERVER;

    protected ServerSocket SERVERSOCKET;

    protected String HOST;

    protected Integer PORT;

    protected WebExpress WEBEXPRESS;

    protected final String LINE_FEED = "\n";

    protected static final Integer READ_WRITE_STANDARD_SOCKET_TIMEOUT = 60*2*1000;

    public ConnectionPoller(BaseServer BASESERVER, String HOST, Integer PORT)
    {
        this.BASESERVER = BASESERVER;

        this.WEBEXPRESS = (WebExpress) this.BASESERVER.SUPERCLASS;

        this.HOST = HOST;

        this.PORT = PORT;

        this.setName("ConnectionPoller");
    }

    public ConnectionPoller(WebExpress WEBEXPRESS, BaseServer BASESERVER)
    {
        this.BASESERVER = BASESERVER;

        this.setName("ConnectionPoller");
    }

    @Override
    public void run()
    {
        MessageQueue.Message MESSAGE = new MessageQueue.Message();

        Connection CONNECTION = null;

        CurrentConnections CURRENT_CONNECTIONS = null;

        while(true)
        {
            try
            {
                CURRENT_CONNECTIONS = this.BASESERVER.CURRENT_CONNECTIONS;

                for(int i=0; i<CURRENT_CONNECTIONS.size(); i++)
                {
                    CurrentConnections CONNECTIONS = this.WEBEXPRESS.CURRENT_CONNECTIONS;

                    CONNECTION = CURRENT_CONNECTIONS.CURRENT_CONNECTION.get(i);

                    if(!CONNECTION.IS_TELNET_EXCELSIOR_CONNECTED)
                    {
                        EnglishArithemeter arithemeter = new EnglishArithemeter(CONNECTIONS.size());

                        CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> new CONNECTION from ["+CONNECTION.SOCKET.getRemoteSocketAddress()+"] total CONNECTION count ["+arithemeter.result.arithemetic+" : "+arithemeter.result.numeral+"].");

                        TelnetMessageQueue.Message TELNET_MESSAGE = new TelnetMessageQueue.Message();

                        TELNET_MESSAGE.PORT = Integer.parseInt(WebExpress.REMOTE_PORT);

                        TELNET_MESSAGE.SOCKET = this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.socket;

                        TELNET_MESSAGE.TIMESTAMP = new Date();

                        TELNET_MESSAGE.MESSAGE_BUFFER = new StringBuffer("US6");

                        this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.OUTPUT_BUILDER.TELNET_MESSAGE_QUEUE.add(TELNET_MESSAGE);

                        CONNECTION.IS_TELNET_EXCELSIOR_CONNECTED = Boolean.TRUE;
                    }

                    if(CommonRails.SocketUtils.isSocketConnected(MESSAGE.SOCKET))
                    {
                        MESSAGE.CONNECTION = CONNECTION;

                        MESSAGE.SOCKET = CONNECTION.SOCKET;

                        MESSAGE.INTERNET_ADDRESS = CONNECTION.SOCKET.getInetAddress();

                        MESSAGE.TIME_STAMP = new Date(System.currentTimeMillis());

                        MESSAGE.MESSAGE_BUFFER = new StringBuffer("US22.09");

                        BufferedReader READER = new BufferedReader(new InputStreamReader(CONNECTION.SOCKET.getInputStream()));

                        StringBuilder BUFFER = new StringBuilder();

                        String LINE = null;

                        try
                        {
                            if ((LINE=READER.readLine())!=null)
                            {
                                String LOCAL_TEMP = LINE;

                                BUFFER.append(LOCAL_TEMP);

                                for(LINE=null;(LINE=READER.readLine())!=null;)
                                {
                                    CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> reading in input ["+MESSAGE.SOCKET +"] for Telnet Proxy message ["+LINE+"].");

                                    MESSAGE.SOCKET.setSoTimeout(ConnectionPoller.READ_WRITE_STANDARD_SOCKET_TIMEOUT);

                                    BUFFER.append(LINE).append(LINE_FEED);
                                }
                            }

                            MESSAGE.MESSAGE_BUFFER = new StringBuffer(BUFFER);

                            this.WEBEXPRESS.MESSAGE_QUEUE.add(MESSAGE);
                        }
                        catch (SocketTimeoutException ste)
                        {
                            MESSAGE.MESSAGE_BUFFER = new StringBuffer(BUFFER);

                            this.WEBEXPRESS.MESSAGE_QUEUE.add(MESSAGE);

                            CONNECTIONS.remove(CONNECTION);

                            CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> graceful disconnect ["+MESSAGE.SOCKET.getRemoteSocketAddress()+"] ["+ste.getMessage()+"] total CONNECTION count ["+CONNECTIONS.size()+"].");
                        }
                        catch (Exception e)
                        {
                            CONNECTIONS.remove(CONNECTION);

                            CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> socket exception ["+e.getMessage()+"].");
                        }
                        finally
                        {
                            for(int k=0; k<CURRENT_CONNECTIONS.size(); k++)
                            {
                                Connection LATENT = CURRENT_CONNECTIONS.CURRENT_CONNECTION.get(k);

                                if(CommonRails.SocketUtils.isSocketClosed(LATENT.SOCKET))
                                {
                                    CURRENT_CONNECTIONS.remove(LATENT);

                                    CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> closed a sleeping turtle ["+LATENT.SOCKET +"].");
                                }
                            }

                            if(CommonRails.SocketUtils.isSocketConnected(MESSAGE.SOCKET))
                            {
                                MESSAGE.SOCKET.setSoTimeout(READ_WRITE_STANDARD_SOCKET_TIMEOUT);
                            }
                        }
                    }
                    else
                    {
                        try
                        {
                            if(CONNECTION.SOCKET !=null)
                            {
                                CONNECTION.SOCKET.close();
                            }
                        }
                        catch (Exception e)
                        {
                            CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> closed CONNECTION close.");
                        }
                    }
                }
            }
            catch (SocketTimeoutException ste)
            {
                CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> closing socket due to timeout ["+MESSAGE.SOCKET +"].");

                CURRENT_CONNECTIONS.remove(CONNECTION);

                if(MESSAGE.MESSAGE_BUFFER.length()>0)
                {
                    this.WEBEXPRESS.MESSAGE_QUEUE.add(MESSAGE);
                }

                CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> new CONNECTION count ["+CURRENT_CONNECTIONS.size()+"].");

                try
                {
                    if(CONNECTION!=null && CONNECTION.SOCKET !=null)
                    {
                        CONNECTION.SOCKET.close();
                    }
                }
                catch (Exception e)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> closed CONNECTION close.");
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
                    CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress ConnectionPoller >> closed CONNECTION on main polling thread sleep.");
                }
            }


        }
    }
}