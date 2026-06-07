package telnet;

import commons.CommonRails;
import exceptions.ExceptionHandler;

public class TelnetOutputBuilder extends Thread
{
    public TelnetCommunicationProxy TELNET_COMMUNICATION_PROXY;

    public TelnetMessageQueue TELNET_MESSAGE_QUEUE = new TelnetMessageQueue(5000);

    public TelnetOutputBuilder(final TelnetCommunicationProxy TELNET_COMMUNICATION_PROXY)
    {
        this.TELNET_COMMUNICATION_PROXY = TELNET_COMMUNICATION_PROXY;
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

                    while (queue.MESSAGES.size() > 0)
                    {
                        try
                        {
                            final TelnetMessageQueue.Message message = queue.MESSAGES.get(0);

                            final String value = message.MESSAGE_BUFFER.toString();

                            final TelnetCommunicationProxy proxy = this.TELNET_COMMUNICATION_PROXY;

                            if(!value.isEmpty())
                            {
                                CommonRails.printSystemComponent(this, this.hashCode(), "TelnetOutputBuilder Output >> sending message ["+value+"]");

                                if(CommonRails.isConnected(proxy.writer))
                                    proxy.writer.write(value);

                                if(CommonRails.isConnected(proxy.writer))
                                    proxy.writer.flush();

                                queue.MESSAGES.removeFirst();
                            }
                            else
                            {
                                CommonRails.printSystemComponent(this, this.hashCode(), "TelnetOutputBuilder Output >> removing sorted-simple message.");

                                queue.MESSAGES.remove(0);
                            }
                        }
                        catch (Exception e)
                        {
                            ExceptionHandler.dispatch(e);
                            e.printStackTrace(System.err);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                ExceptionHandler.dispatch(e);
                e.printStackTrace(System.err);
            }
        }
    }
}
