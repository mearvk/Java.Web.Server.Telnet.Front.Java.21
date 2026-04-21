package telnet;

import java.net.Socket;

public class TelnetInputBuilder extends Thread
{
    protected TelnetCommunicationProxy telnet_proxy_communicator;

    protected StringBuffer buffer = new StringBuffer();

    public TelnetInputBuilder(TelnetCommunicationProxy telnet_proxy_communicator)
    {
        this.telnet_proxy_communicator = telnet_proxy_communicator;
    }

    @Override
    public void run()
    {

    }

    public void setBuffer(StringBuffer buffer)
    {
        this.buffer = buffer;
    }
}
