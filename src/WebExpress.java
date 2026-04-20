/**
 * @author Max Rupplin
 * @date April 18 2507-2671
 *
 * @us.governor Caesar Bernini
 */

import java.io.*;
import java.util.Date;

public class WebExpress extends BaseServer
{
    protected static final String[] TELNET_PROXY_SERVER_ARGS = new String[]{"telnet", "tacobell.phd", "80"};

    protected TelnetInstaller telnet_installer;

    protected TelnetCommunicationProxy telnet_communicator;

    protected MessageQueueSorter message_queue_sorter;

    public WebExpress(final String host, final Integer port, final Boolean telnet_proxy)
    {
        super(host, port);

        if(telnet_proxy)
        {
            System.out.println("WebExpress >> starts ["+new Date()+"] ["+host+":"+port+"] [Telnet Proxy Enabled]");

            this.telnet_installer = new TelnetInstaller(this);

            this.telnet_communicator = new TelnetCommunicationProxy();
        }
        else
        {
            System.out.println("WebExpress >> starts ["+new Date()+"] ["+host +":"+port+"]");
        }

        System.out.println("WebExpress::CommonRail >> starts ["+new Date()+"].");

        this.message_queue_sorter = new MessageQueueSorter(this);

        this.message_queue_sorter.start();
    }

    public static class TelnetCommunicationProxy
    {
        public TelnetCommunicationProxy()
        {
            System.out.println("WebExpress::Telnet::Communicator >> starts ["+new Date()+"].");
        }

        protected ProcessBuilder process_builder = new ProcessBuilder();

        protected Process process;

        protected BufferedWriter writer;

        protected BufferedReader reader;
    }

    public static class TelnetInstaller
    {
        protected WebExpress web_express;

        public TelnetInstaller(WebExpress web_express)
        {
            System.out.println("WebExpress::Telnet::Installer >> starts ["+new Date()+"].");

            try
            {
                this.web_express = web_express;

                this.web_express.telnet_communicator.process_builder.command(TELNET_PROXY_SERVER_ARGS);

                this.web_express.telnet_communicator.process = this.web_express.telnet_communicator.process_builder.start();

                this.web_express.telnet_communicator.reader = new BufferedReader(new InputStreamReader(this.web_express.telnet_communicator.process.getInputStream()));

                this.web_express.telnet_communicator.writer = new BufferedWriter(new OutputStreamWriter(this.web_express.telnet_communicator.process.getOutputStream()));

                CommonRails._long("TelnetCommunicator::Close::Hook", web_express,1000);
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }

    public static class MessageQueueSorter extends Thread
    {
        protected WebExpress web_express;

        public MessageQueueSorter(WebExpress web_express)
        {
            this.web_express = web_express;
        }

        @Override
        public void run()
        {
            System.out.println("WebExpress::MessageQueueSorter >> starts ["+new Date()+"].");

            for(;;)
            {
                MessageQueue message_queue = this.web_express.getMessageQueue();

                System.out.println("WebExpress::MessageQueueSorter >> reports message queue has size of ["+message_queue.messages.size()+"].");

                for(int i=0; i<message_queue.messages.size(); i++)
                {
                    System.out.println("WebExpress::MessageQueueSorter >> received message.");

                    MessageQueue.Message message = message_queue.messages.remove(i);

                    try
                    {
                        if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                        {
                            BufferedWriter writer = this.web_express.telnet_communicator.writer;

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [Message]: " + message.message_buffer + "].");

                            writer.write("[Message]: " + message.message_buffer);

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [Date]: " + message.time_stamp + "].");

                            writer.write("[Date]: " + message.time_stamp);

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [IP Address]: " + message.internet_address + "].");

                            writer.write("[IP Address]: " + message.internet_address);

                            System.out.println("WebExpress::MessageQueueSorter >> sending to Telnet message [Socket]: " + message.internet_address + "].");

                            writer.write("[Socket]: " + message.socket);

                            writer.flush();
                        }
                    }
                    catch (NullPointerException npe)
                    {
                        //this.web_express.current_connections.remove(message.socket);

                        System.out.println("WebExpress >> dropped connection ["+message.socket+"] - new connection count ["+(this.web_express.current_connections.size())+"].");

                        break;
                    }
                    catch (IOException e)
                    {
                        throw new RuntimeException(e);
                    }

                    try
                    {
                        BufferedReader reader = this.web_express.telnet_communicator.reader;

                        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(message.socket.getOutputStream()));

                        String line = null;

                        while((line=reader.readLine())!=null)
                        {
                            if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                            {
                                System.out.println("MessageQueueSorter >> replying with Proxy message ["+line+"].");

                                writer.write(line);

                                writer.flush();
                            }
                            else
                            {
                                //this.web_express.current_connections.remove(message.socket);

                                System.out.println("WebExpress >> dropped connection ["+message.socket+"] - new connection count ["+(this.web_express.current_connections.size()+1)+"].");

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
    }
}
