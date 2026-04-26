import commons.CommonRails;
import server.WebExpress;

import java.util.Date;

/**
 * @author Max Rupplin
 *
 * @date April 20 2026
 * @us.governor Caesar Bernini
 */
public class Main
{
    protected String hash = "0xDA717018470E213F";

    protected static final Integer WEB_EXPRESS_SERVER_SOCKET = 49152;

    protected static final String WEB_EXPRESS_SERVER_THREAD_NAME = "WEB_EXPRESS_TELNET_PROXY_SERVER";

    protected static final Integer AES2_EXPRESS_SERVER_SOCKET = 5512;

    protected static final String AES2_EXPRESS_SERVER_THREAD_NAME = "WEB_EXPRESS_AES2_SERVER";

    protected static final String WEB_EXPRESS_HOST = "localhost";

    protected static final String AES_WEB_EXPRESS = "localhost";

    protected static final String BITCOIN_WEB_EXPRESS = "localhost";

    public Main()
    {
        WebExpress.reference = null;

        CommonRails.printSystemComponent(this.hashCode(),"WebExpress::Main >> starts.");

        WebExpress web_express = WebExpress.reference = new WebExpress(WEB_EXPRESS_HOST, WEB_EXPRESS_SERVER_SOCKET, WEB_EXPRESS_SERVER_THREAD_NAME, true);

        WebExpress.AES_WebExpress aes_express = new WebExpress.AES_WebExpress(AES_WEB_EXPRESS, AES2_EXPRESS_SERVER_SOCKET, AES2_EXPRESS_SERVER_THREAD_NAME, false);

        WebExpress.Bitcoin_WebExpress bitcoin_express = new WebExpress.Bitcoin_WebExpress(BITCOIN_WEB_EXPRESS, AES2_EXPRESS_SERVER_SOCKET, AES2_EXPRESS_SERVER_THREAD_NAME, false);

        web_express.start();

        //aes_express.start();
    }

    public static void main(String...args)
    {
        Main main = new Main();
    }
}
