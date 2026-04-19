import java.io.*;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class WebExpress extends CommonRail
{
    protected final String telnet_proxy_server = "telnet tacobell.phd 80";

    protected Integer WebExpress_listener_port = 49152;

    protected Integer AES2_listener_port = 5512;

    protected ServerSocket WebExpress_server_socket;

    protected ServerSocket AES2_server_socket;

    protected MessageQueue message_queue = new MessageQueue(5000);

    protected TelnetCommunicator telnet_communicator;

    protected MessageQueueSorter message_queue_sorter;

    public WebExpress()
    {
        System.out.println("WebExpress >> starts ["+new Date()+"].");

        System.out.println("WebExpress::CommonRail >> starts ["+new Date()+"].");

        this.telnet_communicator = new TelnetCommunicator();

        this.message_queue_sorter = new MessageQueueSorter(this);

        this.message_queue_sorter.start();
    }

    public static class TelnetCommunicator
    {
        public TelnetCommunicator()
        {
            System.out.println("WebExpress::TelnetCommunicator >> starts ["+new Date()+"].");
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
                MessageQueue message_queue = this.web_express.message_queue;

                System.out.println("WebExpress::MessageQueueSorter >> reports messaage queue has size of ["+message_queue.messages.size()+"].");

                for(int i=0; i<message_queue.messages.size(); i++)
                {
                    System.out.println("WebExpress::MessageQueueSorter >> received message.");

                    MessageQueue.Message message = message_queue.messages.get(i);

                    try
                    {
                        if(CommonRail.CommonUtils.socketIsConnected(message.socket))
                        {
                            BufferedWriter writer = this.web_express.telnet_communicator.writer;

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [MESSAGE]: " + message.message_buffer + "].");

                            writer.write("[MESSAGE]: " + message.message_buffer);

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [DATE]: " + message.time_stamp + "].");

                            writer.write("[DATE]: " + message.time_stamp);

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [IP ADDRESS]: " + message.internet_address + "].");

                            writer.write("[IP ADDRESS]: " + message.internet_address);

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [SOCKET]: " + message.socket + "].");

                            writer.write("[SOCKET]: " + message.socket);

                            writer.flush();
                        }
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
                            if(CommonRail.CommonUtils.socketIsConnected(message.socket))
                            {
                                System.out.println("MessageQueueSorter >> replying with Proxy message ["+line+"].");

                                writer.write(line);

                                writer.flush();
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
                    Thread.sleep(100);
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
        protected ArrayList<Message> messages;

        public MessageQueue(Integer size)
        {
            this.messages = new ArrayList<>();
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

    public void install_network_hooks()
    {
        try
        {
            this.WebExpress_server_socket = new ServerSocket(this.WebExpress_listener_port);

            this.AES2_server_socket = new ServerSocket(this.AES2_listener_port);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }

    public void install_remote_connections()
    {
        try
        {
            for(;;)
            {
                Socket socket = this.WebExpress_server_socket.accept();

                System.out.println("WebExpress >> new connection ["+socket.toString()+"].");

                MessageQueue.Message message = new MessageQueue.Message();

                message.socket = socket;

                message.internet_address = socket.getInetAddress();

                message.time_stamp = new Date(System.currentTimeMillis());

                BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));

                StringBuffer buffer = new StringBuffer();

                String line = null;

                for(;(line=reader.readLine())!=null;)
                {
                    System.out.println("WebExpress::PublicSocket >> reading in input for Proxy ["+line+"].");

                    buffer.append(line);
                }

                message.message_buffer = buffer;

                this.message_queue.add(message);

                Thread.sleep(100);
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
