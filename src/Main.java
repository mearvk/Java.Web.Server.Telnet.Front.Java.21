public class Main
{
    protected String hash = "0xDA717018470E213F";

    protected static final Integer WEB_EXPRESS_SERVER_SOCKET = 49152;

    protected static final Integer AES2_EXPRESS_SERVER_SOCKET = 5512;

    public static void main(String...args)
    {
        WebExpress web_express = new WebExpress("localhost", WEB_EXPRESS_SERVER_SOCKET, true);

        WebExpress aes_express = new WebExpress("localhost", AES2_EXPRESS_SERVER_SOCKET, false);
    }
}
