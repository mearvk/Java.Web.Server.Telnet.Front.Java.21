/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package telnet;

import commons.CommonRails;
import server.nitro.WebExpress;
//import sim.stochastic;

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

    public TelnetProxyCommunicator telnet_proxy_communicator;

    public TelnetOutputBuilder output_builder;

    public TelnetInputBuilder input_builder;

    public TelnetCommunicationProxy(WebExpress WEB_EXPRESS)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress Telnet Communicator starts .");

        this.WEB_EXPRESS = WEB_EXPRESS;

        this.process_builder = this.WEB_EXPRESS.TELNET_INSTALLER.process_builder;

        this.process = this.WEB_EXPRESS.TELNET_INSTALLER.process;

        this.writer = this.WEB_EXPRESS.TELNET_INSTALLER.writer;

        this.reader = this.WEB_EXPRESS.TELNET_INSTALLER.reader;

        this.telnet_proxy_communicator = new TelnetProxyCommunicator(this);

        this.output_builder = new TelnetOutputBuilder(this);

        this.input_builder = new TelnetInputBuilder(this);

        this.output_builder.start();

        this.input_builder.start();
    }

    public static class TelnetProxyCommunicator extends Thread
    {
        protected TelnetCommunicationProxy telnet_communication_proxy;

        public TelnetProxyCommunicator(TelnetCommunicationProxy telnet_communication_proxy)
        {
            this.telnet_communication_proxy = telnet_communication_proxy;
        }

        @Override
        public void run()
        {
            for(;;)
            {
                StringBuffer buffer = null;

                final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                try
                {
                    String line = proxy.reader.readLine();

                    if(line != null)
                    {
                        TelnetMessageQueue.Message message = new TelnetMessageQueue.Message();

                        // collect first line and subsequent available lines
                        message.message_buffer.append(line);

                        while ((line = proxy.reader.readLine()) != null)
                        {
                            message.message_buffer.append('\n').append(line);
                        }

                        // keep a reference to buffer for optional outbound use
                        buffer = message.message_buffer;

                        // enqueue received data for input processing
                        proxy.input_builder.telnet_message_queue.add(message);
                    }
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }

                // If we have data (buffer), create an outbound message for the output queue
                if (buffer != null)
                {
                    try
                    {
                        TelnetMessageQueue.Message outMsg = new TelnetMessageQueue.Message();

                        outMsg.port = Integer.valueOf(WebExpress.REMOTE_PORT);

                        outMsg.protocol = WebExpress.PROTOCOL;

                        outMsg.socket = proxy.socket;

                        outMsg.message_buffer = buffer;

                        outMsg.time_stamp = new Date();

                        outMsg.internet_address = InetAddress.getByName(WebExpress.REMOTE_SITE);

                        this.telnet_communication_proxy.output_builder.telnet_message_queue.add(outMsg);
                    }
                    catch (Exception e)
                    {
                        e.printStackTrace(System.err);
                    }
                    finally
                    {
                        // check the actual socket if available
                        try {
                            CommonRails.SocketUtils.isSocketConnected(this.telnet_communication_proxy.socket);
                        } catch (Exception ignored) {
                        }
                    }
                }

                try { Thread.sleep(100); } catch (Exception e) { /* throttle loop a bit */ }
            }
        }
    }

    //protected stochastic _process_builder;

    //protected stochastic _process;

    //protected stochastic _writer;

    //protected stochastic _reader;
}