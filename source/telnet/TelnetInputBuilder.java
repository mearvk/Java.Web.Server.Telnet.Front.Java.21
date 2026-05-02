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

            for(int i=0; queue!=null && i<queue.size(); i++)
            {
                try
                {
                    final String message = queue.messages.get(i).message_buffer.toString();

                    final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                    proxy.writer.write(message);

                    CommonRails.printSystemComponent(this.hashCode(), "[Object ID: "+this.hashCode()+"] TelnetOutputBuilder::Output >> sending message ["+message+"]");

                    proxy.writer.flush();
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
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
