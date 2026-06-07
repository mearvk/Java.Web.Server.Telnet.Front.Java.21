package telnet;

import commons.CommonRails;
import exceptions.ExceptionHandler;
import server.nitro.WebExpress;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.util.Date;

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

    public TelnetInputBuilder input_builder;

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

        this.input_builder = new TelnetInputBuilder(this);

        this.OUTPUT_BUILDER.start();

        this.input_builder.start();

        this.liveness_monitor = new TelnetProxyLivenessMonitor(this);

        this.liveness_monitor.start();
    }

    /** Returns true when the backing process is alive and the writer pipe is open. */
    public boolean isProxyAlive()
    {
        try
        {
            if (this.process == null || !this.process.isAlive()) return false;

            if (this.writer != null) this.writer.flush();

            return true;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return false;
        }
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
                StringBuffer buffer;

                try
                {
                    TelnetMessageQueue.Message message = new TelnetMessageQueue.Message();

                    final TelnetCommunicationProxy proxy = this.TELNET_COMMUNICATION_PROXY;

                    String line = proxy.reader.readLine();

                    if(line!=null)
                    {
                        message.MESSAGE_BUFFER.append(line);

                        while ( (line=proxy.reader.readLine()) !=null)
                        {
                            message.MESSAGE_BUFFER.append(line);
                        }

                        proxy.input_builder.telnet_message_queue.add(message);
                    }
                }
                catch (Exception e)
                {
                    ExceptionHandler.dispatch(e);
                    e.printStackTrace(System.err);
                }
                finally
                {
                    buffer = null;
                }

                try
                {
                    TelnetMessageQueue.Message message = new TelnetMessageQueue.Message();

                    message.PORT = Integer.valueOf(WebExpress.REMOTE_PORT);

                    message.protocol = WebExpress.PROTOCOL;

                    message.SOCKET = null;

                    message.MESSAGE_BUFFER = buffer;

                    message.TIMESTAMP = new Date();

                    message.internet_address = InetAddress.getByName(WebExpress.REMOTE_SITE);

                    this.TELNET_COMMUNICATION_PROXY.OUTPUT_BUILDER.TELNET_MESSAGE_QUEUE.add(message);
                }
                catch (Exception e)
                {
                    ExceptionHandler.dispatch(e);
                    e.printStackTrace(System.err);
                }
                finally
                {
                    CommonRails.SocketUtils.isSocketConnected(null);
                }
            }
        }
    }

    //protected stochastic _process_builder;

    //protected stochastic _process;

    //protected stochastic _writer;

    //protected stochastic _reader;
}