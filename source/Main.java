import commons.CommonRails;
import calendar.d44.CalendarD44Server;
import communicator.Communicator;
import configuration.NitroWebExpressConfig;
import http.BinaryHttpServer;
import loader.ModuleLoaderDaemon;
import national.NationalDriver;
import server.nitro.NitroWebExpress;
import server.nitro.modules.ConnectionStatusServer;
import server.nitro.modules.MySQLComponent;
import server.nitro.modules.ModuleInstallationService;
import shutdown.ShutdownHooks;
import weather.WeatherServer;

/**
 * @author Max Rupplin
 *
 * @date April 20 2026
 * @us.governor Caesar Bernini
 * @date January 18 2026-1811 ad. governmor ad justices . ad justem
 */
public class Main
{
    protected String hash = "0xDA717018470E213F";

    protected static final Integer WEBEXPRESS_PORT = 49152;

    protected static final Integer AES2_WEBEXPRESS_SERVER_SOCKET = 5512;

    protected static final Integer BITCOIN_WEBEXPRESS_SERVER_SOCKET = 6682;

    protected static final String WEB_EXPRESS_SERVER_THREADNAME = "WEBEXPRESS_TELNET_PROXY_SERVER";

    protected static final String AES2_WEBEXPRESS_SERVER_THREAD_NAME = "WEBEXPRESS_AES2_SERVER";

    protected static final String BITCOIN_WEBEXPRESS_SERVER_THREAD_NAME = "WEBEXPRESS_BITCOIN_SERVER";

    protected static final Integer RSA_WEBEXPRESS_SERVER_SOCKET = NitroWebExpress.Aspect.RSACompliant.DEFAULT_PORT;

    protected static final String RSA_WEBEXPRESS_REMOTE_HOST = "localhost";

    protected static final String RSA_WEBEXPRESS_SERVER_THREAD_NAME = NitroWebExpress.Aspect.RSACompliant.DEFAULT_THREAD;

    protected static final Integer DSA_WEBEXPRESS_SERVER_SOCKET = NitroWebExpress.Aspect.DSACompliant.DEFAULT_PORT;

    protected static final String DSA_WEBEXPRESS_REMOTE_HOST = "localhost";

    protected static final String DSA_WEBEXPRESS_SERVER_THREAD_NAME = NitroWebExpress.Aspect.DSACompliant.DEFAULT_THREAD;

    protected static final String WEBEXPRESS_HOSTNAME = "localhost";

    protected static final String AES_WEBEXPRESS_REMOTE_HOST = "localhost";

    protected static final String BINARY_HTTP_SERVER_HOST = "localhost";

    protected static final String BITCOIN_WEBEXPRESS_REMOTE_HOST = "localhost";

    protected static final Integer CONNECTION_STATUS_SERVER_PORT = ConnectionStatusServer.STATUS_PORT;

    protected static final String CONNECTION_STATUS_SERVER_HOST = "localhost";

    protected static final Integer MODULE_INSTALLER_SERVICE_PORT = ModuleInstallationService.PORT;

    protected static final String MODULE_INSTALLER_SERVICE_HOST = "localhost";

    protected static final Integer ASCII_CREATOR_SERVER_PORT = NitroWebExpress.Aspect.ASCIICreatorServer.PORT;

    protected static final String ASCII_CREATOR_SERVER_HOST = "localhost";

    protected static final Integer MODULE_LOADER_DAEMON_PORT = ModuleLoaderDaemon.PORT;

    protected static final String MODULE_LOADER_DAEMON_HOST = "localhost";

    protected static final Integer COMMUNICATOR_PORT = Communicator.PORT;

    protected static final String COMMUNICATOR_HOST = "localhost";

    protected static final String WEATHER_SERVER_HOST = "localhost";

    protected static final String CALENDAR_D44_HOST = "localhost";

    public static void main(String...args)
    {
        Main main = new Main();
    }

    public Main()
    {
        ShutdownHooks.register();

        // Reassemble PyTorch native JAR from split parts if needed
        java.io.File pytorchJar = new java.io.File("jars/djl/pytorch-native-cpu-2.5.1-linux-x86_64.jar");
        if (!pytorchJar.exists()) {
            try {
                String os = System.getProperty("os.name").toLowerCase();
                ProcessBuilder pb = os.contains("win")
                    ? new ProcessBuilder("cmd", "/c", "jars\\djl\\reassemble-pytorch.bat")
                    : new ProcessBuilder("bash", "jars/djl/reassemble-pytorch.sh");
                pb.inheritIO();
                pb.start().waitFor();
            } catch (Exception e) { e.printStackTrace(); }
        }

        database.N21AuthConfig.get().ensureMysqlRunning();

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". CONFIG loaded — authentication/mysql.auth.xml .",
            commons.color.ColorPalette.COLOR_LIME_GREEN);

