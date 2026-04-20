import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;

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
            System.out.println("BaseServer::ServerSocket >> created on port "+this.port);
        }
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