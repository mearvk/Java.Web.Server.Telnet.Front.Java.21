package telnet;

import commons.CommonRails;
import exceptions.ExceptionHandler;

public class TelnetInputBuilder extends Thread
{
    protected TelnetCommunicationProxy telnet_communication_proxy;

    protected TelnetMessageQueue telnet_message_queue;

    protected StringBuffer BUFFER = new StringBuffer();

    public TelnetInputBuilder(final TelnetCommunicationProxy TELNET_PROXY_COMMUNICATOR)
    {
        this.telnet_communication_proxy = TELNET_PROXY_COMMUNICATOR;

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
                            final String message = queue.MESSAGES.get(0).MESSAGE_BUFFER.toString();

                            final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                            if (proxy.process != null && proxy.process.isAlive() && proxy.writer != null)
                            {
                                proxy.writer.write(message);
                                proxy.writer.flush();

                                CommonRails.printSystemComponent(this, this.hashCode(), "TelnetInputBuilder >> sending message ["+message+"]");
                            }

                            queue.MESSAGES.remove(0);
                        }
                        catch (Exception e)
                        {
                            ExceptionHandler.dispatch(e);
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

    public void setBuffer(final StringBuffer BUFFER)
    {
        this.BUFFER = BUFFER;
    }
}
