/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

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

            if (queue == null) {
                try{ Thread.sleep(1000); } catch (Exception e){e.printStackTrace(System.err);} 
                continue;
            }

            int i = 0;
            while (i < queue.messages.size())
            {
                try
                {
                    final TelnetMessageQueue.Message message = queue.messages.get(i);

                    final String value = message.message_buffer == null ? "" : message.message_buffer.toString();

                    final TelnetCommunicationProxy proxy = this.telnet_communication_proxy;

                    if (proxy == null || proxy.writer == null)
                    {
                        // advance to avoid stuck on null proxy
                        i++;
                        continue;
                    }

                    if(!value.isEmpty())
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(), "TelnetOutputBuilder::Output >> sending message ["+value+"]");

                        proxy.writer.write(value);

                        proxy.writer.flush();

                        queue.messages.remove(i);
                        // do not increment i, list shifted
                    }
                    else
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(), "TelnetOutputBuilder::Output >> removing empty message.");

                        queue.messages.remove(i);
                        // do not increment i, list shifted
                    }
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                    i++; // advance on error to avoid infinite loop
                }
            }

            try{ Thread.sleep(1000); } catch (Exception e){e.printStackTrace(System.err);} 
        }
    }
}
