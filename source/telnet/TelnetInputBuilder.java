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

            if (queue == null) {
                try{ Thread.sleep(1000); } catch (Exception e){e.printStackTrace(System.err);} 
                continue;
            }

            int i = 0;
            while (i < queue.size())
            {
                try
                {
                    final String message = queue.messages.get(i).message_buffer.toString();

                    final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                    proxy.writer.write(message);

                    CommonRails.printSystemComponent(this, this.hashCode(), "[Object ID: "+this.hashCode()+"] TelnetInputBuilder::Input >> sending message ["+message+"]");

                    proxy.writer.flush();

                    // remove the message after successfully sending
                    queue.messages.remove(i);
                    // do not increment i because the list shifted
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                    // on exception, advance to avoid tight-looping on a bad element
                    i++;
                }
            }

            try{ Thread.sleep(1000); } catch (Exception e){e.printStackTrace(System.err);} 
        }
    }

    public void setBuffer(StringBuffer buffer)
    {
        this.buffer = buffer;
    }
}
