package server.nitro;

import bitcoin.module.TraderModule;
import commons.CommonRails;
import commons.EnglishArithemeter;
import connections.CurrentConnections;
import encryption.module.aes.two.EncryptionModule;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import national.NationalID;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.util.Random;

public class NitroWebExpress extends WebExpress
{
    public String[] note = {"AES 2.0 DSS5.0, AES2.0", "California Governor Gavin Newsom"};

    public String[] primer = {"AES 2.0 DSS5.0, AES2.0", "North Carolina Governor Joshua Stein"};

    public static final String AES_COMPLIANT_HOSTNAME = "";

    public static final Integer AES_COMPLIANT_PORT = 0;

    public static final String AES_COMPLIANT_THREADNAME = "AES 2.0 Masterthread";

    public static final String BITCOIN_COMPLIANT_HOSTNAME = "";

    public static final Integer BITCOIN_COMPLIANT_PORT = 0;

    public static final String BITCOIN_COMPLIANT_THREADNAME = "Bitcoin v24.0+ Masterthread";

    public Aspect bridge = new Aspect(this);

    public NationalID id = new NationalID();

    public NitroWebExpress()
    {
        CommonRails.printSystemComponent(this, this.id.hashCode(), ". National ID initialized: "+this.id.eight_digits +" .");

        CommonRails.printSystemComponent(this, this.hashCode(),". Nitro version of WebExpress Starting .");
    }

    public static class Aspect
    {
        protected final Integer random = 10078;

        protected WebExpress web_express;

        protected EncryptionModule encryption_module = new EncryptionModule(new Random(random),"AES 2.0 DSS5.0","AES2.0 - California Governor Gavin Newsom");

        protected TraderModule trader_module = new TraderModule(this, "Bitcoin Remote Module 2.0 ADS5.0");

        public AESCompliant aescompliance = new AESCompliant("", 0, "", true);

        public BitcoinCompliant bitcoincompliance = new BitcoinCompliant();

        public Aspect(WebExpress web_express)
        {
            this.web_express = web_express;
        }

        public static class AESCompliant extends WebExpress
        {
            protected AESCompliant.MessageOutputHandler aes_message_output_handler = new AESCompliant.MessageOutputHandler();

            public MessageQueueSorter message_queue_sorter = new MessageQueueSorter(this);

            public MessageQueue message_queue = new MessageQueue(this);

            public Socket socket;

            public AESCompliant(final String host, final Integer port, final String thread_name, final Boolean telnet_proxy_enabled)
            {
                super(host, port, thread_name, telnet_proxy_enabled);

                this.host = host;

                this.port = port;

                this.setName(thread_name);
            }

            public AESCompliant()
            {

            }

            protected static class MessageOutputRecord
            {
                public MessageOutputRecord()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "AESCompliant::MessageOutputRecord loads.");
                }
            }

            protected static class MessageOutputHandler
            {
                public Socket socket;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". AESCompliant::MessageOutputHandler starts .");
                }

                public void send_message(StringBuffer buffer)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(socket, buffer);

                    message_output_handler.run();
                }

                public void send_message(String message)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(socket, message);

                    message_output_handler.run();
                }
            }
        }

        public static class BitcoinCompliant extends WebExpress
        {
            protected BitcoinCompliant.MessageOutputHandler bitcoin_message_output_handler = new BitcoinCompliant.MessageOutputHandler();

            public messaging.MessageQueueSorter message_queue_sorter = new messaging.MessageQueueSorter(this);

            public MessageQueue message_queue = new MessageQueue(this);

            public Socket socket;

            public BitcoinCompliant(final String host, final Integer port, final String thread_name, final Boolean telnet_proxy_enabled)
            {
                super(host, port, thread_name, telnet_proxy_enabled);

                this.host = host;

                this.port = port;

                this.setName(thread_name);
            }

            public BitcoinCompliant()
            {
                CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant starts .");
            }

            protected static class MessageOutputRecord
            {
                public MessageOutputRecord()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant::MessageOutputRecord loads .");
                }
            }

            protected static class MessageOutputHandler
            {
                public Socket socket;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant::MessageOutputHandler starts .");
                }

                public void send_message(StringBuffer buffer)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(socket, buffer);

                    message_output_handler.run();
                }

                public void send_message(String message)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(socket, message);

                    message_output_handler.run();
                }
            }

            public static class MessageQueueSorter extends Thread
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
                        MessageQueue message_queue = this.web_express.message_queue;

                        for(int i=0; i<message_queue.messages.size(); i++)
                        {
                            CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter reports message queue has size of "+message_queue.messages.size()+" .");

                            CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress::MessageQueueSorter received message from connection "+message_queue.messages.get(i).socket+" "+message_queue.messages.get(i).message_buffer+" .");

                            MessageQueue.Message message = message_queue.messages.remove(i);

                            try
                            {
                                if(CommonRails.SocketUtils.isSocketConnected(message.socket))
                                {
                                    BufferedWriter writer = this.web_express.telnet_communication_proxy.writer;

                                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress::MessageQueueSorter sending to Telnet message Message: " + message.message_buffer + " .");

                                    writer.write("Message: "+message.message_buffer+"\n");

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
                                BufferedReader reader = this.web_express.telnet_communication_proxy.reader;

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

                    this.web_express.message_queue.add(message);

                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress::addMessage message queue size after "+this.getMessageQueueSize()+" .");
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
        }
    }
}
