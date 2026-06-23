package server.nitro.modules;

import commons.CommonRails;
import commons.formatting.LineFormatter;
import commons.printing.StartsCanonical;
import commons.socket.SocketUtils;
import commons.transition.english.EnglishArithemeter;
import connections.CurrentConnections;
import exceptions.ExceptionHandler;
import messaging.MessageQueue;
import server.webexpress.WebExpress;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.net.SocketTimeoutException;

public class BitcoinCompliant extends WebExpress
{
    protected BitcoinCompliant.MessageOutputHandler bitcoin_message_output_handler = new BitcoinCompliant.MessageOutputHandler();

    public messaging.MessageQueueSorter message_queue_sorter = new messaging.MessageQueueSorter(this);

    public MessageQueue message_queue = new MessageQueue(this);

    public Socket socket;

    public BitcoinCompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
    {
        if(HOST==null || PORT==null || THREAD_NAME==null || TELNET_PROXY_ENABLED==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);

        super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

        this.HOST = HOST;

        this.PORT = PORT;

        this.setName(THREAD_NAME);
    }

    public BitcoinCompliant()
    {
        CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant " + LineFormatter.starts() + " .");
    }

    protected static class MessageOutputRecord
    {
        public MessageOutputRecord()
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant MessageOutputRecord loads .");
        }
    }

    protected static class MessageOutputHandler
    {
        public Socket SOCKET;

        public MessageOutputHandler()
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant MessageOutputHandler " + LineFormatter.starts() + " .");
        }

        public void send_message(final StringBuffer BUFFER)
        {
            if(BUFFER==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);

            messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, BUFFER);

            message_output_handler.run();
        }

        public void send_message(final String MESSAGE)
        {
            if(MESSAGE==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);

            messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, MESSAGE);

            message_output_handler.run();
        }
    }

    public static class MessageQueueSorter extends Thread
    {
        protected String HASH = "0xDA717018470E213F";

        protected WebExpress WEB_EXPRESS;

        public MessageQueueSorter(final WebExpress WEB_EXPRESS)
        {
            if(WEB_EXPRESS==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);

            this.WEB_EXPRESS = WEB_EXPRESS;

            this.setName("MessageQueueSorter");
        }

        @Override
        public void run()
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter " + LineFormatter.starts() + " .");

            while(true)
            {
                MessageQueue MESSAGE_QUEUE = this.WEB_EXPRESS.MESSAGE_QUEUE;

                try
                {
                    synchronized (MESSAGE_QUEUE)
                    {
                        while (MESSAGE_QUEUE.MESSAGES.size() == 0)
                        {
                            try { MESSAGE_QUEUE.wait(); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); return; }
                        }

                        while (MESSAGE_QUEUE.MESSAGES.size() > 0)
                        {
                            MessageQueue.Message message = MESSAGE_QUEUE.MESSAGES.remove(0);

                            try
                            {
                                if(SocketUtils.isConnected(message.SOCKET))
                                {
                                    BufferedWriter writer = this.WEB_EXPRESS.TELNET_COMMUNICATION_PROXY.writer;

                                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter sending to Telnet message Message: " + message.MESSAGE_BUFFER + " .");

                                    writer.write("Message: "+message.MESSAGE_BUFFER +"\n");

                                    CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter sending to Telnet message Date: " + message.TIME_STAMP + " .");

                                    writer.write("[Date]: " + message.TIME_STAMP +"\n");

                                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter sending to Telnet message IP Address: " + message.INTERNET_ADDRESS + " .");

                                    writer.write("[IP Address]: " + message.INTERNET_ADDRESS +"\n");

                                    CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter >> sending to Telnet message Socket: " + message.SOCKET + " .");

                                    writer.write("[Socket]: " + message.SOCKET.toString()+"\n");

                                    writer.flush();

                                    MESSAGE_QUEUE.remove(message);
                                }
                            }
                            catch (SocketTimeoutException ste)
                            {
                                try
                                {
                                    message.SOCKET.close();
                                }
                                catch (Exception e)
                                {
                                    ExceptionHandler.dispatch(e);

                                    CurrentConnections connections = this.WEB_EXPRESS.CURRENT_CONNECTIONS;

                                    connections.remove(message.CONNECTION);

                                    EnglishArithemeter arithemeter = new EnglishArithemeter(connections.size());

                                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter >> dropped connection "+message.SOCKET +" - new connection count "+arithemeter.result.arithemetic +" : "+arithemeter.result.numeral +" .");
                                }

                                this.WEB_EXPRESS.CURRENT_CONNECTIONS.remove(message.SOCKET);

                                break;
                            }
                            catch (IOException e)
                            {
                                ExceptionHandler.dispatch(e);

                                CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter socket connection closed Socket: " + message.INTERNET_ADDRESS + " .");
                            }

                            try
                            {
                                BufferedReader reader = this.WEB_EXPRESS.TELNET_COMMUNICATION_PROXY.reader;

                                if(SocketUtils.isConnected(message.SOCKET))
                                {
                                    BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(message.SOCKET.getOutputStream()));

                                    String line = null;

                                    while((line=reader.readLine())!=null)
                                    {
                                        if(SocketUtils.isConnected(message.SOCKET))
                                        {
                                            CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter received from active Telnet session "+ WebExpress.REMOTE_SITE+":"+ WebExpress.REMOTE_PORT+" message "+line+" .");

                                            writer.write(line+"\n");

                                            writer.flush();
                                        }
                                        else
                                        {
                                            CurrentConnections connections = this.WEB_EXPRESS.CURRENT_CONNECTIONS;

                                            connections.remove(message.CONNECTION);

                                            EnglishArithemeter arithemeter = new EnglishArithemeter(connections.size());

                                            CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter dropped connection "+message.SOCKET +" - new connection count "+arithemeter.result.arithemetic+" : "+arithemeter.result.numeral+" .");

                                            break;
                                        }
                                    }
                                }
                            }
                            catch (Exception e)
                            {
                                ExceptionHandler.dispatch(e);

                                CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter >> dropped connection "+message.SOCKET +" .");
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
            if(MESSAGE==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);

            CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress addMessage MESSAGE queue size before "+this.getMessageQueueSize()+" .");

            this.WEB_EXPRESS.MESSAGE_QUEUE.add(MESSAGE);

            CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress addMessage MESSAGE queue size after "+this.getMessageQueueSize()+" .");
        }

        public synchronized MessageQueue getMessageQueue()
        {
            return this.WEB_EXPRESS.MESSAGE_QUEUE;
        }

        public synchronized Integer getMessageQueueSize()
        {
            return this.WEB_EXPRESS.MESSAGE_QUEUE.MESSAGES.size();
        }
    }
}
