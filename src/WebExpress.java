import java.io.*;
import java.util.Date;

public class WebExpress extends BaseServer
{
    protected static final String[] TELNET_PROXY_SERVER_ARGS = new String[]{"telnet", "tacobell.phd", "80"};

    protected static final Boolean TELNET_PROXY = Boolean.FALSE;

    protected TelnetInstaller telnet_installer;

    protected TelnetCommunicationProxy telnet_communicator;

    protected MessageQueueSorter message_queue_sorter;

    public WebExpress(final String host, final Integer port, final Boolean telnet_proxy)
    {
        super(host, port);

        if (telnet_proxy)
        {
            System.out.println("WebExpress::Main >> starts [Object ID: "+this.hashCode()+"] [" + new Date() + "] [" + host + ":" + port + "] [Telnet Proxy Enabled]");

            this.telnet_installer = new TelnetInstaller(this);

            this.telnet_communicator = new TelnetCommunicationProxy(this);
        }
        else
        {
            System.out.println("WebExpress::Main >> starts [Object ID: "+this.hashCode()+"] [" + new Date() + "] [" + host + ":" + port + "]");
        }

        System.out.println("WebExpress::CommonRail >> starts [" + new Date() + "].");

        this.message_queue_sorter = new MessageQueueSorter(this);

        this.message_queue_sorter.start();
    }
}
