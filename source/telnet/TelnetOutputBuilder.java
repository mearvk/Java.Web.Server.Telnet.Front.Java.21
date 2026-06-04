package telnet;

import commons.CommonRails;

public class TelnetOutputBuilder extends Thread
{
    public TelnetCommunicationProxy telnet_communication_proxy;

    public TelnetMessageQueue TELNET_MESSAGE_QUEUE = new TelnetMessageQueue(5000);

    public TelnetOutputBuilder(TelnetCommunicationProxy telnet_communication_proxy)
    {
        this.telnet_communication_proxy = telnet_communication_proxy;
    }

    @Override
    public void run()
    {
        while(true)
        {
            TelnetMessageQueue queue = this.TELNET_MESSAGE_QUEUE;

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

                            final String value = message.MESSAGE_BUFFER.toString();

                            final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                            if(!value.isEmpty())
                            {
                                CommonRails.printSystemComponent(this, this.hashCode(), "TelnetOutputBuilder Output >> sending message ["+value+"]");

                                if(CommonRails.isConnected(proxy.writer))
                                    proxy.writer.write(value);

                                if(CommonRails.isConnected(proxy.writer))
                                    proxy.writer.flush();

                                queue.messages.removeFirst();
                            }
                            else
                            {
                                CommonRails.printSystemComponent(this, this.hashCode(), "TelnetOutputBuilder Output >> removing sorted-simple message.");

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
