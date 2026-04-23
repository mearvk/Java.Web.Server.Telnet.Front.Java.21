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

    protected static final Integer AES2_EXPRESS_SERVER_SOCKET = 5512;

    public Main()
    {
        WebExpress.reference = null;

        CommonRails.printSystemComponent(this.hashCode(),"*","[Object ID: *] WebExpress::Main >> starts ["+ new Date() +"]");

        WebExpress web_express = new WebExpress("localhost", WEB_EXPRESS_SERVER_SOCKET, true);

        WebExpress aes_express = new WebExpress("localhost", AES2_EXPRESS_SERVER_SOCKET, false);

        web_express.start();

        aes_express.start();
    }

    public static void main(String...args)
    {
        Main main = new Main();
    }
}
