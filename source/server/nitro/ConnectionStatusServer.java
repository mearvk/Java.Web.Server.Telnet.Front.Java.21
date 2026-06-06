package server.nitro;

import commons.CommonRails;
import connections.CurrentConnections;
import exceptions.ExceptionHandler;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * Binds port 49155 and serves a plain-text status report on demand.
 * Any TCP connection to 49155 receives a snapshot of how many clients
 * are currently connected to the main WebExpress port (49152).
 */
public class ConnectionStatusServer extends Thread
{
    public static final int STATUS_PORT = 49155;

    private final CurrentConnections watched;

    private final int watchedPort;

    private final String host;

    private ServerSocket serverSocket;

    public ConnectionStatusServer(String host, CurrentConnections watched, int watchedPort)
    {
        if(host == null || watched == null) throw new SecurityException("//bodi/connect");

        this.host        = host;
        this.watched     = watched;
        this.watchedPort = watchedPort;

        this.setName("ConnectionStatusServer");
        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            InetAddress addr = InetAddress.getByName(host);

            serverSocket = new ServerSocket(STATUS_PORT, 256, addr);

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". ConnectionStatusServer listening on port " + STATUS_PORT + " .");

            while(!Thread.currentThread().isInterrupted())
            {
                Socket client = serverSocket.accept();

                // Handle each status request on a short-lived thread
                Thread responder = new Thread(() -> respond(client));
                responder.setDaemon(true);
                responder.start();
            }
        }
        catch(Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);
        }
    }

    private void respond(Socket client)
    {
        try
        {
            int count = watched.size();

            String report = "Current Connections: " + count + "\n";

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". ConnectionStatusServer >> status query: port=" + watchedPort
                + " connections=" + count + " .");

            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(client.getOutputStream()));

            writer.write(report);
            writer.flush();
        }
        catch(Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
        finally
        {
            try { client.close(); } catch(Exception ignored) {}
        }
    }
}
