package messaging;

import commons.CommonRails;
import commons.socket.SocketUtils;
import exceptions.ExceptionHandler;
import server.webexpress.WebExpress;

import java.io.BufferedWriter;
import java.io.IOException;
import java.net.SocketTimeoutException;

public class MessageQueueSorter extends Thread
{
    protected String hash = "0xDA717018470E213F";

    protected WebExpress WEBEXPRESS;

    public MessageQueueSorter(final WebExpress WEBEXPRESS)
    {
        this.WEBEXPRESS = WEBEXPRESS;

        this.setName("MessageQueueSorter");
    }

    @Override
    public void run()
    {
        CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter starts .");

        while(true)
        {
            MessageQueue message_queue = this.WEBEXPRESS.MESSAGE_QUEUE;

            try
            {
                synchronized (message_queue)
                {
                    while (message_queue.MESSAGES.size() == 0)
                    {
                        try { message_queue.wait(); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); return; }
                    }

                    // process all messages currently in queue
                    while (message_queue.MESSAGES.size() > 0)
                    {
                        MessageQueue.Message message = message_queue.MESSAGES.remove(0);

                        try
                        {
                            if (SocketUtils.isConnected(message.SOCKET)
                                    && this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY != null
                                    && this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.writer != null)
                            {
                                BufferedWriter writer = this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.writer;

                                writer.write("Message: "    + message.MESSAGE_BUFFER   + "\n");
                                writer.write("[Date]: "     + message.TIME_STAMP        + "\n");
                                writer.write("[IP Address]: "+ message.INTERNET_ADDRESS + "\n");
                                writer.write("[Socket]: "   + message.SOCKET            + "\n");
                                writer.flush();
                            }

                            CommonRails.printSystemComponent(this, this.hashCode(),
                                ". MessageQueueSorter >> processed [" + message.MESSAGE_BUFFER.toString().trim() + "] from " + message.INTERNET_ADDRESS + " .");
                        }
                        catch (SocketTimeoutException ste)
                        {
                            this.WEBEXPRESS.CURRENT_CONNECTIONS.remove(message.SOCKET);
                            try { message.SOCKET.close(); } catch (Exception ignored) {}
                        }
                        catch (IOException e)
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

    public synchronized void addMessage(final MessageQueue.Message MESSAGE)
    {
        this.WEBEXPRESS.MESSAGE_QUEUE.add(MESSAGE);
    }

    public synchronized MessageQueue getMessageQueue()
    {
        return this.WEBEXPRESS.MESSAGE_QUEUE;
    }

    public synchronized Integer getMessageQueueSize()
    {
        return this.WEBEXPRESS.MESSAGE_QUEUE.MESSAGES.size();
    }
}