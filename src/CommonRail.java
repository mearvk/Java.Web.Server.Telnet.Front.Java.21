import java.net.Socket;

public class CommonRail
{
    public CommonRail()
    {

    }

    protected void _long(final String orgasm, WebExpress web_express, Integer not_less_than)
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
                    TelnetCallOnComplete call_on_complete = new TelnetCallOnComplete(this, web_express);

                    call_on_complete.run();
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }

                break;
        }
    }

    public static class Utils
    {
        public static Boolean socketIsConnected(Socket socket)
        {
            try
            {
                socket.getOutputStream().write("".getBytes());

                return true;
            }
            catch (Exception e)
            {
                return false;
            }
        }
    }

    public static class TelnetCallOnComplete implements Runnable
    {
        protected CommonRail common_rail;

        protected WebExpress web_express;

        public TelnetCallOnComplete(CommonRail common_rail, WebExpress web_express)
        {
            this.common_rail = common_rail;

            this.web_express = web_express;
        }

        @Override
        public void run()
        {
            try
            {
                int return_value = web_express.telnet_communicator.process.waitFor();
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }
}