        NitroWebExpressConfig.load();

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". CONFIG loaded — configuration/nwe-config.xml .",
            commons.color.ColorPalette.COLOR_LIME_GREEN);

        // MySQL N21 connector — early init so DB is available for all boot operations
        MySQLComponent mysqlComponent = new MySQLComponent();
        mysqlComponent.print(this);
        database.N21XmlFallback.replayFallback();

        //CommonRails.printStartRecipeSpinner();

            System.out.println();
            System.out.println("\033[38;5;74m[ Java National Finance Engine v.28.1.1 Software Processes Starting ]\033[0m");

            System.out.println(". Cryptography/Cryptology AES 2.0 National Cryptolograph Enabled DSS (DeepSonaGraphoSophons) 5.0 .");

            System.out.println(". Bitcoin Lightweight Binary Trader 2.0 Enabled ₿ Running on Bitcoin Open-Source v24.0 or newer .");

            System.out.println(". Operating within and United to National Authority of US United States and State of California in Coalition of and for North Carolina her betterment .");

            System.out.println(". ND51 North Carolina Labors & Standards A5501 ANationals Standards of Cary, NC 2807 .");

            System.out.println(". UNC Chapel Hill medes of 24 Billion PhDs and Granted thereof of Final Marker Rights care of Harvard and Those Universities .");

            System.out.println(". Duke University and A91 Artificial Intelligence Program now in Honors .");

            System.out.println(". Java 9 up to Java 25+ Copyrighted, in Private Held and Hand and Held in Contract & Confidence .\n");

        //CommonRails.International.IranWedding.printSystemComponent(this);

            //System.out.print(CommonRails.COLOR_TANGERINE);
            CommonRails.printSystemComponent(this, this.hashCode(),". Java™ National Finance Engine v.2811.1 v.11.1 .");
            //System.out.print(CommonRails.ANSI_NEAR_RESET_DARK);

        middle.director.DistributionLicense.loadFromDatabase();
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". " + middle.director.DistributionLicense.editionBanner() + " .");
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Creator: Max Rupplin — mearvk@mearvk.us | mearvk@outlook.com .");
        middle.director.PublicKeyVerifier.verify();

        NationalDriver DRIVER = new NationalDriver();

            DRIVER.printOrderedComponents();

            DRIVER.clear();

        NitroWebExpress NITRO = new NitroWebExpress(Main.WEBEXPRESS_PORT, Main.WEBEXPRESS_HOSTNAME, Main.WEB_EXPRESS_SERVER_THREADNAME);

            NITRO.PORT = 49152;

            NITRO.HOST = "localhost";

            NITRO.THREAD_NAME = "United States D500 WebExpress";

            NITRO.TELNET_PROXY_ENABLED = Boolean.TRUE;

            if (NitroWebExpressConfig.isEnabled("AesCompliant"))
                NITRO.BRIDGE.AES_COMPONENT = new NitroWebExpress.Aspect.AESCompliant(AES_WEBEXPRESS_REMOTE_HOST, AES2_WEBEXPRESS_SERVER_SOCKET, AES2_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            if (NitroWebExpressConfig.isEnabled("BitcoinCompliant"))
                NITRO.BRIDGE.BITCOIN_COMPONENT = new NitroWebExpress.Aspect.BitcoinCompliant(BITCOIN_WEBEXPRESS_REMOTE_HOST, BITCOIN_WEBEXPRESS_SERVER_SOCKET, BITCOIN_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            if (NitroWebExpressConfig.isEnabled("RsaCompliant"))
                NITRO.BRIDGE.RSA_COMPONENT = new NitroWebExpress.Aspect.RSACompliant(RSA_WEBEXPRESS_REMOTE_HOST, RSA_WEBEXPRESS_SERVER_SOCKET, RSA_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            if (NitroWebExpressConfig.isEnabled("DsaCompliant"))
                NITRO.BRIDGE.DSA_COMPONENT = new NitroWebExpress.Aspect.DSACompliant(DSA_WEBEXPRESS_REMOTE_HOST, DSA_WEBEXPRESS_SERVER_SOCKET, DSA_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            if (NitroWebExpressConfig.isEnabled("ConnectionStatus"))
                NITRO.BRIDGE.CONNECTION_STATUS = new ConnectionStatusServer(CONNECTION_STATUS_SERVER_HOST, NITRO.CURRENT_CONNECTIONS, NITRO.PORT);

            if (NitroWebExpressConfig.isEnabled("ModuleInstallation"))
                NITRO.BRIDGE.MODULE_INSTALLER_SERVICE = new NitroWebExpress.Aspect.ModuleInstallationService(MODULE_INSTALLER_SERVICE_HOST);

            if (NitroWebExpressConfig.isEnabled("AsciiCreator"))
                NITRO.BRIDGE.ASCII_CREATOR_SERVER = new NitroWebExpress.Aspect.ASCIICreatorServer(ASCII_CREATOR_SERVER_HOST);

            if (NitroWebExpressConfig.isEnabled("ModuleLoaderDaemon"))
                NITRO.BRIDGE.MODULE_LOADER_DAEMON = new ModuleLoaderDaemon(MODULE_LOADER_DAEMON_HOST);

            if (NitroWebExpressConfig.isEnabled("Communicator"))
                NITRO.BRIDGE.COMMUNICATOR = new Communicator(COMMUNICATOR_HOST);

            if (NitroWebExpressConfig.isEnabled("BinaryHttp"))
                NITRO.BRIDGE.BINARY_HTTP_SERVER = new BinaryHttpServer(BINARY_HTTP_SERVER_HOST);

            if (NitroWebExpressConfig.isEnabled("Weather"))
                NITRO.BRIDGE.WEATHER_SERVER = new WeatherServer(WEATHER_SERVER_HOST);

            if (NitroWebExpressConfig.isEnabled("CalendarD44"))
                NITRO.BRIDGE.CALENDAR_D44_SERVER = new CalendarD44Server(CALENDAR_D44_HOST);

            if (NitroWebExpressConfig.isEnabled("JapanSignalServer"))
                new international.radio.japan.JapanSignalServer("localhost");

            if (NitroWebExpressConfig.isEnabled("RussiaSignalServer"))
                new international.radio.russia.RussiaSignalServer("localhost");

            if (NitroWebExpressConfig.isEnabled("MexicoSignalServer"))
                new international.radio.mexico.MexicoSignalServer("localhost");

            if (NitroWebExpressConfig.isEnabled("GreeceInternationalSignalServer"))
                new greece.international.GreeceInternationalSignalServer("localhost");

            if (NitroWebExpressConfig.isEnabled("Strernary"))
                new strernary.StrernaryServer("localhost");

            if (NitroWebExpressConfig.isEnabled("StrernaryDirectory"))
                new strernary.StrernaryDirectoryServer("localhost");

            if (NitroWebExpressConfig.isEnabled("CaliforniaFBI"))
                Thread.ofVirtual().name("CALIFORNIA_FBI_SERVER").start(new source.CaliforniaFBIServer());

            if (NitroWebExpressConfig.isEnabled("CaliforniaCIA"))
                Thread.ofVirtual().name("CALIFORNIA_CIA_SERVER").start(new source.CaliforniaCIAServer());

            if (NitroWebExpressConfig.isEnabled("CaliforniaNSA"))
                Thread.ofVirtual().name("CALIFORNIA_NSA_SERVER").start(new source.CaliforniaNSAServer());

            if (NitroWebExpressConfig.isEnabled("DukeUniversity"))
                Thread.ofVirtual().name("DUKE_UNIVERSITY_SERVER").start(new source.DukeUniversityServer());

            if (NitroWebExpressConfig.isEnabled("StanfordLibrary"))
                Thread.ofVirtual().name("STANFORD_LIBRARY_SERVER").start(new source.StanfordLibraryServer());

            if (NitroWebExpressConfig.isEnabled("DemocraticProFrontNational"))
                new red.Futures.source.ai.server.DemocraticAIServer().start();

            if (NitroWebExpressConfig.isEnabled("BrarnerAlete"))
                new brarner.m.alete.BrarnerAleteModule();

            if (NitroWebExpressConfig.isEnabled("Antivirus"))
                new antivirus.AntivirusScanner().start();

            if (NitroWebExpressConfig.isEnabled("BitcoinWalletIndexer"))
                Thread.ofVirtual().name("BitcoinWalletIndexer").start(() -> new bitcoin.module.BitcoinWalletIndexer().indexAll());
            else
                bitcoin.module.BitcoinWalletIndexer.seedDefaults();

            NITRO.BRIDGE.MYSQL_COMPONENT = mysqlComponent;

            // Gray Port Registry — Installer ID Tech™ (enabled by default)
            new modules.gray.source.GrayPortRegistryServer().start();

            // Gray.85 Crème Port Registry — Installer ID Tech™ (enabled by default)
            new modules.gray.a85.source.Gray85PortRegistryServer().start();

            new lanterna.TerminalMenu().start();

            NITRO.BRIDGE.start();
    }
}
