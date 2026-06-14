import commons.CommonRails;
import communicator.Communicator;
import configuration.NweConfig;
import http.BinaryHttpServer;
import loader.ModuleLoaderDaemon;
import national.NationalDriver;
import server.nitro.NitroWebExpress;
import server.nitro.modules.ConnectionStatusServer;
import server.nitro.modules.MySQLComponent;
import server.nitro.modules.ModuleInstallationService;
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

    public static void main(String...args)
    {
        Main main = new Main();
    }

    public Main()
    {
        shutdown.ShutdownHooks.register();

        configuration.NweConfig.load();

        //CommonRails.printStartRecipeSpinner();

            System.out.println("\033[38;5;74m[ Java National Finance Engine v.28.1.1 Software Processes Starting ]\033[0m");

            System.out.println(". Cryptography/Cryptology AES 2.0 National Cryptolograph Enabled DSS (DeepSonaGraphoSophons) 5.0 .");

            System.out.println(". Bitcoin Lightweight Binary Trader 2.0 Enabled ₿ Running on Bitcoin Open-Source v24.0 or newer .");

            System.out.println(". Operating within and United to National Authority of US United States and State of California in Coalition of and for North Carolina her betterment .");

            System.out.println(". ND51 North Carolina Labors & Standards A5501 ANationals Standards of Cary, NC 2807 .\n");

        //CommonRails.International.IranWedding.printSystemComponent(this);

            //System.out.print(CommonRails.COLOR_TANGERINE);
            CommonRails.printSystemComponent(this, this.hashCode(),". Java™ National Finance Engine v.2811.1 v.11.1 .");
            //System.out.print(CommonRails.ANSI_NEAR_RESET_DARK);

        NationalDriver DRIVER = new NationalDriver();

            DRIVER.printOrderedComponents();

            DRIVER.clear();

        NitroWebExpress NITRO = new NitroWebExpress(Main.WEBEXPRESS_PORT, Main.WEBEXPRESS_HOSTNAME, Main.WEB_EXPRESS_SERVER_THREADNAME);

            NITRO.PORT = 49152;

            NITRO.HOST = "localhost";

            NITRO.THREAD_NAME = "United States D500 WebExpress";

            NITRO.TELNET_PROXY_ENABLED = Boolean.TRUE;

            if (configuration.NweConfig.isEnabled("AES_COMPLIANT"))
                NITRO.BRIDGE.AES_COMPONENT = new NitroWebExpress.Aspect.AESCompliant(AES_WEBEXPRESS_REMOTE_HOST, AES2_WEBEXPRESS_SERVER_SOCKET, AES2_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            if (configuration.NweConfig.isEnabled("BITCOIN_COMPLIANT"))
                NITRO.BRIDGE.BITCOIN_COMPONENT = new NitroWebExpress.Aspect.BitcoinCompliant(BITCOIN_WEBEXPRESS_REMOTE_HOST, BITCOIN_WEBEXPRESS_SERVER_SOCKET, BITCOIN_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            if (configuration.NweConfig.isEnabled("RSA_COMPLIANT"))
                NITRO.BRIDGE.RSA_COMPONENT = new NitroWebExpress.Aspect.RSACompliant(RSA_WEBEXPRESS_REMOTE_HOST, RSA_WEBEXPRESS_SERVER_SOCKET, RSA_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            if (configuration.NweConfig.isEnabled("DSA_COMPLIANT"))
                NITRO.BRIDGE.DSA_COMPONENT = new NitroWebExpress.Aspect.DSACompliant(DSA_WEBEXPRESS_REMOTE_HOST, DSA_WEBEXPRESS_SERVER_SOCKET, DSA_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            if (configuration.NweConfig.isEnabled("CONNECTION_STATUS"))
                NITRO.BRIDGE.CONNECTION_STATUS = new ConnectionStatusServer(CONNECTION_STATUS_SERVER_HOST, NITRO.CURRENT_CONNECTIONS, NITRO.PORT);

            if (configuration.NweConfig.isEnabled("MODULE_INSTALLATION"))
                NITRO.BRIDGE.MODULE_INSTALLER_SERVICE = new ModuleInstallationService(MODULE_INSTALLER_SERVICE_HOST);

            if (configuration.NweConfig.isEnabled("ASCII_CREATOR"))
                NITRO.BRIDGE.ASCII_CREATOR_SERVER = new NitroWebExpress.Aspect.ASCIICreatorServer(ASCII_CREATOR_SERVER_HOST);

            if (configuration.NweConfig.isEnabled("MODULE_LOADER_DAEMON"))
                NITRO.BRIDGE.MODULE_LOADER_DAEMON = new ModuleInstallationService(MODULE_LOADER_DAEMON_HOST);

            if (configuration.NweConfig.isEnabled("COMMUNICATOR"))
                NITRO.BRIDGE.COMMUNICATOR = new Communicator(COMMUNICATOR_HOST);

            if (configuration.NweConfig.isEnabled("BINARY_HTTP"))
                NITRO.BRIDGE.BINARY_HTTP_SERVER = new BinaryHttpServer(BINARY_HTTP_SERVER_HOST);

            if (configuration.NweConfig.isEnabled("WEATHER"))
                NITRO.BRIDGE.WEATHER_SERVER = new WeatherServer(WEATHER_SERVER_HOST);

            if (configuration.NweConfig.isEnabled("ANTIVIRUS"))
                new antivirus.AntivirusScanner(NweConfig.antivirusSchedule(), NweConfig.antivirusScanPath()).start();

            NITRO.BRIDGE.MYSQL_COMPONENT = new MySQLComponent();

            NITRO.BRIDGE.MYSQL_COMPONENT.print(this);

            database.N21XmlFallback.replayFallback();

            NITRO.BRIDGE.start();
    }
}
