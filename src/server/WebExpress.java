package server;

import commons.CommonRails;
import encryption.AES2;
import messaging.MessageOutputHandler;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import telnet.TelnetCommunicationProxy;
import telnet.TelnetInstaller;

import java.net.Socket;
import java.util.Random;

public class WebExpress extends BaseServer
{
    protected String hash = "0xDA717018470E213F";

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

        this.setName("United States::D500::WebExpress");
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
                public MessageOutputRecord()
                {
                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageOutputRecord >> starts.");
                }
            }

            protected static class MessageOutputHandler
            {
                public Socket socket;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageOutputHandler >> starts.");
                }

                public void send_message(StringBuffer buffer)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(socket, buffer);

                    message_output_handler.run();
                }

                public void send_message(String message)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(socket, message);

                    message_output_handler.run();
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
                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::BitcoinCompliant >> starts.");
            }

            public void send_message(StringBuffer buffer)
            {
                MessageOutputHandler message_output_handler = new MessageOutputHandler(socket, buffer);

                message_output_handler.run();
            }

            public void send_message(String message)
            {
                MessageOutputHandler message_output_handler = new MessageOutputHandler(socket, message);

                message_output_handler.run();
            }
        }
    }

}
