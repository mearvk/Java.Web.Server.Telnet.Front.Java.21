package server.nitro;

import bitcoin.module.TraderModule;
import commons.CommonRails;
import commons.EnglishArithemeter;
import connections.CurrentConnections;
import exceptions.ExceptionHandler;
import encryption.module.aes.two.EncryptionModule;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import national.NationalID;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
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

        public ConnectionStatusServer CONNECTION_STATUS;

        public MySQLComponent MYSQL_COMPONENT = new MySQLComponent();

        public ModuleInstallationService MODULE_INSTALLER_SERVICE;

        /** Start CONNECTION_STATUS and NitroWebExpress.SELF together. */
        public void start()
        {
            if (CONNECTION_STATUS    != null) CONNECTION_STATUS.start();
            if (MODULE_INSTALLER_SERVICE != null) MODULE_INSTALLER_SERVICE.start();
            if (NitroWebExpress.SELF != null) NitroWebExpress.SELF.start();
        }

        public static class ConnectionStatusServer extends Thread
        {
            public static final int STATUS_PORT = 49155;

            private final CurrentConnections WATCHED;
            private final int WATCHEDPORT;
            private final String HOST;
            private ServerSocket serverSocket;
            private final long startTime = System.currentTimeMillis();

            public ConnectionStatusServer(final String HOST, final CurrentConnections WATCHED, final int WATCHEDPORT)
            {
                if (HOST == null || WATCHED == null) throw new SecurityException("//bodi/connect");
                this.HOST = HOST;
                this.WATCHED = WATCHED;
                this.WATCHEDPORT = WATCHEDPORT;
                this.setName("ConnectionStatusServer");
                this.setDaemon(true);
            }

            @Override
            public void run()
            {
                try
                {
                    serverSocket = new ServerSocket(STATUS_PORT, 256, InetAddress.getByName(HOST));
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ConnectionStatusServer listening on port " + STATUS_PORT + " .");
                    while (!Thread.currentThread().isInterrupted())
                    {
                        Socket client = serverSocket.accept();
                        Thread responder = new Thread(() -> respond(client));
                        responder.setDaemon(true);
                        responder.start();
                    }
                }
                catch (Exception e) { ExceptionHandler.dispatch(e); e.printStackTrace(System.err); }
            }

            private void respond(final Socket CLIENT)
            {
                try
                {
                    int count = WATCHED.size();
                    String remoteIp  = CLIENT.getInetAddress().getHostAddress();
                    String geoLine   = fetchGeo(remoteIp);
                    String localTime = LocalTime.now().format(DateTimeFormatter.ofPattern("h:mm a"));
                    long uptimeSecs  = (System.currentTimeMillis() - startTime) / 1000;
                    String uptime    = (uptimeSecs / 3600) + "hrs " + ((uptimeSecs % 3600) / 60) + "mins " + (uptimeSecs % 60) + "secs";
                    Runtime rt       = Runtime.getRuntime();
                    long totalMB     = rt.totalMemory() / (1024 * 1024);
                    long usedMB      = (rt.totalMemory() - rt.freeMemory()) / (1024 * 1024);

                    String[] geoParts = geoLine.split(", ", 2);
                    db.N21Store.storeGeo(remoteIp, geoParts.length > 0 ? geoParts[0] : "", geoParts.length > 1 ? geoParts[1] : "");
                    db.N21Store.storeStatusSnapshot(count, uptimeSecs, totalMB, usedMB);

                    String report =
                        "╔══════════════════════════════════════════════╗\n" +
                        "║   National JDK Finance Engine  v2811.1 v12.1 ║\n" +
                        "╚══════════════════════════════════════════════╝\n" +
                        "Remote IP:           " + remoteIp  + "\n" +
                        "Geo Location:        " + geoLine   + "\n" +
                        "Local Server Time:   " + localTime + "\n" +
                        "Server Uptime:       " + uptime    + "\n" +
                        "Total Memory:        " + totalMB   + "MB (used: " + usedMB + "MB)\n" +
                        "Current Connections: " + count     + "\n";

                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ConnectionStatusServer >> status query: port=" + WATCHEDPORT + " connections=" + count + " .");

                    BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream()));
                    writer.write(report);
                    writer.flush();
                }
                catch (Exception e) { ExceptionHandler.dispatch(e); }
                finally { try { CLIENT.close(); } catch (Exception ignored) {} }
            }

            private String fetchGeo(final String IP)
            {
                try
                {
                    boolean isPrivate = IP.startsWith("127.") || IP.startsWith("10.")
                        || IP.startsWith("192.168.") || IP.equals("::1") || IP.equals("0:0:0:0:0:0:0:1");
                    HttpURLConnection conn = (HttpURLConnection)
                        new URL("http://IP-api.com/line/" + (isPrivate ? "" : IP) + "?fields=city,country").openConnection();
                    conn.setConnectTimeout(2000);
                    conn.setReadTimeout(2000);
                    try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream())))
                    {
                        String country = br.readLine();
                        String city    = br.readLine();
                        return (city != null ? city : "?") + ", " + (country != null ? country : "?");
                    }
                }
                catch (Exception e) { return "Unknown"; }
            }
        }

        public static class MySQLComponent
        {
            public db.N21Status.Status dbStatus;
            public String oidColor;
            public String statusMsg;

            public MySQLComponent()
            {
                db.N21AuthConfig.get().ensureMysqlRunning();
                this.dbStatus = db.N21Status.check();

                if (dbStatus.jdbcConnected() && dbStatus.n21DbExists())
                {
                    String host     = db.N21Status.dbHost();
                    int    port     = db.N21Status.dbPort();
                    String locality = (host.equals("localhost") || host.equals("127.0.0.1")) ? "Local" : "Remote";
                    this.oidColor  = CommonRails.COLOR_LIME_GREEN;
                    this.statusMsg = ". MySQL N21 Connected — " + locality + " — Port " + port + " .";
                }
                else if (dbStatus.tcpReachable() || dbStatus.pingable())
                {
                    this.oidColor  = CommonRails.COLOR_TANGERINE;
                    this.statusMsg = ". MySQL Unreachable or Auth Failed — XML Fallback Storage Active .";
                }
                else
                {
                    this.oidColor  = CommonRails.COLOR_STANDARD_RED;
                    this.statusMsg = ". MySQL Not Found or Not Running — XML Fallback Storage Active .";
                }
            }

            public void print(final Object OWNER)
            {
                CommonRails.printSystemComponent(OWNER, OWNER.hashCode(), statusMsg, oidColor);
            }
        }


        public Aspect(final WebExpress WEBEXPRESS)
        {
            if(WEBEXPRESS==null) throw new SecurityException("//bodi/connect");

            this.WEBEXPRESS = WEBEXPRESS;
        }

        public static class ModuleInstallationService extends Thread
        {
            public static final int PORT = 49166;

            private final String HOST;

            private ServerSocket SERVER_SOCKET;

            public ModuleInstallationService(final String HOST)
            {
                if (HOST == null) throw new SecurityException("//bodi/connect");
                this.HOST = HOST;
                this.setName("ModuleInstallationService");
                this.setDaemon(true);
            }

            @Override
            public void run()
            {
                try
                {
                    SERVER_SOCKET = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ModuleInstallationService listening on port " + PORT + " .");
                    while (!Thread.currentThread().isInterrupted())
                    {
                        Socket client = SERVER_SOCKET.accept();
                        Thread h = new Thread(() -> handle(client));
                        h.setDaemon(true);
                        h.start();
                    }
                }
                catch (Exception e) { ExceptionHandler.dispatch(e); }
            }

            private void handle(final Socket CLIENT)
            {
                try (
                    BufferedReader in  = new BufferedReader(new InputStreamReader(CLIENT.getInputStream()));
                    BufferedWriter out = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream()))
                ) {
                    writeLine(out, "ModuleInstallationService v1.0 — type 'help' for commands.");
                    String line;
                    while ((line = in.readLine()) != null)
                    {
                        line = line.trim();
                        if (line.isEmpty()) continue;
                        CommonRails.printSystemComponent(this, this.hashCode(),
                            ". ModuleInstallationService command [" + line + "] from " + CLIENT.getInetAddress().getHostAddress() + " .");
                        if (line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")) break;
                        writeLine(out, dispatch(line));
                    }
                }
                catch (Exception e) { ExceptionHandler.dispatch(e); }
                finally { try { CLIENT.close(); } catch (Exception ignored) {} }
            }

            private String dispatch(final String CMD)
            {
                String[] parts = CMD.split("\\s+", 3);
                switch (parts[0].toLowerCase())
                {
                    case "restart":
                        if (parts.length < 2) return "Usage: restart <module>";
                        return restartModule(parts[1]);
                    case "comment":
                        if (parts.length < 3) return "Usage: comment <nationalId> <text>";
                        return addComment(parts[1], parts[2]);
                    case "signatory":
                        if (parts.length < 2) return "Usage: signatory <nationalId>";
                        return grantSignatory(parts[1]);
                    case "help":
                        return HELP;
                    default:
                        return "Unknown command: " + parts[0] + ". Type 'help'.";
                }
            }

            private String restartModule(final String MODULE)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". ModuleInstallationService restarting module [" + MODULE + "] .");
                switch (MODULE.toLowerCase())
                {
                    case "aes": case "bitcoin": case "status": case "national":
                        return "[restart] Module '" + MODULE + "' restart signal sent.";
                    default:
                        return "[restart] Unknown module: " + MODULE;
                }
            }

            private String addComment(final String NATIONAL_ID_STR, final String COMMENT)
            {
                try
                {
                    long id = Long.parseLong(NATIONAL_ID_STR);
                    national.NationalFinanceID r = db.N21Store.loadNationalFinanceID(id);
                    if (r == null) return "[comment] National ID " + id + " not found.";
                    r.suspects = (r.suspects != null && !r.suspects.isEmpty()) ? r.suspects + "; " + COMMENT : COMMENT;
                    db.N21Store.storeNationalFinanceID(r);
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ModuleInstallationService comment added to National ID " + id + " .");
                    return "[comment] Comment added to National ID " + id + ".";
                }
                catch (NumberFormatException e) { return "[comment] Invalid National ID: " + NATIONAL_ID_STR; }
                catch (Exception e) { ExceptionHandler.dispatch(e); return "[comment] Error: " + e.getMessage(); }
            }

            private String grantSignatory(final String NATIONAL_ID_STR)
            {
                try
                {
                    long id = Long.parseLong(NATIONAL_ID_STR);
                    national.NationalFinanceID r = db.N21Store.loadNationalFinanceID(id);
                    if (r == null) return "[signatory] National ID " + id + " not found.";
                    r.trustLevel = 100;
                    db.N21Store.storeNationalFinanceID(r);
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ModuleInstallationService final signatory granted to National ID " + id + " .");
                    return "[signatory] Final signatory rights granted to National ID " + id + ".";
                }
                catch (NumberFormatException e) { return "[signatory] Invalid National ID: " + NATIONAL_ID_STR; }
                catch (Exception e) { ExceptionHandler.dispatch(e); return "[signatory] Error: " + e.getMessage(); }
            }

            private static void writeLine(final BufferedWriter OUT, final String LINE)
            {
                try { OUT.write(LINE + "\r\n"); OUT.flush(); } catch (Exception ignored) {}
            }

            private static final String HELP =
                "Commands:\r\n" +
                "  restart <module>             Restart a named module (aes, bitcoin, status, national)\r\n" +
                "  comment <nationalId> <text>  Append a comment to a user account\r\n" +
                "  signatory <nationalId>       Grant final signatory rights to a user\r\n" +
                "  help                         Show this list\r\n" +
                "  quit                         Close connection";
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
