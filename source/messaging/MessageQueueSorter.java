package messaging;

import commons.CommonRails;
import commons.EnglishArithemeter;
import connections.CurrentConnections;
import server.nitro.WebExpress;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.SocketTimeoutException;

public class MessageQueueSorter extends Thread
{
    protected String hash = "0xDA717018470E213F";

    protected WebExpress web_express;

    public MessageQueueSorter(WebExpress web_express)
    {
        this.web_express = web_express;

        this.setName("MessageQueueSorter");
    }

    @Override
    public void run()
    {
        CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress::MessageQueueSorter starts .");

        for(;;)
        {
            MessageQueue message_queue = this.web_express.MESSAGE_QUEUE;

            for(int i = 0; i<message_queue.MESSAGES.size(); i++)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter reports message queue has size of "+message_queue.MESSAGES.size()+" .");

                CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter received message from connection "+message_queue.MESSAGES.get(i).socket+" "+message_queue.MESSAGES.get(i).MESSAGE_BUFFER +" .");

                MessageQueue.Message message = message_queue.MESSAGES.remove(i);

                try
                {
                    if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                    {
                        BufferedWriter writer = this.web_express.TELNET_COMMUNICATION_PROXY.writer;

                        CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress::MessageQueueSorter sending to Telnet message Message: " + message.MESSAGE_BUFFER + " .");

                        writer.write("Message: "+message.MESSAGE_BUFFER +"\n");

                        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter sending to Telnet message Date: " + message.time_stamp + " .");

                        writer.write("[Date]: " + message.time_stamp+"\n");

                        CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress::MessageQueueSorter sending to Telnet message IP Address: " + message.internet_address + " .");

                        writer.write("[IP Address]: " + message.internet_address+"\n");

                        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter >> sending to Telnet message Socket: " + message.socket + " .");

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
                        CurrentConnections connections = this.web_express.current_connections;

                        connections.remove(message.connection);

                        EnglishArithemeter arithemeter = new EnglishArithemeter(connections.size());

                        CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress::MessageQueueSorter >> dropped connection "+message.socket+" - new connection count "+arithemeter.result.arithemetic +" : "+arithemeter.result.numeral +" .");
                    }

                    this.web_express.current_connections.remove(message.socket);

                    break;
                }
                catch (IOException e)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter socket connection closed Socket: " + message.internet_address + " .");
                }

                try
                {
                    BufferedReader reader = this.web_express.TELNET_COMMUNICATION_PROXY.reader;

                    if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                    {
                        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(message.socket.getOutputStream()));

                        String line = null;

                        while((line=reader.readLine())!=null)
                        {
                            if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                            {
                                CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter received from active Telnet session "+ WebExpress.REMOTE_SITE+":"+ WebExpress.REMOTE_PORT+" message "+line+" .");

                                writer.write(line+"\n");

                                writer.flush();
                            }
                            else
                            {
                                CurrentConnections connections = this.web_express.current_connections;

                                connections.remove(message.connection);

                                EnglishArithemeter arithemeter = new EnglishArithemeter(connections.size());

                                CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter dropped connection "+message.socket+" - new connection count "+arithemeter.result.arithemetic+" : "+arithemeter.result.numeral+" .");

                                break;
                            }
                        }
                    }
                }
                catch (Exception e)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter >> dropped connection "+message.socket+" .");
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
        CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress::addMessage message queue size before "+this.getMessageQueueSize()+" .");

        this.web_express.MESSAGE_QUEUE.add(message);

        CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress::addMessage message queue size after "+this.getMessageQueueSize()+" .");
    }

    public synchronized MessageQueue getMessageQueue()
    {
        return this.web_express.MESSAGE_QUEUE;
    }

    public synchronized Integer getMessageQueueSize()
    {
        return this.web_express.MESSAGE_QUEUE.MESSAGES.size();
    }
}