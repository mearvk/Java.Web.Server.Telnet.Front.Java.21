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
        while(true)
        {
            TelnetMessageQueue queue = this.telnet_message_queue;

            for(int i=0; i<queue.size(); i++)
            {
                try
                {
                    final String message = queue.messages.get(i).message_buffer.toString();

                    final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                    proxy.writer.write(message);

                    System.out.println("[Object ID: "+this.hashCode()+"] TelnetOutputBuilder::Output >> sending message ["+message+"]");

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
}
