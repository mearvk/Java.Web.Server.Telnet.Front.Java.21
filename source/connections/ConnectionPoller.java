package connections;

import commons.CommonRails;
import commons.EnglishArithemeter;
import exceptions.ExceptionHandler;
import messaging.MessageQueue;
import server.base.BaseServer;
import server.nitro.WebExpress;
import telnet.TelnetMessageQueue;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
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

    /** Timeout (ms) for reading client request and telnet backend response per session. */
    protected static final int PROXY_READ_TIMEOUT_MS = 5000;

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

    @Override
    public void run()
    {
        MessageQueue.Message MESSAGE = new MessageQueue.Message();

        Connection CONNECTION = null;

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
                            + "] total CONNECTION count ["
                            + arithemeter.result.arithemetic + " : " + arithemeter.result.numeral + "].");

                        TelnetMessageQueue.Message TELNET_MESSAGE = new TelnetMessageQueue.Message();

                        TELNET_MESSAGE.PORT      = Integer.parseInt(WebExpress.REMOTE_PORT);
                        TELNET_MESSAGE.SOCKET    = this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.socket;
                        TELNET_MESSAGE.TIMESTAMP = new Date();
                        TELNET_MESSAGE.MESSAGE_BUFFER = new StringBuffer("US6");

                        this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.OUTPUT_BUILDER.TELNET_MESSAGE_QUEUE.add(TELNET_MESSAGE);

                        CONNECTION.IS_TELNET_EXCELSIOR_CONNECTED = Boolean.TRUE;
                    }

                    // Assign MESSAGE fields from current CONNECTION before any guard
                    MESSAGE.CONNECTION       = CONNECTION;
                    MESSAGE.SOCKET           = CONNECTION.SOCKET;
                    MESSAGE.INTERNET_ADDRESS = CONNECTION.SOCKET.getInetAddress();
                    MESSAGE.TIME_STAMP       = new Date(System.currentTimeMillis());

                    if(CommonRails.SocketUtils.isSocketConnected(CONNECTION.SOCKET))
                    {
                        MESSAGE.MESSAGE_BUFFER = new StringBuffer("US22.09");

                        StringBuilder BUFFER = new StringBuilder();

                        // ── 1. Read the client request with a bounded timeout ──────────────
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
                                        "WebExpress ConnectionPoller >> reading input ["
                                        + MESSAGE.SOCKET + "] line [" + LINE + "].");

                                    BUFFER.append(LINE).append(LINE_FEED);
                                }
                            }
                        }
                        catch(SocketTimeoutException clientReadDone)
                        {
                            // read window expired — proceed with what arrived
                        }
                        finally
                        {
                            CONNECTION.SOCKET.setSoTimeout(READ_WRITE_STANDARD_SOCKET_TIMEOUT);
                        }

                        MESSAGE.MESSAGE_BUFFER = new StringBuffer(BUFFER);

                        // ── 2. Forward request and write response directly back to client ──
                        try
                        {
                            if(BUFFER.length() > 0)
                            {
                                // Spawn a dedicated telnet subprocess per session so concurrent
                                // clients each get their own independent backend connection.
                                ProcessBuilder PER_PB = new ProcessBuilder(WebExpress.TELNET_PROXY_SERVER_ARGS);

                                Process PER_PROC = PER_PB.start();

                                try
                                {
                                    // Send request bytes to the per-session telnet process
                                    java.io.OutputStream PER_OUT = PER_PROC.getOutputStream();
                                    byte[] REQUEST_BYTES = BUFFER.toString().getBytes();
                                    PER_OUT.write(REQUEST_BYTES);
                                    PER_OUT.write('\n');
                                    PER_OUT.flush();

                                    CommonRails.printSystemComponent(this, this.hashCode(),
                                        "WebExpress ConnectionPoller >> forwarded ["
                                        + REQUEST_BYTES.length + " bytes] to per-session telnet backend.");

                                    // Blocking byte-copy with wall-clock timeout using a reader thread.
                                    // available() can't be used here — the telnet process needs time
                                    // to resolve DNS and establish the remote connection.
                                    java.io.InputStream  PER_IN     = PER_PROC.getInputStream();
                                    java.io.OutputStream CLIENT_OUT = CONNECTION.SOCKET.getOutputStream();

                                    java.util.concurrent.atomic.AtomicLong LAST_READ =
                                        new java.util.concurrent.atomic.AtomicLong(System.currentTimeMillis());

                                    java.util.concurrent.ExecutorService READER_EXEC =
                                        java.util.concurrent.Executors.newSingleThreadExecutor();

                                    java.util.concurrent.Future<?> READER_FUTURE = READER_EXEC.submit(() ->
                                    {
                                        byte[] CHUNK = new byte[4096];
                                        int    READ;
                                        try
                                        {
                                            while ((READ = PER_IN.read(CHUNK)) != -1)
                                            {
                                                CLIENT_OUT.write(CHUNK, 0, READ);
                                                CLIENT_OUT.flush();
                                                LAST_READ.set(System.currentTimeMillis());

                                                CommonRails.printSystemComponent(this, this.hashCode(),
                                                    "WebExpress ConnectionPoller >> proxied ["
                                                    + READ + " bytes] to client.");
                                            }
                                        }
                                        catch (Exception ignored) {}
                                    });

                                    // Wait up to PROXY_READ_TIMEOUT_MS of idle silence after last read
                                    long WALL = System.currentTimeMillis() + 15_000L;

                                    while (System.currentTimeMillis() < WALL)
                                    {
                                        if (READER_FUTURE.isDone()) break;

                                        if (System.currentTimeMillis() - LAST_READ.get() > PROXY_READ_TIMEOUT_MS)
                                            break;

                                        Thread.sleep(100);
                                    }

                                    READER_FUTURE.cancel(true);
                                    READER_EXEC.shutdownNow();

                                    CommonRails.printSystemComponent(this, this.hashCode(),
                                        "WebExpress ConnectionPoller >> per-session proxy read window closed.");
                                }
                                finally
                                {
                                    try { PER_PROC.destroyForcibly(); } catch(Exception ignored) {}
                                }
                            }

                            this.WEBEXPRESS.MESSAGE_QUEUE.add(MESSAGE);
                        }
                        catch(SocketTimeoutException ste)
                        {
                            this.WEBEXPRESS.MESSAGE_QUEUE.add(MESSAGE);

                            CONNECTIONS.remove(CONNECTION);

                            CommonRails.printSystemComponent(this, this.hashCode(),
                                "WebExpress ConnectionPoller >> graceful disconnect ["
                                + MESSAGE.SOCKET.getRemoteSocketAddress() + "] ["
                                + ste.getMessage() + "] total count [" + CONNECTIONS.size() + "].");
                        }
                        catch(Exception e)
                        {
                            ExceptionHandler.dispatch(e);

                            CONNECTIONS.remove(CONNECTION);

                            CommonRails.printSystemComponent(this, this.hashCode(),
                                "WebExpress ConnectionPoller >> socket exception [" + e.getMessage() + "].");
                        }
                        finally
                        {
                            for(int k = 0; k < CURRENT_CONNECTIONS.size(); k++)
                            {
                                Connection LATENT = CURRENT_CONNECTIONS.CURRENT_CONNECTION.get(k);

                                if(CommonRails.SocketUtils.isSocketClosed(LATENT.SOCKET))
                                {
                                    CURRENT_CONNECTIONS.remove(LATENT);

                                    CommonRails.printSystemComponent(this, this.hashCode(),
                                        "WebExpress ConnectionPoller >> closed sleeping turtle ["
                                        + LATENT.SOCKET + "].");
                                }
                            }

                            if(CommonRails.SocketUtils.isSocketConnected(MESSAGE.SOCKET))
                            {
                                MESSAGE.SOCKET.setSoTimeout(READ_WRITE_STANDARD_SOCKET_TIMEOUT);
                            }
                        }
                    }
                    else
                    {
                        try
                        {
                            if(CONNECTION.SOCKET != null)
                            {
                                CONNECTION.SOCKET.close();
                            }
                        }
                        catch(Exception e)
                        {
                            ExceptionHandler.dispatch(e);

                            CommonRails.printSystemComponent(this, this.hashCode(),
                                "WebExpress ConnectionPoller >> closed CONNECTION close.");
                        }
                    }
                }
            }
            catch(SocketTimeoutException ste)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    "WebExpress ConnectionPoller >> closing socket due to timeout [" + MESSAGE.SOCKET + "].");

                CURRENT_CONNECTIONS.remove(CONNECTION);

                if(MESSAGE.MESSAGE_BUFFER.length() > 0)
                {
                    this.WEBEXPRESS.MESSAGE_QUEUE.add(MESSAGE);
                }

                CommonRails.printSystemComponent(this, this.hashCode(),
                    "WebExpress ConnectionPoller >> new CONNECTION count [" + CURRENT_CONNECTIONS.size() + "].");

                try
                {
                    if(CONNECTION != null && CONNECTION.SOCKET != null)
                    {
                        CONNECTION.SOCKET.close();
                    }
                }
                catch(Exception e)
                {
                    ExceptionHandler.dispatch(e);

                    CommonRails.printSystemComponent(this, this.hashCode(),
                        "WebExpress ConnectionPoller >> closed CONNECTION close.");
                }
            }
            catch(Exception e)
            {
                ExceptionHandler.dispatch(e);

                e.printStackTrace(System.err);
            }
            finally
            {
                try
                {
                    Thread.sleep(1500);
                }
                catch(Exception e)
                {
                    ExceptionHandler.dispatch(e);

                    CommonRails.printSystemComponent(this, this.hashCode(),
                        "WebExpress ConnectionPoller >> closed CONNECTION on main polling thread sleep.");
                }
            }
        }
    }
}
