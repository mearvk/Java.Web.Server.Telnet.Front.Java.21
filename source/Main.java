import commons.CommonRails;
import national.NationalDriver;
import server.nitro.ConnectionStatusServer;
import server.nitro.NitroWebExpress;

import java.io.File;

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

    protected static final String WEBEXPRESS_HOSTNAME = "localhost";

    protected static final String AES_WEBEXPRESS_REMOTE_HOST = "localhost";

    protected static final String BITCOIN_WEBEXPRESS_REMOTE_HOST = "localhost";

    protected static final Integer CONNECTION_STATUS_SERVER_PORT = ConnectionStatusServer.STATUS_PORT;

    protected static final String CONNECTION_STATUS_SERVER_HOST = "localhost";

    public Main()
    {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                String script = new File("scripts/shutdown.sh").getAbsolutePath();
                new ProcessBuilder("bash", script).inheritIO().start().waitFor();
            } catch (Exception e) { e.printStackTrace(System.err); }
        }, "ShutdownHook"));

        CommonRails.printStartRecipeSpinner();

            System.out.println("[ Java National Finance Engine v.28.1.1 Software Processes Starting ]");

            System.out.println(". Cryptography/Cryptology AES 2.0 National Cryptolograph Enabled DSS (DeepSonaGraphoSophons) 5.0 .");

            System.out.println(". Bitcoin Lightweight Binary Trader 2.0 Enabled ₿ Running on Bitcoin Open-Source v24.0 or newer .");

            System.out.println(". Operating within and United to National Authority of US United States and State of California in Coalition of and for North Carolina her betterment .");

            System.out.println(". ND51 North Carolina Labors & Standards A5501 ANationals Standards of Cary, NC 2807 .\n");

        CommonRails.International.IranWedding.printSystemComponent(this);

        System.out.println();

            CommonRails.printSystemComponent(this, this.hashCode(),". Java™ National Finance Engine v.2811.1 v.11.1 .");

            CommonRails.printSystemComponent(this, this.hashCode(),". National NitroExpress™ Web Engine Starting .");

        // ── MySQL / N21 database status check ────────────────────────────────
        db.N21Status.Status dbStatus = db.N21Status.check();
        if (dbStatus.jdbcConnected() && dbStatus.n21DbExists())
            CommonRails.printLimeGreen(". " + dbStatus.message() + " .");
        else
            CommonRails.printDeepRed(". " + dbStatus.message() + " .");
        // ─────────────────────────────────────────────────────────────────────

        NationalDriver DRIVER = new NationalDriver();

            DRIVER.printOrderedComponents();

            DRIVER.clear();

        NitroWebExpress NITRO = new NitroWebExpress(Main.WEBEXPRESS_PORT, Main.WEBEXPRESS_HOSTNAME, Main.WEB_EXPRESS_SERVER_THREADNAME);

            NITRO.PORT = 49152;

            NITRO.HOST = "localhost";

            NITRO.THREAD_NAME = "United States D500 WebExpress";

            NITRO.TELNET_PROXY_ENABLED = Boolean.TRUE;

            NITRO.BRIDGE.AES_COMPONENT = new NitroWebExpress.Aspect.AESCompliant(AES_WEBEXPRESS_REMOTE_HOST, AES2_WEBEXPRESS_SERVER_SOCKET, AES2_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            NITRO.BRIDGE.BITCOIN_COMPONENT = new NitroWebExpress.Aspect.BitcoinCompliant(BITCOIN_WEBEXPRESS_REMOTE_HOST, BITCOIN_WEBEXPRESS_SERVER_SOCKET, BITCOIN_WEBEXPRESS_SERVER_THREAD_NAME, Boolean.TRUE);

            NITRO.BRIDGE.CONNECTION_STATUS = new ConnectionStatusServer(CONNECTION_STATUS_SERVER_HOST, NITRO.CURRENT_CONNECTIONS, NITRO.PORT);

            NITRO.BRIDGE.CONNECTION_STATUS.start();

        NitroWebExpress.SELF.start();
    }

    public static void main(String...args)
    {
        Main main = new Main();
    }
}
