/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

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

    protected static String requireHost(final String HOST)
    {
        if(HOST==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        return HOST;
    }

    protected static Integer requirePort(final Integer PORT)
    {
        if(PORT==null || PORT<0 || PORT>65535) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        return PORT;
    }

    protected static String requireThreadName(final String THREAD_NAME)
    {
        if(THREAD_NAME==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        return THREAD_NAME;
    }

    protected static Boolean requireTelnetProxyEnabled(final Boolean TELNET_PROXY_ENABLED)
    {
        if(TELNET_PROXY_ENABLED==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        return TELNET_PROXY_ENABLED;
    }

    public WebExpress()
    {
        this.setName("United States::D500::WebExpress");
    }

    public WebExpress(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
    {
        super(requireHost(HOST), requirePort(PORT));

        this.INHERITOR = this;

        this.THREAD_NAME = requireThreadName(THREAD_NAME);

        this.TELNET_PROXY_ENABLED = requireTelnetProxyEnabled(TELNET_PROXY_ENABLED);

        CommonRails.printSystemComponent(this, this.hashCode(), ". CommonRails starts .");

        if(this.TELNET_PROXY_ENABLED)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". "+this.THREAD_NAME+" "+HOST+" : "+PORT+" Telnet Proxy Enabled .");

            this.TELNET_INSTALLER = new TelnetInstaller(this);

            this.TELNET_COMMUNICATION_PROXY = new TelnetCommunicationProxy(this);

            this.MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);

            this.MESSAGE_QUEUE_SORTER.setName("MessageQueueSorter.TelnetProxy");

            this.TELNET_COMMUNICATION_PROXY.output_builder.setName("TelnetCommunicationProxy.Builder.Output");

            this.TELNET_COMMUNICATION_PROXY.input_builder.setName("TelnetCommunicationProxy.Builder.Input");
        }
        else
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". Main starts "+this.THREAD_NAME+" HOST : "+PORT+" .");

            this.MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);

            this.MESSAGE_QUEUE_SORTER.setName("MessageQueueSorter.AES2");
        }

        this.MESSAGE_QUEUE_SORTER.start();

        this.setName(this.THREAD_NAME);
    }
}
