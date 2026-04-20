import java.util.Date;

public class WebExpress extends BaseServer
{
    protected static WebExpress reference = new WebExpress();

    protected static final String[] TELNET_PROXY_SERVER_ARGS = new String[]{"telnet", "tacobell.phd", "80"};

    protected static final Boolean TELNET_PROXY = Boolean.FALSE;

    protected static final String PROTOCOL = "telnet";

    protected static final String REMOTE_SITE = "tacobell.phd";

    protected static final String REMOTE_PORT = "80";

    protected TelnetInstaller telnet_installer;

    protected TelnetCommunicationProxy telnet_communication_proxy;

    protected MessageQueueSorter message_queue_sorter;

    protected MessageQueue message_queue = new MessageQueue(this);

    public WebExpress()
    {
        WebExpress.reference = this;
    }

    public WebExpress(final String host, final Integer port, final Boolean telnet_proxy)
    {
        super(host, port);

        if (telnet_proxy)
        {
            System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::Main >> starts [" + new Date() + "] [" + host + ":" + port + "] [Telnet Proxy Enabled]");

            this.telnet_installer = new TelnetInstaller(this);

            this.telnet_communication_proxy = new TelnetCommunicationProxy(this);
        }
        else
        {
            System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::Main >> starts [Object ID: "+this.hashCode()+"] [" + new Date() + "] [" + host + ":" + port + "]");
        }

        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::CommonRail >> starts [" + new Date() + "].");

        this.message_queue_sorter = new MessageQueueSorter(this);

        this.message_queue_sorter.start();

        WebExpress.reference = this;
    }
}
