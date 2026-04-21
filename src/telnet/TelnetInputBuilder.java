package telnet;

public class TelnetInputBuilder extends Thread
{
    protected TelnetCommunicationProxy telnet_proxy_communicator;

    protected TelnetMessageQueue telnet_message_queue;

    protected StringBuffer buffer = new StringBuffer();

    public TelnetInputBuilder(TelnetCommunicationProxy telnet_proxy_communicator)
    {
        this.telnet_proxy_communicator = telnet_proxy_communicator;

        this.telnet_message_queue = new TelnetMessageQueue(5000);
    }

    @Override
    public void run()
    {
        for(;;)
        {

        }
    }

    public void setBuffer(StringBuffer buffer)
    {
        this.buffer = buffer;
    }
}
