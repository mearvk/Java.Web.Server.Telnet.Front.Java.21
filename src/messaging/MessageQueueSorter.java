package messaging;

import commons.CommonRails;
import commons.EnglishArithemeter;
import connections.CurrentConnections;
import server.WebExpress;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.SocketTimeoutException;
import java.util.ArrayList;

public class MessageQueueSorter extends Thread
{
    protected WebExpress web_express;

    public MessageQueueSorter(WebExpress web_express)
    {
        this.web_express = web_express;

        this.setName("MessageQueueSorter");
    }

    @Override
    public void run()
    {
        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageQueueSorter >> starts.");

        for(;;)
        {
            MessageQueue message_queue = this.web_express.message_queue;

            for(int i=0; i<message_queue.messages.size(); i++)
            {
                CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageQueueSorter ["+this.web_express.THREAD_NAME+"] >> reports message queue has size of ["+message_queue.messages.size()+"].");

                CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageQueueSorter >> received message from connection ["+message_queue.messages.get(i).socket+"] ["+message_queue.messages.get(i).message_buffer+"].");

                MessageQueue.Message message = message_queue.messages.remove(i);

                try
                {
                    if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                    {
                        BufferedWriter writer = this.web_express.telnet_communication_proxy.writer;

                        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageQueueSorter >> sending to Telnet message [Message]: [" + message.message_buffer + "].");

                        writer.write("[Message: ]"+message.message_buffer+"\n");

                        CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageQueueSorter >> sending to Telnet message [Date]: [" + message.time_stamp + "].");

                        writer.write("[Date]: " + message.time_stamp+"\n");

                        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageQueueSorter >> sending to Telnet message [IP Address]: [" + message.internet_address + "].");

                        writer.write("[IP Address]: " + message.internet_address+"\n");

                        CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageQueueSorter >> sending to Telnet message [Socket]: [" + message.socket + "].");

                        writer.write("[Socket]: " + message.socket.toString()+"\n");

                        writer.flush();

                        message_queue.remove(message);
                    }
                }
                catch (SocketTimeoutException ste)
                {
                    try
                    {
                        message.socket.close();
                    }
                    catch (Exception e)
                    {
                        Integer size = this.web_express.current_connections.size();

                        EnglishArithemeter meter = new EnglishArithemeter();

                        String conversion = meter.convert(size);

                        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::MessageQueueSorter >> dropped connection ["+message.socket+"] - new connection count ["+conversion+" "+size+"].");
                    }

                    this.web_express.current_connections.remove(message.socket);

                    break;
                }
                catch (IOException e)
                {
                    CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageQueueSorter >> socket connection closed [Socket]: " + message.internet_address + "].");
                }

                try
                {
                    BufferedReader reader = this.web_express.telnet_communication_proxy.reader;

                    if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                    {
                        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(message.socket.getOutputStream()));

                        String line = null;

                        while((line=reader.readLine())!=null)
                        {
                            if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                            {
                                CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageQueueSorter >> received from active Telnet session ["+ WebExpress.REMOTE_SITE+":"+ WebExpress.REMOTE_PORT+"] message ["+line+"].");

                                writer.write(line+"\n");

                                writer.flush();
                            }
                            else
                            {
                                CurrentConnections connections = this.web_express.current_connections;

                                String conversion;

                                Integer size;

                                connections.remove(message.socket);

                                conversion = EnglishArithemeter.convert(connections.size());

                                conversion = conversion.substring(0, 1).toUpperCase();

                                size = EnglishArithemeter.size(connections.current_connections);

                                CommonRails.printSystemComponent(this.hashCode(),"WebExpress::MessageQueueSorter >> dropped connection ["+message.socket+"] - new connection count ["+conversion+" : "+size+"].");

                                break;
                            }
                        }
                    }
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
        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::addMessage >> message queue size before ["+this.getMessageQueueSize()+"].");

        this.web_express.message_queue.add(message);

        CommonRails.printSystemComponent(this.hashCode(), "WebExpress::addMessage >> message queue size after ["+this.getMessageQueueSize()+"].");
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