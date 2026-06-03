package telnet;

import commons.CommonRails;

public class TelnetOutputBuilder extends Thread
{
    public TelnetCommunicationProxy telnet_communication_proxy;

    public TelnetMessageQueue telnet_message_queue = new TelnetMessageQueue(5000);

    public TelnetOutputBuilder(TelnetCommunicationProxy telnet_communication_proxy)
    {
        this.telnet_communication_proxy = telnet_communication_proxy;
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

                    while (queue.messages.size() > 0)
                    {
                        try
                        {
                            final TelnetMessageQueue.Message message = queue.messages.get(0);

                            final String value = message.message_buffer.toString();

                            final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                            if(!value.isEmpty())
                            {
                                CommonRails.printSystemComponent(this, this.hashCode(), "TelnetOutputBuilder::Output >> sending message ["+message+"]");

                                proxy.writer.write(value);

                                proxy.writer.flush();

                                queue.messages.remove(0);
                            }
                            else
                            {
                                CommonRails.printSystemComponent(this, this.hashCode(), "TelnetOutputBuilder::Output >> removing sorted-simple message.");

                                queue.messages.remove(0);
                            }
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
}
