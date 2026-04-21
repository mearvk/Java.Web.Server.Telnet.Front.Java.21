package message;

import commons.CommonRails;
import server.WebExpress;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.util.Date;

public class MessageQueueSorter extends Thread
{
    protected WebExpress web_express;

    public MessageQueueSorter(WebExpress web_express)
    {
        this.web_express = web_express;
    }

    @Override
    public void run()
    {
        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> starts ["+new Date()+"].");

        for(;;)
        {
            MessageQueue message_queue = this.web_express.message_queue;

            for(int i=0; i<message_queue.messages.size(); i++)
            {
                System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> reports message queue has size of ["+message_queue.messages.size()+"].");

                System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> received message ["+message_queue.messages.get(i)+"].");

                MessageQueue.Message message = message_queue.messages.remove(i);

                try
                {
                    if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                    {
                        BufferedWriter writer = this.web_express.telnet_communication_proxy.writer;

                        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> sending to Telnet message [Message]: " + message.message_buffer + "].");

                        writer.write("[Message]: " + message.message_buffer);

                        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> sending to Telnet message [Date]: " + message.time_stamp + "].");

                        writer.write("[Date]: " + message.time_stamp);

                        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> sending to Telnet message [IP Address]: " + message.internet_address + "].");

                        writer.write("[IP Address]: " + message.internet_address);

                        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> sending to Telnet message [Socket]: " + message.internet_address + "].");

                        writer.write("[Socket]: " + message.socket);

                        writer.flush();
                    }
                }
                catch (NullPointerException npe)
                {
                    this.web_express.current_connections.remove(message.socket);

                    System.out.println("[Object ID: "+this.hashCode()+"] WebExpress >> dropped connection ["+message.socket+"] - new connection count ["+(this.web_express.current_connections.size())+"].");

                    break;
                }
                catch (IOException e)
                {
                    System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> socket connection closed [Socket]: " + message.internet_address + "].");
                }

                try
                {
                    BufferedReader reader = this.web_express.telnet_communication_proxy.reader;

                    BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(message.socket.getOutputStream()));

                    String line = null;

                    while((line=reader.readLine())!=null)
                    {
                        if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                        {
                            System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> received from active Telnet session ["+ WebExpress.REMOTE_SITE+":"+ WebExpress.REMOTE_PORT+"] message ["+line+"].");

                            writer.write(line);

                            writer.flush();
                        }
                        else
                        {
                            this.web_express.current_connections.remove(message.socket);

                            System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::message.MessageQueueSorter >> dropped connection ["+message.socket+"] - new connection count ["+(this.web_express.current_connections.size()+1)+"].");

                            break;
                        }
                    }

                    writer.close();
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }
            }

            try
            {
                Thread.sleep(1000);
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }

    public synchronized void addMessage(MessageQueue.Message message)
    {
        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::addMessage >> message queue size before ["+this.getMessageQueueSize()+"].");

        this.web_express.message_queue.add(message);

        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::addMessage >> message queue size after ["+this.getMessageQueueSize()+"].");
    }

    public synchronized MessageQueue getMessageQueue()
    {
        return this.web_express.message_queue;
    }

    public synchronized Integer getMessageQueueSize()
    {
        return this.web_express.message_queue.messages.size();
    }
}