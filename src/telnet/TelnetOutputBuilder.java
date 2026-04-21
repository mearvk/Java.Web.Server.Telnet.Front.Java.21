package telnet;

public class TelnetOutputBuilder extends Thread
{
    protected TelnetCommunicationProxy telnet_communication_proxy;

    protected TelnetMessageQueue telnet_message_queue = new TelnetMessageQueue(5000);

    public TelnetOutputBuilder(TelnetCommunicationProxy telnet_communication_proxy)
    {
        this.telnet_communication_proxy = telnet_communication_proxy;
    }

    @Override
    public void run()
    {

    }
}
