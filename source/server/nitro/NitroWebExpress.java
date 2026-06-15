package server.nitro;

import bitcoin.module.TraderModule;
import commons.CommonRails;
import commons.EnglishArithemeter;
import commons.socket.SocketUtils;
import communicator.Communicator;
import connections.CurrentConnections;
import database.N21Store;
import encryption.module.aes.two.EncryptionModule;
import exceptions.ExceptionHandler;
import http.BinaryHttpServer;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import national.NationalID;
import server.nitro.modules.*;
import server.webexpress.WebExpress;
import weather.WeatherServer;
import whiteauditor.WhiteAuditorTasking;

import java.io.*;
import java.net.*;
import java.nio.file.Path;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

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

        public AESCompliant AES_COMPONENT;

        public BitcoinCompliant BITCOIN_COMPONENT;

        public RSACompliant RSA_COMPONENT;

        public DSACompliant DSA_COMPONENT;

        public ConnectionStatusServer CONNECTION_STATUS;

        public MySQLComponent MYSQL_COMPONENT = new MySQLComponent();

        public ModuleInstallationService MODULE_INSTALLER_SERVICE;

        public ASCIICreatorServer ASCII_CREATOR_SERVER;

        public ModuleInstallationService MODULE_LOADER_DAEMON;

        public Communicator COMMUNICATOR;

        public BinaryHttpServer BINARY_HTTP_SERVER;

        public WeatherServer WEATHER_SERVER;

        public WhiteAuditorTasking WHITE_AUDITOR_TASKING;

        public void start()
        {
            if (RSA_COMPONENT            != null) RSA_COMPONENT.start();
            if (DSA_COMPONENT            != null) DSA_COMPONENT.start();
            if (CONNECTION_STATUS        != null) CONNECTION_STATUS.start();
            if (MODULE_INSTALLER_SERVICE != null) MODULE_INSTALLER_SERVICE.start();
            if (ASCII_CREATOR_SERVER     != null) ASCII_CREATOR_SERVER.start();
            if (MODULE_LOADER_DAEMON     != null) MODULE_LOADER_DAEMON.start();
            if (COMMUNICATOR             != null) COMMUNICATOR.start();
            if (BINARY_HTTP_SERVER       != null) BINARY_HTTP_SERVER.start();
            if (WEATHER_SERVER           != null) WEATHER_SERVER.start();
            //if (ENCRYPTION_MODULE        != null) ENCRYPTION_MODULE.start();
            //if (TRADER_MODULE            != null) TRADER_MODULE.start();
            if (WHITE_AUDITOR_TASKING    != null) WHITE_AUDITOR_TASKING.start();
            if (NitroWebExpress.SELF     != null) NitroWebExpress.SELF.start();
        }

        public Aspect(final WebExpress WEBEXPRESS)
        {
            if(WEBEXPRESS==null) throw new SecurityException("//bodi/connect");

            this.WEBEXPRESS = WEBEXPRESS;

            this.WHITE_AUDITOR_TASKING = new whiteauditor.WhiteAuditorTasking(NitroWebExpress.WEBEXPRESS_COMPLIANT_HOSTNAME);
        }

        public static class InstalledModule
        {
            public final String         NAME;
            public final Path           SOURCE;
            public final URLClassLoader LOADER;
            public final long           INSTALLED_AT = System.currentTimeMillis();

            public InstalledModule(final String NAME, final Path SOURCE, final URLClassLoader LOADER)
            {
                this.NAME   = NAME;

                this.SOURCE = SOURCE;

                this.LOADER = LOADER;
            }
        }

        public static class ModuleRegistry
        {
            private static final ConcurrentHashMap<String, InstalledModule> MODULES = new ConcurrentHashMap<>();

            public static void register(final InstalledModule M)
            {
                MODULES.put(M.NAME, M);

                CommonRails.printSystemComponent(M, M.hashCode(), ". ModuleRegistry registered module [" + M.NAME + "] .");
            }

            public static boolean unload(final String NAME)
            {
                InstalledModule m = MODULES.remove(NAME);

                if (m == null) return false;

                try
                {
                    m.LOADER.close();
                }
                catch (Exception ignored)
                {
                    ignored.printStackTrace(System.err);
                }

                CommonRails.printSystemComponent(m, m.hashCode(), ". ModuleRegistry unloaded module [" + NAME + "] .");

                return true;
            }

            public static InstalledModule get(final String NAME) { return MODULES.get(NAME); }

            public static ConcurrentHashMap<String, InstalledModule> all() { return MODULES; }
        }



        // ── ASCIICreatorServer ────────────────────────────────────────────────



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

                public void send_message(final StringBuffer BUFFER)
                {
                    if(BUFFER==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, BUFFER);

                    message_output_handler.run();
                }

                public void send_message(final String MESSAGE)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, MESSAGE);

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

            public BitcoinCompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
            {
                if(HOST==null || PORT==null || THREAD_NAME==null || TELNET_PROXY_ENABLED==null) throw new SecurityException("//bodi/connect");

                super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

                this.HOST = HOST;

                this.PORT = PORT;

                this.setName(THREAD_NAME);
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

                public void send_message(final StringBuffer BUFFER)
                {
                    if(BUFFER==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, BUFFER);

                    message_output_handler.run();
                }

                public void send_message(final String MESSAGE)
                {
                    if(MESSAGE==null) throw new SecurityException("//bodi/connect");

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
                    if(WEB_EXPRESS==null) throw new SecurityException("//bodi/connect");

                    this.WEB_EXPRESS = WEB_EXPRESS;

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
                    if(MESSAGE==null) throw new SecurityException("//bodi/connect");

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
    }
}
