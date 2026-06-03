package telnet;

import commons.CommonRails;

public class TelnetInputBuilder extends Thread
{
    protected TelnetCommunicationProxy telnet_communication_proxy;

    protected TelnetMessageQueue telnet_message_queue;

    protected StringBuffer buffer = new StringBuffer();

    public TelnetInputBuilder(TelnetCommunicationProxy telnet_proxy_communicator)
    {
        this.telnet_communication_proxy = telnet_proxy_communicator;

        this.telnet_message_queue = new TelnetMessageQueue(5000);
    }

    @Override
    public void run()
    {
        while(true)
        {
            TelnetMessageQueue queue = this.telnet_message_queue;

            try
            {
                synchronized (queue)
                {
                    while (queue.size() == 0)
                    {
                        try { queue.wait(); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); return; }
                    }

                    // process all available messages
                    while (queue.size() > 0)
                    {
                        try
                        {
                            final String message = queue.messages.get(0).message_buffer.toString();

                            final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                            proxy.writer.write(message);

                            CommonRails.printSystemComponent(this, this.hashCode(), "[Object ID: "+this.hashCode()+"] TelnetOutputBuilder::Output >> sending message ["+message+"]");

                            proxy.writer.flush();

                            queue.messages.remove(0);
                        }
                        catch (Exception e)
                        {
                            e.printStackTrace(System.err);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }

    public void setBuffer(StringBuffer buffer)
    {
        this.buffer = buffer;
    }
}
