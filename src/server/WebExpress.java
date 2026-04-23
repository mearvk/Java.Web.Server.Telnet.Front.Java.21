package server;

import commons.CommonRails;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import telnet.TelnetCommunicationProxy;
import telnet.TelnetInstaller;

public class WebExpress extends BaseServer
{
    public static WebExpress reference = new WebExpress();

    public static final String[] TELNET_PROXY_SERVER_ARGS = new String[]{"telnet", "tacobell.phd", "80"};

    public static final Boolean TELNET_PROXY = Boolean.FALSE;

    public static final String PROTOCOL = "telnet";

    public static final String REMOTE_SITE = "tacobell.phd";

    public static final String REMOTE_PORT = "80";

    public TelnetInstaller telnet_installer;

    public TelnetCommunicationProxy telnet_communication_proxy;

    public MessageQueueSorter message_queue_sorter;

    public MessageQueue message_queue = new MessageQueue(this);

    public WebExpress()
    {
        WebExpress.reference = this;
    }

    public WebExpress(final String host, final Integer port, final Boolean telnet_proxy)
    {
        super(host, port);

        if (telnet_proxy)
        {
            CommonRails.printSystemComponent(this.hashCode(),"WebExpress::Main >> starts [" + host + ":" + port + "] [Telnet Proxy Enabled]");

            this.telnet_installer = new TelnetInstaller(this);

            this.telnet_communication_proxy = new TelnetCommunicationProxy(this);
        }
        else
        {
            CommonRails.printSystemComponent(this.hashCode(), "WebExpress::Main >> starts [" + host + ":" + port + "]");
        }

        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::CommonRails >> starts.");

        this.message_queue_sorter = new MessageQueueSorter(this);

        this.message_queue_sorter.start();

        WebExpress.reference = this;
    }
}
