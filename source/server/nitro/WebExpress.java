package server.nitro;

import bitcoin.module.TraderModule;
import commons.CommonRails;
import commons.EnglishArithemeter;
import connections.CurrentConnections;
import encryption.module.aes.two.EncryptionModule;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import server.base.BaseServer;
import telnet.TelnetCommunicationProxy;
import telnet.TelnetInstaller;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.net.SocketTimeoutException;
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

        this.setName("United States::D500::WebExpress");
    }

    public WebExpress(final String host, final Integer port, final String thread_name, final Boolean TELNET_PROXY_ENABLED)
    {
        super(host, port);

        this.THREAD_NAME = thread_name;

        CommonRails.printSystemComponent(this, this.hashCode(), ". CommonRails starts .");

        if (TELNET_PROXY_ENABLED)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),". "+thread_name+" " + host + ":" + port + " [Telnet Proxy Enabled] .");

            this.telnet_installer = new TelnetInstaller(this);

            this.telnet_communication_proxy = new TelnetCommunicationProxy(this);

            this.message_queue_sorter = new MessageQueueSorter(this);

            this.message_queue_sorter.setName("MessageQueueSorter.TelnetProxy");

            this.telnet_communication_proxy.output_builder.setName("TelnetCommunicationProxy.Builder.Output");

            this.telnet_communication_proxy.input_builder.setName("TelnetCommunicationProxy.Builder.Input");
        }
        else if(!TELNET_PROXY_ENABLED)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". Main starts "+thread_name+" " + host + ":" + port + " .");

            this.message_queue_sorter = new MessageQueueSorter(this);

            this.message_queue_sorter.setName("MessageQueueSorter.AES2");
        }

        this.message_queue_sorter.start();

        WebExpress.reference = this;

        this.setName(thread_name);
    }
}
