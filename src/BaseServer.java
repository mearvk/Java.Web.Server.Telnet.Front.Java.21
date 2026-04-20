import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

public abstract class BaseServer extends Thread
{
    public Integer hash = 0x008808FF;

    public String host = "localhost";

    public InetAddress address;

    public Integer port;

    public ServerSocket server_socket;

    public Boolean running = true;

    protected CurrentConnections current_connections = new CurrentConnections();

    protected PublicListener public_socket_listener;

    protected MessageQueue message_queue = new MessageQueue(this);

    public BaseServer(String host, Integer port)
    {
        if(host==null || port==null) throw new SecurityException("//bodi/connect");

        this.host = host;

        this.port = port;

        this.setName("BasicServer");

        try
        {
            this.address = InetAddress.getByName(host);
        }
        catch(Exception e)
        {
            e.printStackTrace(System.err);

            return;
        }

        try
        {
            this.server_socket = new ServerSocket(this.port, 4096, this.address);
        }
        catch(Exception e)
        {
            e.printStackTrace(System.err);

            return;
        }
        finally
        {
            System.out.println("ServerSocket created on port "+this.port);
        }

        this.public_socket_listener = new PublicListener(this);

        this.public_socket_listener.start();
    }

    public BaseServer(Integer port)
    {
        if(port==null) throw new SecurityException("//bodi/connect");

        this.port = port;

        this.setName("BasicServer");

        try
        {
            this.address = InetAddress.getByName(host);
        }
        catch(Exception e)
        {
            e.printStackTrace(System.err);

            return;
        }

        try
        {
            this.server_socket = new ServerSocket(this.port, 4096, this.address);
        }
        catch(Exception e)
        {
            e.printStackTrace(System.err);

            return;
        }
        finally
        {
            System.out.println("WebExpress::BaseServer >> server created on port ["+this.port+"].");
        }

        this.public_socket_listener = new PublicListener(this);

        this.public_socket_listener.start();
    }

    public static class MessageQueue
    {
        protected List<Message> messages;

        protected BaseServer base_server;

        public MessageQueue(BaseServer base_server)
        {
            this.base_server = base_server;

            this.messages = Collections.synchronizedList(messages = new ArrayList<>(5000));
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

    public synchronized void addMessage(WebExpress.MessageQueue.Message message)
    {
        System.out.println("WebExpress::addMessage >> message queue size before ["+this.getMessageQueueSize()+"].");

        this.message_queue.add(message);

        System.out.println("WebExpress::addMessage >> message queue size after ["+this.getMessageQueueSize()+"].");
    }

    public synchronized WebExpress.MessageQueue getMessageQueue()
    {
        return this.message_queue;
    }

    public synchronized Integer getMessageQueueSize()
    {
        return this.message_queue.messages.size();
    }

    @Override
    public void run()
    {
        try
        {
            while(running)
            {
                Connection connection;

                connection = new Connection(this);

                connection.socket = this.server_socket.accept();

                connection.remote_address = connection.socket.getRemoteSocketAddress().toString();

                System.out.println("WebExpress::BaseServer >> new remote connection established.");

                try
                {
                    connection.inputstream = connection.socket.getInputStream();

                    connection.reader = new BufferedReader(new InputStreamReader(connection.inputstream));
                }
                catch(Exception e)
                {
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    System.out.println("WebExpress::BaseServer >> related input reader established.");
                }

                try
                {
                    connection.outputstream = connection.socket.getOutputStream();

                    connection.writer = new BufferedWriter(new OutputStreamWriter(connection.outputstream));
                }
                catch(Exception e)
                {
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    System.out.println("WebExpress::BaseServer >> related output writer established.");
                }

                try
                {
                    connection.thread = new PublicListener(this.host, this.port);

                    connection.thread.start();
                }
                catch(Exception e)
                {
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    System.out.println("WebExpress::BaseServer >> related I/O listener thread established.");
                }

                this.current_connections.add(connection);
            }
        }
        catch(Exception se)
        {
            se.printStackTrace(System.err);
        }
    }
}