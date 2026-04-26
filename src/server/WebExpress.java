package server;

import commons.CommonRails;
import encryption.AES2;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import telnet.TelnetCommunicationProxy;
import telnet.TelnetInstaller;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.util.Date;
import java.util.Random;

public class WebExpress extends BaseServer
{
    public static WebExpress reference = new WebExpress();

    public static final String[] TELNET_PROXY_SERVER_ARGS = new String[]{"telnet", "tacobell.phd", "80"};

    public static final Boolean TELNET_PROXY = Boolean.FALSE;

    public static final String PROTOCOL = "telnet";

    public static final String REMOTE_SITE = "tacobell.phd";

    public static final String REMOTE_PORT = "80";

    public String THREAD_NAME;

    public TelnetInstaller telnet_installer;

    public TelnetCommunicationProxy telnet_communication_proxy;

    public MessageQueueSorter message_queue_sorter;

    public MessageQueue message_queue = new MessageQueue(this);

    public WebExpress()
    {
        WebExpress.reference = this;

        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::CommonRails >> starts.");

        this.setName("WebExpress");
    }

    public WebExpress(final String host, final Integer port, final String thread_name, final Boolean telnet_proxy_enabled)
    {
        super(host, port);

        this.THREAD_NAME = thread_name;

        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::CommonRails >> starts.");

        if (telnet_proxy_enabled)
        {
            CommonRails.printSystemComponent(this.hashCode(),"WebExpress::Main >> starts ["+thread_name+"] [" + host + ":" + port + "] [Telnet Proxy Enabled]");

            this.telnet_installer = new TelnetInstaller(this);

            this.telnet_communication_proxy = new TelnetCommunicationProxy(this);

            this.message_queue_sorter = new MessageQueueSorter(this);

            this.message_queue_sorter.setName("MessageQueueSorter.TelnetProxy");

            this.telnet_communication_proxy.output_builder.setName("TelnetCommunicationProxy.Builder.Output");

            this.telnet_communication_proxy.input_builder.setName("TelnetCommunicationProxy.Builder.Input");
        }
        else
        {
            CommonRails.printSystemComponent(this.hashCode(), "WebExpress::Main >> starts ["+thread_name+"] [" + host + ":" + port + "]");

            this.message_queue_sorter = new MessageQueueSorter(this);

            this.message_queue_sorter.setName("MessageQueueSorter.AES2");
        }

        this.message_queue_sorter.start();

        WebExpress.reference = this;

        this.setName(thread_name);
    }

    public static class Aspect
    {
        protected AESCompliant.MessageOutputHandler message_output_handler = new AESCompliant.MessageOutputHandler();

        protected AES2 aes = new AES2(String.valueOf(new Random(10078)));

        public static class AESCompliant extends WebExpress
        {
            public AESCompliant(final String host, final Integer port, final String thread_name, final Boolean telnet_proxy_enabled)
            {
                super(host, port, thread_name, telnet_proxy_enabled);

                this.host = host;

                this.port = port;

                this.setName(thread_name);

                this.start();
            }

            protected static class MessageOutputRecord
            {

            }

            protected static class MessageOutputHandler
            {
                public Socket socket;

                public void send_message(StringBuffer buffer)
                {
                    if(socket!=null && CommonRails.SocketUtils.isSocketConnected(socket))
                    {
                        try
                        {
                            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));

                            writer.write(buffer.toString());

                            writer.write( new AES2(String.valueOf(this.hashCode() | (this.hashCode() & new Date().hashCode()) | Integer.parseUnsignedInt("1132"))).cipher_text );

                            writer.flush();
                        }
                        catch (Exception e)
                        {
                            if(CommonRails.SocketUtils.isSocketClosed(socket))
                            {
                                try
                                {
                                    socket.close();
                                }
                                catch (Exception xe)
                                {
                                    CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageOutputHandler >> closes on try-exception to close ["+socket.toString()+"]");
                                }
                                finally
                                {
                                    CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageOutputHandler >> safe closes ["+socket.toString()+"]");
                                }
                            }
                        }
                    }
                }

                public void send_message(String message)
                {
                    if(socket!=null && CommonRails.SocketUtils.isSocketConnected(socket))
                    {
                        try
                        {
                            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));

                            writer.write(message);

                            writer.flush();
                        }
                        catch (Exception e)
                        {
                            if(CommonRails.SocketUtils.isSocketClosed(socket))
                            {
                                try
                                {
                                    socket.close();
                                }
                                catch (Exception xe)
                                {
                                    CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageOutputHandler >> closes on try-exception to close ["+socket.toString()+"]");
                                }
                                finally
                                {
                                    CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageOutputHandler >> safe closes ["+socket.toString()+"]");
                                }
                            }
                        }
                    }
                }
            }
        }

        public static class BitcoinCompliant extends WebExpress
        {
            public Socket socket;

            public BitcoinCompliant(final String host, final Integer port, final String thread_name, final Boolean telnet_proxy_enabled)
            {
                super(host, port, thread_name, telnet_proxy_enabled);

                this.host = host;

                this.port = port;

                this.setName(thread_name);

                this.start();
            }

            public BitcoinCompliant()
            {

            }

            public void send_message(StringBuffer buffer)
            {
                if (socket != null && CommonRails.SocketUtils.isSocketConnected(socket))
                {
                    try
                    {
                        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));

                        writer.write(buffer.toString());

                        writer.flush();
                    }
                    catch (Exception e)
                    {
                        if (CommonRails.SocketUtils.isSocketClosed(socket))
                        {
                            try
                            {
                                socket.close();
                            }
                            catch (Exception xe)
                            {
                                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageOutputHandler >> closes on try-exception to close [" + socket.toString() + "]");
                            }
                            finally
                            {
                                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageOutputHandler >> safe closes [" + socket.toString() + "]");
                            }
                        }
                    }
                }
            }

            public void send_message(String message)
            {
                if (socket != null && CommonRails.SocketUtils.isSocketConnected(socket))
                {
                    try
                    {
                        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));

                        writer.write(message);

                        writer.flush();
                    }
                    catch (Exception e)
                    {
                        if (CommonRails.SocketUtils.isSocketClosed(socket))
                        {
                            try
                            {
                                socket.close();
                            }
                            catch (Exception xe)
                            {
                                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageOutputHandler >> closes on try-exception to close [" + socket.toString() + "]");
                            }
                            finally
                            {
                                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageOutputHandler >> safe closes [" + socket.toString() + "]");
                            }
                        }
                    }
                }
            }
        }
    }

}
