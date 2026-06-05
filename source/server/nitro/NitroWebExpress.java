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
    public final String[] NOTE = new String[]{"AES 2.0 DSS5.0, AES2.0", "California Governor Gavin Newsom"};

    public final String[] PRIMER = new String[]{"AES 2.0 DSS5.0, AES2.0", "North Carolina Governor Joshua Stein"};

    public static NitroWebExpress SELF;

    public static Integer BASE_PORT = 49152;

    public static final Integer AES_COMPLIANT_PORT = 5512;

    public static final Integer BITCOIN_COMPLIANT_PORT = 6682;

    public static final String AES_COMPLIANT_THREADNAME = "AES 2.0 Masterthread";

    public static final String BITCOIN_COMPLIANT_THREADNAME = "Bitcoin v24.0+ Masterthread";

    public static String WEBEXPRESS_COMPLIANT_THREADNAME = "WebExpress v24.0+ Masterthread";


    public static String WEBEXPRESS_COMPLIANT_HOSTNAME = "localhost";

    public static final String BITCOIN_COMPLIANT_HOSTNAME = "localhost";

    public static final String AES_COMPLIANT_HOSTNAME = "localhost";

    public Aspect BRIDGE = new Aspect(this);

    public NationalID NATIONALID = new NationalID();

    public NitroWebExpress(final Integer PORT, final String HOST, final String THREAD_NAME)
    {
        // Initialize BaseServer/WebExpress so SERVER_SOCKET is created and run() will not NPE
        super(HOST, PORT, THREAD_NAME, Boolean.TRUE);

        CommonRails.printSystemComponent(this, 8, ". National ID initialized: "+this.NATIONALID.EIGHT_DIGITS+" .");

        CommonRails.printSystemComponent(this, this.hashCode(),". Nitro version of WebExpress Starting .");

        NitroWebExpress.BASE_PORT = PORT;

        NitroWebExpress.WEBEXPRESS_COMPLIANT_HOSTNAME = HOST;

        NitroWebExpress.WEBEXPRESS_COMPLIANT_THREADNAME = THREAD_NAME;

        NitroWebExpress.SELF = this;
    }

    public static class Aspect
    {
        protected final Integer RANDOM = 10078;

        protected WebExpress WEBEXPRESS;

        protected EncryptionModule ENCRYPTION_MODULE = new EncryptionModule(new Random(RANDOM),"AES 2.0 DSS5.0","AES2.0 - California Governor Gavin Newsom");

        protected TraderModule TRADER_MODULE = new TraderModule(this, "Bitcoin Remote Module 2.0 ADS5.0");

        // Do not eagerly instantiate components that bind sockets; create on-demand to avoid accidental double binds
        public AESCompliant AES_COMPONENT;

        public BitcoinCompliant BITCOIN_COMPONENT;


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

            public AESCompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
            {
                if(HOST==null || PORT==null || THREAD_NAME==null || TELNET_PROXY_ENABLED==null) throw new SecurityException("//bodi/connect");

                super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

                this.HOST = HOST;

                this.PORT = PORT;

                this.setName(THREAD_NAME);
            }

            public AESCompliant()
            {

            }

            protected static class MessageOutputRecord
            {
                public MessageOutputRecord()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". AESCompliant MessageOutputRecord loads .");
                }
            }

            protected static class MessageOutputHandler
            {
                public Socket SOCKET;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". AESCompliant MessageOutputHandler starts .");
                }

                public void send_message(StringBuffer buffer)
                {
                    if(buffer==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, buffer);

                    message_output_handler.run();
                }

                public void send_message(String message)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, message);

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
                if(host==null || port==null || thread_name==null || telnet_proxy_enabled==null) throw new SecurityException("//bodi/connect");

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
                    CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant MessageOutputRecord loads .");
                }
            }

            protected static class MessageOutputHandler
            {
                public Socket SOCKET;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant MessageOutputHandler starts .");
                }

                public void send_message(StringBuffer buffer)
                {
                    if(buffer==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, buffer);

                    message_output_handler.run();
                }

                public void send_message(String message)
                {
                    if(message==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, message);

                    message_output_handler.run();
                }
            }

            public static class MessageQueueSorter extends Thread
            {
                protected String HASH = "0xDA717018470E213F";

                protected WebExpress WEB_EXPRESS;

                public MessageQueueSorter(WebExpress web_express)
                {
                    if(web_express==null) throw new SecurityException("//bodi/connect");

                    this.WEB_EXPRESS = web_express;

                    this.setName("MessageQueueSorter");
                }

                @Override
                public void run()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter starts .");

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
                                        if(CommonRails.SocketUtils.isSocketConnected(message.SOCKET))
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
                                        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter socket connection closed Socket: " + message.INTERNET_ADDRESS + " .");
                                    }

                                    try
                                    {
                                        BufferedReader reader = this.WEB_EXPRESS.TELNET_COMMUNICATION_PROXY.reader;

                                        if(CommonRails.SocketUtils.isSocketConnected(message.SOCKET))
                                        {
                                            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(message.SOCKET.getOutputStream()));

                                            String line = null;

                                            while((line=reader.readLine())!=null)
                                            {
                                                if(CommonRails.SocketUtils.isSocketConnected(message.SOCKET))
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
                                        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter >> dropped connection "+message.SOCKET +" .");
                                    }
                                }
                            }
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

                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress addMessage message queue size before "+this.getMessageQueueSize()+" .");

                    this.WEB_EXPRESS.MESSAGE_QUEUE.add(message);

                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress addMessage message queue size after "+this.getMessageQueueSize()+" .");
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
    }
}
