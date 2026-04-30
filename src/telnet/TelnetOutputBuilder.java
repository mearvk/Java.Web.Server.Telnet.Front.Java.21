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

            for(int i=0; queue!=null && i<queue.messages.size(); i++)
            {
                try
                {
                    final TelnetMessageQueue.Message message = queue.messages.get(i);

                    final String value = message.message_buffer.toString();

                    final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                    if(!value.isEmpty())
                    {
                        CommonRails.printSystemComponent(this.hashCode(), "TelnetOutputBuilder::Output >> sending message ["+message+"]");

                        proxy.writer.write(value);

                        proxy.writer.flush();

                        queue.messages.remove(i);
                    }
                    else
                    {
                        CommonRails.printSystemComponent(this.hashCode(), "TelnetOutputBuilder::Output >> removing sorted-simple message.");

                        queue.messages.remove(i);
                    }
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }
            }

            try{ Thread.sleep(1000); } catch (Exception e){e.printStackTrace(System.err);}
        }
    }
}
