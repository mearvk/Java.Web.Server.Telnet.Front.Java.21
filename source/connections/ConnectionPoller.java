package connections;

import commons.CommonRails;
import commons.EnglishArithemeter;
import exceptions.ExceptionHandler;
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

    protected static final int PROXY_READ_TIMEOUT_MS  = 5000;
    protected static final int PROXY_WALL_TIMEOUT_MS  = 20_000;

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

    // ── Per-connection session handler ────────────────────────────────────────

    private void handleSession(Connection CONNECTION, CurrentConnections CONNECTIONS)
    {
        try
        {
            if(!CommonRails.SocketUtils.isSocketConnected(CONNECTION.SOCKET)) return;

            // 1. Read client request with bounded timeout
            StringBuilder BUFFER = new StringBuilder();

            try
            {
                CONNECTION.SOCKET.setSoTimeout(PROXY_READ_TIMEOUT_MS);

                BufferedReader READER = new BufferedReader(
                    new InputStreamReader(CONNECTION.SOCKET.getInputStream()));

                String LINE;

                if((LINE = READER.readLine()) != null)
                {
                    BUFFER.append(LINE).append(LINE_FEED);

                    while((LINE = READER.readLine()) != null)
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),
                            "WebExpress SessionHandler >> read line [" + LINE + "].");

                        BUFFER.append(LINE).append(LINE_FEED);
                    }
                }
            }
            catch(SocketTimeoutException clientReadDone)
            {
                // window closed — proceed with what arrived
            }
            finally
            {
                CONNECTION.SOCKET.setSoTimeout(READ_WRITE_STANDARD_SOCKET_TIMEOUT);
            }

            if(BUFFER.length() == 0) return;

            // 2. Send a sample HTTP GET to tacobell.phd:80 and stream the reply back to the client
            try(java.net.Socket proxy = new java.net.Socket())
            {
                proxy.connect(new java.net.InetSocketAddress(WebExpress.REMOTE_SITE, Integer.parseInt(WebExpress.REMOTE_PORT)), PROXY_READ_TIMEOUT_MS);
                proxy.setSoTimeout(PROXY_READ_TIMEOUT_MS);

                java.io.OutputStream proxyOut = proxy.getOutputStream();
                String httpRequest = "GET / HTTP/1.0\r\nHost: " + WebExpress.REMOTE_SITE + "\r\nConnection: close\r\n\r\n";
                proxyOut.write(httpRequest.getBytes());
                proxyOut.flush();

                CommonRails.printSystemComponent(this, this.hashCode(),
                    "WebExpress SessionHandler >> forwarded HTTP GET to " + WebExpress.REMOTE_SITE + ":" + WebExpress.REMOTE_PORT + ".");

                java.io.OutputStream clientOut = CONNECTION.SOCKET.getOutputStream();
                byte[] chunk = new byte[4096];
                int read;
                long deadline = System.currentTimeMillis() + PROXY_WALL_TIMEOUT_MS;

                while(System.currentTimeMillis() < deadline && (read = proxy.getInputStream().read(chunk)) != -1)
                {
                    clientOut.write(chunk, 0, read);
                    clientOut.flush();

                    CommonRails.printSystemComponent(this, this.hashCode(),
                        "WebExpress SessionHandler >> proxied [" + read + " bytes] to client.");
                }
            }

            // Enqueue for MessageQueueSorter audit trail
            MessageQueue.Message MSG = new MessageQueue.Message();
            MSG.CONNECTION       = CONNECTION;
            MSG.SOCKET           = CONNECTION.SOCKET;
            MSG.INTERNET_ADDRESS = CONNECTION.SOCKET.getInetAddress();
            MSG.TIME_STAMP       = new Date();
            MSG.MESSAGE_BUFFER   = new StringBuffer(BUFFER);

            this.WEBEXPRESS.MESSAGE_QUEUE.add(MSG);
        }
        catch(Exception e)
        {
            ExceptionHandler.dispatch(e);

            CommonRails.printSystemComponent(this, this.hashCode(),
                "WebExpress SessionHandler >> exception [" + e.getMessage() + "].");
        }
        // Do NOT remove from CONNECTIONS here — BaseServer.run() cleans up on socket close
    }

    // ── Poller loop: accepts new connections, marks them, spawns handler ──────

    @Override
    public void run()
    {
        Connection         CONNECTION         = null;
        CurrentConnections CURRENT_CONNECTIONS = null;

        while(true)
        {
            try
            {
                CURRENT_CONNECTIONS = this.BASESERVER.CURRENT_CONNECTIONS;

                for(int i = 0; i < CURRENT_CONNECTIONS.size(); i++)
                {
                    if(this.WEBEXPRESS == null || this.WEBEXPRESS.CURRENT_CONNECTIONS == null)
                        throw new SecurityException("//bodi/exceptions");

                    CurrentConnections CONNECTIONS = this.WEBEXPRESS.CURRENT_CONNECTIONS;

                    CONNECTION = CURRENT_CONNECTIONS.CURRENT_CONNECTION.get(i);

                    if(!CONNECTION.IS_TELNET_EXCELSIOR_CONNECTED)
                    {
                        EnglishArithemeter arithemeter = new EnglishArithemeter(CONNECTIONS.size());

                        CommonRails.printSystemComponent(this, this.hashCode(),
                            "WebExpress ConnectionPoller >> new CONNECTION from ["
                            + CONNECTION.SOCKET.getRemoteSocketAddress()
                            + "] total count ["
                            + arithemeter.result.arithemetic + " : " + arithemeter.result.numeral + "].");

                        TelnetMessageQueue.Message TELNET_MSG = new TelnetMessageQueue.Message();
                        TELNET_MSG.PORT           = Integer.parseInt(WebExpress.REMOTE_PORT);
                        TELNET_MSG.SOCKET         = this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.socket;
                        TELNET_MSG.TIMESTAMP      = new Date();
                        TELNET_MSG.MESSAGE_BUFFER = new StringBuffer("US6");

                        this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.OUTPUT_BUILDER
                            .TELNET_MESSAGE_QUEUE.add(TELNET_MSG);

                        CONNECTION.IS_TELNET_EXCELSIOR_CONNECTED = Boolean.TRUE;

                        // Spawn a dedicated handler thread so all sessions run in parallel
                        final Connection         CONN_F  = CONNECTION;
                        final CurrentConnections CONNS_F = CONNECTIONS;

                        Thread H = new Thread(() -> handleSession(CONN_F, CONNS_F));
                        H.setName("SessionHandler-" + CONNECTION.SOCKET.getRemoteSocketAddress());
                        H.setDaemon(true);
                        H.start();
                    }

                    // Clean up closed sockets
                    if(CommonRails.SocketUtils.isSocketClosed(CONNECTION.SOCKET))
                    {
                        CONNECTIONS.remove(CONNECTION);

                        CommonRails.printSystemComponent(this, this.hashCode(),
                            ". WebExpress ConnectionPoller >> client disconnected ["
                            + CONNECTION.SOCKET.getRemoteSocketAddress()
                            + "] active connections now [" + CONNECTIONS.size() + "] .");
                    }
                }
            }
            catch(Exception e)
            {
                ExceptionHandler.dispatch(e);

                if(CURRENT_CONNECTIONS != null)
                {
                    CURRENT_CONNECTIONS.remove(CONNECTION);

                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". WebExpress ConnectionPoller >> client disconnected on exception ["
                        + (CONNECTION != null && CONNECTION.SOCKET != null ? CONNECTION.SOCKET.getRemoteSocketAddress() : "unknown")
                        + "] active connections now [" + CURRENT_CONNECTIONS.size() + "] .");
                }

                try
                {
                    if(CONNECTION != null && CONNECTION.SOCKET != null)
                        CONNECTION.SOCKET.close();
                }
                catch(Exception ignored) {}

                e.printStackTrace(System.err);
            }
            finally
            {
                try
                {
                    Thread.sleep(500);
                }
                catch(Exception e)
                {
                    ExceptionHandler.dispatch(e);
                }
            }
        }
    }
}
