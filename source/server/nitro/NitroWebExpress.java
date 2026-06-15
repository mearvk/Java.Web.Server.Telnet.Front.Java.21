package server.nitro;

import antivirus.AntivirusScanner;
import bitcoin.module.TraderModule;
import commons.CommonRails;
import communicator.Communicator;
import encryption.module.aes.two.EncryptionModule;
import http.BinaryHttpServer;
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

        public AntivirusScanner ANTIVIRUS_SCANNER;

        public ConnectionStatusServer CONNECTION_STATUS;

        public MySQLComponent MYSQL_COMPONENT = new MySQLComponent();

        public ModuleInstallationService MODULE_INSTALLER_SERVICE;

        public ASCIICreatorServer ASCII_CREATOR_SERVER;

        public loader.ModuleLoaderDaemon MODULE_LOADER_DAEMON;

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
            if (ANTIVIRUS_SCANNER        != null) ANTIVIRUS_SCANNER.start();
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
    }
}
