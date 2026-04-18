public class Main
{
    public static void main(String...args)
    {
        WebExpress web_express = new WebExpress();

        web_express.install();

        web_express.listen();

        web_express.local();
    }
}
