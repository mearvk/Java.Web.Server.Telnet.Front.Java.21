package server.base;

import commons.CommonRails;
import connections.*;
import exceptions.ExceptionHandler;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;

public abstract class BaseServer extends Thread
{
    public Integer HASH = 0x008808FF;

    public BaseServer SUPERCLASS;

    public BaseServer SELF;
    public static final Integer BASE_CONNECTION_TIMEOUT = 43200 * 2 * 2 * 1000;

    public String HOST = "localhost";

    public InetAddress ADDRESS;

    public Integer PORT;

    public ServerSocket SERVER_SOCKET;

    public Boolean RUNNING = true;


    public CurrentConnections CURRENT_CONNECTIONS = new CurrentConnections();

    private final RecordedConnections RECORDED_CONNECTIONS = new RecordedConnections();

    private final InternationalConnections INTERNATIONAL_CONNECTIONS = new InternationalConnections();

    public BaseServer()
    {
        System.out.println(this.HASH);
    }

    public BaseServer(String host, Integer PORT)
    {
        if(host==null || PORT ==null) throw new SecurityException("//bodi/connect");

        this.HOST = host;

        this.PORT = PORT;

        this.SUPERCLASS = this;

        this.SELF = this;

        this.setName("BasicServer");

        try
        {
            this.ADDRESS = InetAddress.getByName(host);
        }
        catch(Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);

            this.RUNNING = false;

            return;
        }

        try
        {
            this.SERVER_SOCKET = new ServerSocket(this.PORT, 4096, this.ADDRESS);
        }
        catch(Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);

            // mark as not running so run() will not attempt accept on a null socket
            this.RUNNING = false;

            return;
        }
        finally
        {
            CommonRails.printSystemComponent(this, this.hashCode(),". BaseServer ServerSocket created on Port "+this.PORT +" .");
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
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);

            this.RUNNING = false;

            return;
        }

        try
        {
            this.SERVER_SOCKET = new ServerSocket(this.PORT, 4096, this.ADDRESS);
        }
        catch(Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);

            this.RUNNING = false;

            return;
        }
        finally
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress BaseServer] [Server created on Port ["+this.PORT+"]]" );
        }
    }

    @Override
    public void run()
    {
        try
        {
            // Defensive: if server socket failed to initialize the constructor set RUNNING=false;
            if (this.SERVER_SOCKET == null)
            {
                CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress BaseServer] [SERVER_SOCKET is null; server not started]");

                return;
            }

            while(RUNNING)
            {
                Connection connection;

                connection = new Connection(this);

                connection.SOCKET = this.SERVER_SOCKET.accept();

                connection.SOCKET.setSoTimeout(BaseServer.BASE_CONNECTION_TIMEOUT);

                connection.remote_address = connection.SOCKET.getRemoteSocketAddress().toString();

                connection.internet_address = connection.SOCKET.getInetAddress();

                connection.server = this;

                CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress BaseServer] [New remote connection established [remote-ephemeral: "+connection.remote_address+" : local: "+this.PORT +"]]");

                try
                {
                    connection.inputstream = connection.SOCKET.getInputStream();

                    connection.reader = new BufferedReader(new InputStreamReader(connection.inputstream));
                }
                catch(Exception e)
                {
                    ExceptionHandler.dispatch(e);
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),"[WebExpress BaseServer] [Related input reader established ["+this.ADDRESS +":"+this.PORT +"]]");
                }

                try
                {
                    connection.outputstream = connection.SOCKET.getOutputStream();

                    connection.writer = new BufferedWriter(new OutputStreamWriter(connection.outputstream));
                }
                catch(Exception e)
                {
                    ExceptionHandler.dispatch(e);
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress BaseServer] [Related output writer established ["+this.ADDRESS +":"+this.PORT +"]]");
                }

                try
                {
                    connection.thread = new ConnectionPoller(this, this.HOST, this.PORT);

                    connection.thread.start();
                }
                catch(Exception e)
                {
                    ExceptionHandler.dispatch(e);
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress BaseServer] [Related I/O listener thread established ["+this.ADDRESS +":"+this.PORT +"]]");
                }

                this.CURRENT_CONNECTIONS.add(connection);

                this.RECORDED_CONNECTIONS.add(connection);

                this.INTERNATIONAL_CONNECTIONS.add(connection);

                db.N21Store.storeConnection(connection, this.PORT);
            }
        }
        catch(Exception se)
        {
            ExceptionHandler.dispatch(se);
            se.printStackTrace(System.err);
        }
    }
}