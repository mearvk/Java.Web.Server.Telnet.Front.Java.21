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
import java.util.Date;
import java.util.concurrent.CopyOnWriteArrayList;

public class WebExpress extends CommonRail
{
    protected final String telnet_proxy_server = "telnet tacobell.phd 80";

    protected final Integer WEB_EXPRESS_SERVER_SOCKET = 49152;

    protected final Integer AES2_EXPRESS_SERVER_SOCKET = 5512;

    protected ServerSocket web_express_server_socket;

    protected ServerSocket aes2_server_socket;

    protected MessageQueue message_queue = new MessageQueue(5000);

    protected TelnetCommunicator telnet_communicator;

    protected MessageQueueSorter message_queue_sorter;

    protected CurrentConnections current_connections = new CurrentConnections();

    protected PublicSocketListener public_socket_lister;

    public WebExpress()
    {
        System.out.println("WebExpress >> starts ["+new Date()+"].");

        System.out.println("WebExpress::CommonRail >> starts ["+new Date()+"].");

        try
        {
            this.web_express_server_socket = new ServerSocket(this.WEB_EXPRESS_SERVER_SOCKET);

            this.aes2_server_socket = new ServerSocket(this.AES2_EXPRESS_SERVER_SOCKET);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }

        this.telnet_communicator = new TelnetCommunicator();

        this.message_queue_sorter = new MessageQueueSorter(this);

        this.public_socket_lister = new PublicSocketListener(this);

        this.public_socket_lister.start();

        this.message_queue_sorter.start();
    }

    public MessageQueue getMessageQueue()
    {
        return this.message_queue;
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

    public static class PublicSocketListener extends Thread
    {
        protected WebExpress web_express;

        public PublicSocketListener(WebExpress web_express)
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
                    Socket socket = this.web_express.web_express_server_socket.accept();

                    System.out.println("WebExpress >> new connection ["+socket.toString()+"].");

                    System.out.println("WebExpress >> new connection count ["+(this.web_express.current_connections.size()+1)+"].");

                    this.web_express.current_connections.add(socket);

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

                    message.message_buffer = buffer;

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
                        if(SocketUtils.isSocketConnected(message.socket))
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

                        System.out.println("WebExpress >> dropped connection ["+message.socket+"] - new connection count ["+(this.web_express.current_connections.size()+1)+"].");

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
                            if(SocketUtils.isSocketConnected(message.socket))
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
        protected CopyOnWriteArrayList<Message> messages;

        public MessageQueue(Integer size)
        {
            this.messages = new CopyOnWriteArrayList<>();
        }

        public void add(Message message)
        {
            this.messages.add(message);
        }

        public static class Message
        {
            protected Socket socket;

            protected Date time_stamp;

            protected StringBuffer message_buffer = new StringBuffer();

            protected InetAddress internet_address;
        }
    }

    public void install_remote_connections()
    {
        try
        {
            for(;;)
            {
                Socket socket = this.web_express_server_socket.accept();

                System.out.println("WebExpress >> new connection ["+socket.toString()+"].");

                System.out.println("WebExpress >> new connection stored; new count ["+(this.current_connections.size()+1)+"].");

                this.current_connections.add(socket);

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

                message.message_buffer = buffer;

                this.message_queue.add(message);

                Thread.sleep(1000);
            }
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }

    public void install_local_connections()
    {
        try
        {
            this.telnet_communicator.process_builder.command(telnet_proxy_server);

            this.telnet_communicator.process = this.telnet_communicator.process_builder.start();

            this.telnet_communicator.reader = new BufferedReader(new InputStreamReader(this.telnet_communicator.process.getInputStream()));

            this.telnet_communicator.writer = new BufferedWriter(new OutputStreamWriter(this.telnet_communicator.process.getOutputStream()));

            this._long("TelnetCommunicator::Close::Hook", this,1000);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}
