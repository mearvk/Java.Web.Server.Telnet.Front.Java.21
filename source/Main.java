import commons.CommonRails;
import server.nitro.NitroWebExpress;

import java.util.Objects;

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

    protected static final String WEB_EXPRESS_SERVER_THREADNAME = ". WEBEXPRESS_TELNET_PROXY_SERVER .";

    protected static final String AES2_WEBEXPRESS_SERVER_THREAD_NAME = ". WEBEXPRESS_AES2_SERVER .";

    protected static final String BITCOIN_WEBEXPRESS_SERVER_THREAD_NAME = ". WEBEXPRESS_BITCOIN_SERVER .";

    protected static final String WEBEXPRESS_HOSTNAME = "localhost";

    protected static final String AES_WEBEXPRESS_HOST = "localhost";

    protected static final String BITCOIN_WEBEXPRESS_HOST = "localhost";

    protected static final Boolean WEBEXPRESS_TELNET_PROXY_ENABLED = Boolean.TRUE;

    protected static final Boolean COMPONENT_TELNET_PROXY_ENABLED = Boolean.TRUE;

    public Main()
    {
        System.out.println("-");

            System.out.println("[ Java National Finance Engine v.28.1.1 Software Processes Starting ]");

            System.out.println(". Cryptography/Cryptology AES2 National Cryptolograph Enabled DSS 5.0 .");

            System.out.println(". Bitcoin Lightweight Binary Trader 2.0 Enabled ₿ Running on Bitcoin Open-Source v24.0 or newer .");

            System.out.println(". Operating within and United to National Authority of US United States and State of California in Coalition of and for North Carolina her betterment .");

            System.out.println(". ND51 North Carolina Labors & Standards A5501 ANationals Standards of Cary, NC 2807 .");

        System.out.println("-");

            CommonRails.printSystemComponent(this, this.hashCode(),". Java™ National Finance Engine v.2811.1 v.11.1 .");

            CommonRails.printSystemComponent(this, this.hashCode(),". National NitroExpress™ Web Engine Starting .");

        NitroWebExpress nitro = new NitroWebExpress(Main.WEBEXPRESS_PORT, Main.WEBEXPRESS_HOSTNAME, Main.WEB_EXPRESS_SERVER_THREADNAME, Main.WEBEXPRESS_TELNET_PROXY_ENABLED);

            configureBridge(nitro);

        startNitroWebExpress(nitro);
    }

    private static void configureBridge(final NitroWebExpress nitro)
    {
        Objects.requireNonNull(nitro, "nitro");

        Objects.requireNonNull(nitro.bridge, "nitro.bridge");

        nitro.bridge.AES_COMPONENT = new NitroWebExpress.Aspect.AESCompliant(AES_WEBEXPRESS_HOST, AES2_WEBEXPRESS_SERVER_SOCKET, AES2_WEBEXPRESS_SERVER_THREAD_NAME, COMPONENT_TELNET_PROXY_ENABLED);

        nitro.bridge.BITCOIN_COMPONENT = new NitroWebExpress.Aspect.BitcoinCompliant(BITCOIN_WEBEXPRESS_HOST, BITCOIN_WEBEXPRESS_SERVER_SOCKET, BITCOIN_WEBEXPRESS_SERVER_THREAD_NAME, COMPONENT_TELNET_PROXY_ENABLED);
    }

    private static void startNitroWebExpress(final NitroWebExpress nitro)
    {
        Objects.requireNonNull(nitro, "nitro");

        if(nitro.SERVER_SOCKET==null) throw new IllegalStateException("NitroWebExpress server socket was not initialized.");

        nitro.start();
    }

    public static void main(String...args)
    {
        Main main = new Main();
    }
}
