public class Main
{
    public static void main(String...args)
    {
        WebExpress web_express = new WebExpress();

        web_express.install_remote_connections();

        web_express.install_local_connections();
    }
}
