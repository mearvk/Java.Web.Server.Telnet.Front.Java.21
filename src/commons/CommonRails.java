package commons;

import server.WebExpress;

import java.net.Socket;
import java.util.Date;

public class CommonRails
{
    public CommonRails()
    {

    }

    public static void printSystemComponent(Integer hashcode, String symbol, String line)
    {
        String compliant_hashcode = String.format("%010d", hashcode);

        String object_id = "[Object ID: "+compliant_hashcode+"] >>";

        String date = "\n\t[Date: "+new Date().toString()+"]";

        String reference = object_id + " " + date + " " + line;

        System.out.println(reference);
    }

    protected static void _long(final String orgasm, WebExpress web_express, Integer not_less_than)
    {
        try
        {
            Thread.sleep(not_less_than);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }

        switch (orgasm)
        {
            case "TelnetCommunicator::Close::Hook":

                try
                {
                    TelnetCallOnComplete call_on_complete = new TelnetCallOnComplete(web_express);

                    call_on_complete.run();
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }

                break;
        }
    }

    public static class SocketUtils
    {
        public static Boolean isSocketConnected(Socket socket)
        {
            try
            {
                socket.getOutputStream().write("".getBytes());
            }
            catch (Exception e)
            {
                return false;
            }

            return true;
        }

        public static Boolean isSocketClosed(Socket socket)
        {
            try
            {
                socket.getOutputStream().write("".getBytes());
            }
            catch(Exception e)
            {
                return true;
            }

            return false;
        }
    }

    public static class TelnetCallOnComplete implements Runnable
    {
        protected WebExpress web_express;

        public TelnetCallOnComplete(WebExpress web_express)
        {
            this.web_express = web_express;
        }

        @Override
        public void run()
        {
            try
            {
                int return_value = this.web_express.telnet_communication_proxy.process.waitFor();
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }
}
