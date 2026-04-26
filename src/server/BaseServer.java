package server;

import commons.CommonRails;
import connections.Connection;
import connections.ConnectionPoller;
import connections.CurrentConnections;
import connections.RecordedConnections;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;

public abstract class BaseServer extends Thread
{
    public Integer hash = 0x008808FF;

    protected WebExpress reference = WebExpress.reference;

    public String host = "localhost";

    public InetAddress address;

    public Integer port;

    public ServerSocket server_socket;

    public Boolean running = true;

    public CurrentConnections current_connections = new CurrentConnections();

    private RecordedConnections recorded_connections = new RecordedConnections();

    public BaseServer()
    {
        System.out.println(this.hash);
    }

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
            CommonRails.printSystemComponent(this.hashCode(),"BaseServer::ServerSocket >> created on port ["+this.port+"]");
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
            CommonRails.printSystemComponent(this.hashCode(), "WebExpress::BaseServer >> server created on port ["+this.port+"].");
        }
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

                connection.socket.setSoTimeout(42300*4*1000); //43200 seconds is 12 hours ~ half a day : is now 2 Days days.

                connection.remote_address = connection.socket.getRemoteSocketAddress().toString();

                connection.internet_address = connection.socket.getInetAddress();

                connection.server = this;

                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::BaseServer >> new remote connection established [remote-ephemeral: "+connection.remote_address+" : local: "+this.port+"].");

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
                    CommonRails.printSystemComponent(this.hashCode(),"WebExpress::BaseServer >> [related input] reader established ["+this.address+":"+this.port+"].");
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
                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::BaseServer >> [related output] writer established ["+this.address+":"+this.port+"].");
                }

                try
                {
                    connection.thread = new ConnectionPoller(WebExpress.reference,this, this.host, this.port);

                    connection.thread.start();
                }
                catch(Exception e)
                {
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::BaseServer >> [related I/O listener] thread established ["+this.address+":"+this.port+"].");
                }

                this.current_connections.add(connection);

                this.recorded_connections.add(connection);
            }
        }
        catch(Exception se)
        {
            se.printStackTrace(System.err);
        }
    }
}