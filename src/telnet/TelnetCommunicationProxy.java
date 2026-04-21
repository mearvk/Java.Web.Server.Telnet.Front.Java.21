package telnet;

import commons.CommonRails;
import server.WebExpress;
import sim.stochastic;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.util.Date;

public class TelnetCommunicationProxy
{
    protected WebExpress web_express;

    protected ProcessBuilder process_builder = new ProcessBuilder();

    public Process process;

    public Socket socket;

    public BufferedWriter writer;

    public BufferedReader reader;

    protected TelnetProxyCommunicator telnet_proxy_communicator;

    protected TelnetOutputBuilder output_builder;

    protected TelnetInputBuilder input_builder;

    public TelnetCommunicationProxy(WebExpress web_express)
    {
        System.out.println("[Object ID: "+this.hashCode()+"] server.WebExpress::Telnet::Communicator >> starts ["+new Date()+"].");

        this.web_express = web_express;

        this.process_builder = this.web_express.telnet_installer.process_builder;

        this.process = this.web_express.telnet_installer.process;

        this.writer = this.web_express.telnet_installer.writer;

        this.reader = this.web_express.telnet_installer.reader;

        this.telnet_proxy_communicator = this.web_express.telnet_communication_proxy.telnet_proxy_communicator;

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
                StringBuffer buffer;

                try
                {
                    TelnetMessageQueue.Message message = new TelnetMessageQueue.Message();

                    final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                    String line = proxy.reader.readLine();

                    if(line!=null)
                    {
                        message.message_buffer.append(line);

                        while ( (line=proxy.reader.readLine()) !=null)
                        {
                            message.message_buffer.append(line);
                        }

                        proxy.input_builder.telnet_message_queue.add(message);
                    }
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }
                finally
                {
                    buffer = null;
                }

                try
                {
                    TelnetMessageQueue.Message message = new TelnetMessageQueue.Message();

                    message.port = Integer.valueOf(WebExpress.REMOTE_PORT);

                    message.protocol = WebExpress.PROTOCOL;

                    message.socket = null;

                    message.message_buffer = buffer;

                    message.time_stamp = new Date();

                    message.internet_address = InetAddress.getByName(WebExpress.REMOTE_SITE);

                    this.telnet_communication_proxy.output_builder.telnet_message_queue.add(message);
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }
                finally
                {
                    CommonRails.SocketUtils.isSocketConnected(null);
                }
            }
        }
    }

    protected stochastic _process_builder;

    protected stochastic _process;

    protected stochastic _writer;

    protected stochastic _reader;
}