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
    {
        WebExpress.reference = null;

        CommonRails.printSystemComponent(this.hashCode(),"WebExpress::Main >> starts.");

        WebExpress web_express = WebExpress.reference = new WebExpress("localhost", WEB_EXPRESS_SERVER_SOCKET, WEB_EXPRESS_SERVER_THREAD_NAME, true);

        //WebExpress aes_express = WebExpress.reference = new WebExpress("localhost", AES2_EXPRESS_SERVER_SOCKET, AES2_EXPRESS_SERVER_THREAD_NAME, false);

        web_express.start();

        //aes_express.start();
    }

    public static void main(String...args)
    {
        Main main = new Main();
    }
}
