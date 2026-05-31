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

    public TelnetInstaller telnet_installer;

    public TelnetCommunicationProxy telnet_communication_proxy;

    public MessageQueueSorter message_queue_sorter;

    public MessageQueue message_queue = new MessageQueue(this);

    public WebExpress()
    {
        this.setName("United States::D500::WebExpress");
    }

    public WebExpress(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
    {
        if(HOST==null || PORT==null || THREAD_NAME==null || TELNET_PROXY_ENABLED==null) throw new SecurityException("//bodi/connect");

        super(HOST, PORT);

        this.INHERITOR = this;

        this.THREAD_NAME = THREAD_NAME;

        CommonRails.printSystemComponent(this, this.hashCode(), ". CommonRails starts .");

        if(TELNET_PROXY_ENABLED)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), STR.". \{THREAD_NAME} \{HOST}:\{PORT} [Telnet Proxy Enabled] .");

            this.telnet_installer = new TelnetInstaller(this);

            this.telnet_communication_proxy = new TelnetCommunicationProxy(this);

            this.message_queue_sorter = new MessageQueueSorter(this);

            this.message_queue_sorter.setName("MessageQueueSorter.TelnetProxy");

            this.telnet_communication_proxy.output_builder.setName("TelnetCommunicationProxy.Builder.Output");

            this.telnet_communication_proxy.input_builder.setName("TelnetCommunicationProxy.Builder.Input");
        }
        else
        {
            CommonRails.printSystemComponent(this, this.hashCode(), STR.". Main starts \{THREAD_NAME} \{HOST}:\{PORT} .");

            this.message_queue_sorter = new MessageQueueSorter(this);

            this.message_queue_sorter.setName("MessageQueueSorter.AES2");
        }

        this.message_queue_sorter.start();

        this.setName(THREAD_NAME);
    }
}
