package server.nitro;

import commons.CommonRails;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import server.base.BaseServer;
import telnet.TelnetCommunicationProxy;
import telnet.TelnetInstaller;

public class WebExpress extends BaseServer
{
    protected String hash = "0xDA717018470E213F";

    public static final String[] TELNET_PROXY_SERVER_ARGS = new String[]{"telnet", "tacobell.phd", "80"};

    public static final Boolean TELNET_PROXY = Boolean.FALSE;

    public static final String PROTOCOL = "telnet";

    public static final String REMOTE_SITE = "tacobell.phd";

    public static final String REMOTE_PORT = "80";

    public String THREAD_NAME;

    public Boolean TELNET_PROXY_ENABLED;

    public TelnetInstaller TELNET_INSTALLER;

    public TelnetCommunicationProxy TELNET_COMMUNICATION_PROXY;

    public MessageQueueSorter MESSAGE_QUEUE_SORTER;

    public MessageQueue MESSAGE_QUEUE = new MessageQueue(this);

    public WebExpress WEBEXPRESS;

    public BaseServer BASESERVER;

    public WebExpress()
    {
        this.setName("United States D500 WebExpress");
    }

    public WebExpress(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
    {
        if(HOST==null || PORT==null || THREAD_NAME==null || TELNET_PROXY_ENABLED==null) throw new SecurityException("//bodi/connect");

        super(HOST, PORT);

        this.BASESERVER = this.SELF;

        this.SUPERCLASS = this;

        this.THREAD_NAME = THREAD_NAME;

        CommonRails.printSystemComponent(this, this.hashCode(), ". CommonRails starts .");

        if(TELNET_PROXY_ENABLED)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". "+THREAD_NAME+" "+HOST+" : "+PORT+" Telnet Proxy Enabled .");

            this.TELNET_INSTALLER = new TelnetInstaller(this);

            this.TELNET_COMMUNICATION_PROXY = new TelnetCommunicationProxy(this);

            this.MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);

            this.MESSAGE_QUEUE_SORTER.setName("MessageQueueSorter.TelnetProxy");

            this.TELNET_COMMUNICATION_PROXY.output_builder.setName("TelnetCommunicationProxy.Builder.Output");

            this.TELNET_COMMUNICATION_PROXY.input_builder.setName("TelnetCommunicationProxy.Builder.Input");
        }
        else
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". Main starts "+THREAD_NAME+" HOST : "+PORT+" .");

            this.MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);

            this.MESSAGE_QUEUE_SORTER.setName("MessageQueueSorter.AES2");
        }

        this.MESSAGE_QUEUE_SORTER.start();

        this.setName(THREAD_NAME);
    }
}
