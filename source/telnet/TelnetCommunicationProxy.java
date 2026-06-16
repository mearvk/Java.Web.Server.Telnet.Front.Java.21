package telnet;

import commons.CommonRails;
import exceptions.ExceptionHandler;
import server.webexpress.WebExpress;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.net.InetAddress;
import java.net.Socket;

public class TelnetCommunicationProxy
{
    protected WebExpress WEB_EXPRESS;

    protected ProcessBuilder process_builder = new ProcessBuilder();

    public Process process;

    public Socket socket;

    public BufferedWriter writer;

    public BufferedReader reader;

    public TelnetProxyCommunicator TELNET_COMMUNICATION_PROXY;

    public TelnetOutputBuilder OUTPUT_BUILDER;

    public TelnetInputBuilder INPUT_BUILDER;

    public TelnetProxyLivenessMonitor liveness_monitor;

    public TelnetCommunicationProxy(final WebExpress WEB_EXPRESS)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress Telnet Communicator starts .");

        this.WEB_EXPRESS = WEB_EXPRESS;

        this.process_builder = this.WEB_EXPRESS.TELNET_INSTALLER.process_builder;

        this.process = this.WEB_EXPRESS.TELNET_INSTALLER.process;

        this.writer = this.WEB_EXPRESS.TELNET_INSTALLER.writer;

        this.reader = this.WEB_EXPRESS.TELNET_INSTALLER.reader;

        this.TELNET_COMMUNICATION_PROXY = new TelnetProxyCommunicator(this);

        this.OUTPUT_BUILDER = new TelnetOutputBuilder(this);

        this.INPUT_BUILDER = new TelnetInputBuilder(this);

        this.OUTPUT_BUILDER.start();

        this.INPUT_BUILDER.start();

        this.liveness_monitor = new TelnetProxyLivenessMonitor(this);

        this.liveness_monitor.start();
    }

    /** Returns true when the backing process is alive and the writer pipe is open. */
    public boolean isProxyAlive()
    {
        if (this.process == null || !this.process.isAlive()) return false;
        return this.writer != null;
    }

    public static class TelnetProxyCommunicator extends Thread
    {
        protected TelnetCommunicationProxy TELNET_COMMUNICATION_PROXY;

        public TelnetProxyCommunicator(final TelnetCommunicationProxy TELNET_COMMUNICATION_PROXY)
        {
            this.TELNET_COMMUNICATION_PROXY = TELNET_COMMUNICATION_PROXY;
        }

        @Override
        public void run()
        {
            for(;;)
            {
                try
                {
                    final TelnetCommunicationProxy proxy = this.TELNET_COMMUNICATION_PROXY;

                    // ── Inbound: read one full response from the remote process ──
                    // readLine() blocks until a line arrives or the stream closes.
                    String line = proxy.reader.readLine();

                    if (line == null)
                    {
                        // Stream closed — back off and let the liveness monitor reconnect
                        CommonRails.printSystemComponent(this, this.hashCode(),
                            ". TelnetProxyCommunicator >> remote stream closed, waiting for reconnect .");
                        Thread.sleep(2000);
                        continue;
                    }

                    TelnetMessageQueue.Message inbound = new TelnetMessageQueue.Message();
                    inbound.MESSAGE_BUFFER.append(line);

                    // Drain any additional lines available without blocking indefinitely
                    proxy.reader.mark(1);
                    while (proxy.reader.ready() && (line = proxy.reader.readLine()) != null)
                    {
                        inbound.MESSAGE_BUFFER.append('\n').append(line);
                        proxy.reader.mark(1);
                    }

                    proxy.INPUT_BUILDER.telnet_message_queue.add(inbound);

                    // ── Outbound: re-enqueue a status ping so OUTPUT_BUILDER stays active ──
                    TelnetMessageQueue.Message outbound = new TelnetMessageQueue.Message();
                    outbound.PORT             = Integer.valueOf(WebExpress.REMOTE_PORT);
                    outbound.protocol         = WebExpress.PROTOCOL;
                    outbound.SOCKET           = null;
                    outbound.MESSAGE_BUFFER   = new StringBuffer(); // empty — OUTPUT_BUILDER skips empties
                    outbound.TIMESTAMP        = new java.util.Date();
                    outbound.internet_address = InetAddress.getByName(WebExpress.REMOTE_SITE);

                    this.TELNET_COMMUNICATION_PROXY.OUTPUT_BUILDER.TELNET_MESSAGE_QUEUE.add(outbound);
                }
                catch (InterruptedException ie)
                {
                    Thread.currentThread().interrupt();
                    return;
                }
                catch (Exception e)
                {
                    ExceptionHandler.dispatch(e);
                }
            }
        }
    }

    //protected stochastic _process_builder;

    //protected stochastic _process;

    //protected stochastic _writer;

    //protected stochastic _reader;
}