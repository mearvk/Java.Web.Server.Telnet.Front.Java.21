package server.base;

import commons.CommonRails;
import connections.*;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;

public abstract class BaseServer extends Thread
{
    public Integer hash = 0x008808FF;

    public BaseServer INHERITOR;
    public static final Integer BASE_CONNECTION_TIMEOUT = 43200 * 2 * 2 * 1000;

    public String HOST = "localhost";

    public InetAddress ADDRESS;

    public Integer PORT;

    public ServerSocket SERVER_SOCKET;

    public Boolean RUNNING = true;

    public CurrentConnections current_connections = new CurrentConnections();

    private final RecordedConnections recorded_connections = new RecordedConnections();

    private final InternationalConnections international_connections = new InternationalConnections();

    public BaseServer()
    {
        System.out.println(this.hash);
    }

    public BaseServer(final String host, Integer PORT)
    {
        if(host==null || PORT ==null) throw new SecurityException("//bodi/connect");

        this.HOST = host;

        this.PORT = PORT;

        this.setName("BasicServer");

        try
        {
            this.ADDRESS = InetAddress.getByName(host);
        }
        catch(Exception e)
        {
            throw new IllegalStateException("Unable to resolve server host "+host, e);
        }

        try
        {
            this.SERVER_SOCKET = new ServerSocket(this.PORT, 4096, this.ADDRESS);

            CommonRails.printSystemComponent(this, this.hashCode(),". BaseServer::ServerSocket created on Port "+this.PORT +" .");
        }
        catch(Exception e)
        {
            throw new IllegalStateException("Unable to create server socket on "+host+":"+this.PORT, e);
        }
    }

    public BaseServer(Integer PORT)
    {
        if(PORT ==null) throw new SecurityException("//bodi/connect");

        this.PORT = PORT;

        this.setName("BasicServer");

        try
        {
            this.ADDRESS = InetAddress.getByName(HOST);
        }
        catch(Exception e)
        {
            throw new IllegalStateException("Unable to resolve server host "+HOST, e);
        }

        try
        {
            this.SERVER_SOCKET = new ServerSocket(this.PORT, 4096, this.ADDRESS);

            CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress::BaseServer] [Server created on Port ["+this.PORT +"]]");
        }
        catch(Exception e)
        {
            throw new IllegalStateException("Unable to create server socket on "+HOST+":"+this.PORT, e);
        }
    }

    @Override
    public void run()
    {
        try
        {
            while(RUNNING)
            {
                Connection connection;

                connection = new Connection(this);

                connection.socket = this.SERVER_SOCKET.accept();

                connection.socket.setSoTimeout(BaseServer.BASE_CONNECTION_TIMEOUT);

                connection.remote_address = connection.socket.getRemoteSocketAddress().toString();

                connection.internet_address = connection.socket.getInetAddress();

                connection.server = this;

                CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress::BaseServer] [New remote connection established [remote-ephemeral: "+connection.remote_address+" : local: "+this.PORT +"]]");

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
                    CommonRails.printSystemComponent(this, this.hashCode(),"[WebExpress::BaseServer] [Related input reader established ["+this.ADDRESS +":"+this.PORT +"]]");
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
                    CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress::BaseServer] [Related output writer established ["+this.ADDRESS +":"+this.PORT +"]]");
                }

                try
                {
                    connection.thread = new ConnectionPoller(null,this, this.HOST, this.PORT);

                    connection.thread.start();
                }
                catch(Exception e)
                {
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress::BaseServer] [Related I/O listener thread established ["+this.ADDRESS +":"+this.PORT +"]]");
                }

                this.current_connections.add(connection);

                this.recorded_connections.add(connection);

                this.international_connections.add(connection);
            }
        }
        catch(Exception se)
        {
            se.printStackTrace(System.err);
        }
    }
}
