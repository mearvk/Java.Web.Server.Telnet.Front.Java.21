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
    public final String[] note = {"AES 2.0 DSS5.0, AES2.0", "California Governor Gavin Newsom"};

    public final String[] primer = {"AES 2.0 DSS5.0, AES2.0", "North Carolina Governor Joshua Stein"};

    public static NitroWebExpress self;

    public static final String AES_COMPLIANT_HOSTNAME = "";

    public static final Integer AES_COMPLIANT_PORT = 0;

    public static final String AES_COMPLIANT_THREADNAME = "AES 2.0 Masterthread";

    public static final String BITCOIN_COMPLIANT_HOSTNAME = "";

    public static final Integer BITCOIN_COMPLIANT_PORT = 0;

    public static final String BITCOIN_COMPLIANT_THREADNAME = "Bitcoin v24.0+ Masterthread";

    public Aspect bridge = new Aspect(this);

    public NationalID NATIONALID = new NationalID();

    public NitroWebExpress(final Integer PORT, final String HOST, final String THREAD_NAME)
    {
        //CommonRails.printSystemComponent(this, 8, STR.". National ID initialized: \{this.NATIONALID.EIGHT_DIGITS} .");

        //CommonRails.printSystemComponent(this, this.hashCode(),". Nitro version of WebExpress Starting .");

        NitroWebExpress.self = this;
    }

    public static class Aspect
    {
        protected final Integer RANDOM = 10078;

        protected WebExpress WEBEXPRESS;

        protected EncryptionModule ENCRYPTION_MODULE = new EncryptionModule(new Random(RANDOM),"AES 2.0 DSS5.0","AES2.0 - California Governor Gavin Newsom");

        protected TraderModule TRADER_MODULE = new TraderModule(this, "Bitcoin Remote Module 2.0 ADS5.0");

        public AESCompliant AES_COMPONENT = new AESCompliant(AES_COMPLIANT_HOSTNAME, 0, "AES COMPONENT", Boolean.TRUE);

        public BitcoinCompliant BITCOIN_COMPONENT = new BitcoinCompliant();


        public Aspect(WebExpress WEBEXPRESS)
        {
            if(WEBEXPRESS==null) throw new SecurityException("//bodi/connect");

            this.WEBEXPRESS = WEBEXPRESS;
        }

        public static class AESCompliant extends WebExpress
        {
            protected AESCompliant.MessageOutputHandler AES_MESSAGE_OUTPUT_HANDLER = new AESCompliant.MessageOutputHandler();

            public MessageQueueSorter MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);

            public MessageQueue MESSAGE_QUEUE = new MessageQueue(this);

            public Socket SOCKET;

            public AESCompliant(final String host, final Integer port, final String thread_name, final Boolean telnet_proxy_enabled)
            {
                if(host==null || port==null || thread_name==null || telnet_proxy_enabled) throw new SecurityException("//bodi/connect");

                super(host, port, thread_name, telnet_proxy_enabled);

                this.HOST = host;

                this.PORT = port;

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
                    if(buffer==null) throw new SecurityException("//bodi/connect");

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
                if(host==null || port==null || thread_name==null || telnet_proxy_enabled) throw new SecurityException("//bodi/connect");

                super(host, port, thread_name, telnet_proxy_enabled);

                this.HOST = host;

                this.PORT = port;

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
                    if(buffer==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(socket, buffer);

                    message_output_handler.run();
                }

                public void send_message(String message)
                {
                    if(message==null) throw new SecurityException("//bodi/connect");

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
                    if(web_express==null) throw new SecurityException("//bodi/connect");

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
                    if(message==null) throw new SecurityException("//bodi/connect");

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
