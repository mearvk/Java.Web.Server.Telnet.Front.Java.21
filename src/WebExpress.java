/**
 * @author Max Rupplin
 * @date April 18 2507-2671
 *
 * @us.governor Caesar Bernini
 */

import java.io.*;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

public class WebExpress extends BaseServer
{
    protected final String[] TELNET_PROXY_SERVER_ARGS = new String[]{"telnet", "tacobell.phd", "80"};

    protected static final Integer WEB_EXPRESS_SERVER_SOCKET = 49152;

    protected static final Integer AES2_EXPRESS_SERVER_SOCKET = 5512;

    protected ServerSocket web_express_server_socket;

    protected ServerSocket aes2_server_socket;

    protected MessageQueue message_queue = new MessageQueue(5000);

    protected TelnetCommunicator telnet_communicator;

    protected MessageQueueSorter message_queue_sorter;

    protected CurrentConnections current_connections = new CurrentConnections();

    protected PublicListener public_socket_listener;

    public WebExpress()
    {
        super("localhost", WEB_EXPRESS_SERVER_SOCKET);

        System.out.println("WebExpress >> starts ["+new Date()+"].");

        System.out.println("WebExpress::CommonRail >> starts ["+new Date()+"].");

        try
        {
            this.web_express_server_socket = new ServerSocket(WEB_EXPRESS_SERVER_SOCKET);

            this.aes2_server_socket = new ServerSocket(AES2_EXPRESS_SERVER_SOCKET);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);

            return;
        }
        finally
        {
            System.out.println("WebExpress::ServerSocket >> server created on port ["+this.port+"]");
        }

        this.telnet_communicator = new TelnetCommunicator();

        this.message_queue_sorter = new MessageQueueSorter(this);

        this.public_socket_listener = new PublicListener(this);

        this.public_socket_listener.start();

        this.message_queue_sorter.start();
    }

    public synchronized void addMessage(MessageQueue.Message message)
    {
        System.out.println("WebExpress::addMessage >> message queue size before ["+this.getMessageQueueSize()+"].");

        this.message_queue.add(message);

        System.out.println("WebExpress::addMessage >> message queue size after ["+this.getMessageQueueSize()+"].");
    }

    public synchronized MessageQueue getMessageQueue()
    {
        return this.message_queue;
    }

    public synchronized Integer getMessageQueueSize()
    {
        return this.message_queue.messages.size();
    }

    public static class TelnetCommunicator
    {
        public TelnetCommunicator()
        {
            System.out.println("WebExpress::Telnet::Communicator >> starts ["+new Date()+"].");
        }

        protected ProcessBuilder process_builder = new ProcessBuilder();

        protected Process process;

        protected BufferedWriter writer;

        protected BufferedReader reader;
    }

    public static class MessageQueueSorter extends Thread
    {
        protected WebExpress web_express;

        public MessageQueueSorter(WebExpress web_express)
        {
            this.web_express = web_express;
        }

        @Override
        public void run()
        {
            System.out.println("WebExpress::MessageQueueSorter >> starts ["+new Date()+"].");

            for(;;)
            {
                MessageQueue message_queue = this.web_express.getMessageQueue();

                System.out.println("WebExpress::MessageQueueSorter >> reports message queue has size of ["+message_queue.messages.size()+"].");

                for(int i=0; i<message_queue.messages.size(); i++)
                {
                    System.out.println("WebExpress::MessageQueueSorter >> received message.");

                    MessageQueue.Message message = message_queue.messages.remove(i);

                    try
                    {
                        if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                        {
                            BufferedWriter writer = this.web_express.telnet_communicator.writer;

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [Message]: " + message.message_buffer + "].");

                            writer.write("[Message]: " + message.message_buffer);

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [Date]: " + message.time_stamp + "].");

                            writer.write("[Date]: " + message.time_stamp);

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [IP Address]: " + message.internet_address + "].");

                            writer.write("[IP Address]: " + message.internet_address);

                            writer.write("[Socket]: " + message.socket);

                            writer.flush();
                        }
                    }
                    catch (NullPointerException npe)
                    {
                        this.web_express.current_connections.remove(message.socket);

                        System.out.println("WebExpress >> dropped connection ["+message.socket+"] - new connection count ["+(this.web_express.current_connections.size())+"].");

                        break;
                    }
                    catch (IOException e)
                    {
                        throw new RuntimeException(e);
                    }

                    try
                    {
                        BufferedReader reader = this.web_express.telnet_communicator.reader;

                        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(message.socket.getOutputStream()));

                        String line = null;

                        while((line=reader.readLine())!=null)
                        {
                            if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                            {
                                System.out.println("MessageQueueSorter >> replying with Proxy message ["+line+"].");

                                writer.write(line);

                                writer.flush();
                            }
                            else
                            {
                                this.web_express.current_connections.remove(message.socket);

                                System.out.println("WebExpress >> dropped connection ["+message.socket+"] - new connection count ["+(this.web_express.current_connections.size()+1)+"].");

                                break;
                            }
                        }

                        writer.close();
                    }
                    catch (Exception e)
                    {
                        e.printStackTrace(System.err);
                    }
                }

                try
                {
                    Thread.sleep(1000);
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }
            }
        }
    }

    public static class MessageQueue
    {
        protected List<Message> messages;

        public MessageQueue(Integer size)
        {
            this.messages = Collections.synchronizedList(messages = new ArrayList<>());
        }

        public void add(Message message)
        {
            synchronized (this)
            {
                this.messages.add(message);
            }
        }

        public static class Message
        {
            protected Socket socket;

            protected Date time_stamp;

            protected StringBuffer message_buffer = new StringBuffer();

            protected InetAddress internet_address;
        }
    }

    public void install_telnet_network()
    {
        try
        {
            this.telnet_communicator.process_builder.command(TELNET_PROXY_SERVER_ARGS);

            this.telnet_communicator.process = this.telnet_communicator.process_builder.start();

            this.telnet_communicator.reader = new BufferedReader(new InputStreamReader(this.telnet_communicator.process.getInputStream()));

            this.telnet_communicator.writer = new BufferedWriter(new OutputStreamWriter(this.telnet_communicator.process.getOutputStream()));

            CommonRails._long("TelnetCommunicator::Close::Hook", this,1000);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}
