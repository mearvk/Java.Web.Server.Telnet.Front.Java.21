/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package commons;

import server.nitro.WebExpress;

import java.io.Closeable;
import java.net.Socket;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class CommonRails
{
    protected String hash = "0xDA717018470E213F";

    private static final DateTimeFormatter TIMESTAMP_FORMATTER = DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss z");

    private static final ZoneId DEFAULT_ZONE = ZoneId.of("America/New_York");

    public CommonRails()
    {

    }

    public static <T> Integer size(final List<T> list)
    {
        return list == null ? 0 : list.size();
    }

    public static void info(final Object object, final Integer hashcode, final String line)
    {
        printSystemComponent(object, hashcode, "INFO", line);
    }

    public static void warn(final Object object, final Integer hashcode, final String line)
    {
        printSystemComponent(object, hashcode, "WARN", line);
    }

    public static void error(final Object object, final Integer hashcode, final String line)
    {
        printSystemComponent(object, hashcode, "ERROR", line);
    }

    public static void printSystemComponent(final Object object, final Integer hashcode, final String level, final String line)
    {
        final String classname = object == null ? "[Current: null]" : ("[Current: "+object.getClass().getSimpleName()+"]");

        final String compliant_hashcode = String.format("%010d", hashcode == null ? 0 : hashcode);

        final String object_id = "-- : [Object ID: "+compliant_hashcode+"]";

        final String date = "[Date: "+ ZonedDateTime.now(DEFAULT_ZONE).format(TIMESTAMP_FORMATTER) +"]";

        final String reference = object_id + " "+ date + " " + level + " " + classname + " " + line;

        delayableFinePrinter(reference, 12);
    }

    public static void printSystemComponent(final Object object,  final Integer hashcode, final String line)
    {
        printSystemComponent(object, hashcode, "INFO", line);
    }

    public static void delayableFinePrinter(final String text, final int delay)
    {
        final int[] codes = {232, 233, 234, 235, 236, 237, 238, 241, 244, 247, 250, 253, 188};

        try
        {
            for (int color : codes)
            {
                System.out.print("\033[38;5;" + color + "m" + text + "\r");

                Thread.sleep(delay);
            }

            Thread.sleep(120L);

            System.out.println(text);
        }
        catch (InterruptedException ie)
        {
            Thread.currentThread().interrupt();

            System.out.println(text);
        }
        catch (Exception e)
        {
            System.out.println(text);
        }
    }

    protected static void actionDelay(final String action,  final WebExpress WEB_EXPRESS, final Integer notLessThan)
    {
        try
        {
            Thread.sleep(notLessThan == null ? 0 : notLessThan);
        }
        catch (InterruptedException ie)
        {
            Thread.currentThread().interrupt();
        }

        if ("TelnetCommunicator::Close::Hook".equals(action))
        {
            try
            {
                TelnetCallOnComplete call_on_complete = new TelnetCallOnComplete(WEB_EXPRESS);

                call_on_complete.run();
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }

    public static class SocketUtils
    {
        public static boolean isSocketConnected(final Socket socket)
        {
            if (socket == null) return false;

            try
            {
                return socket.isConnected() && !socket.isClosed();
            }
            catch (Exception e)
            {
                return false;
            }
        }

        public static boolean isSocketClosed(final Socket socket)
        {
            if (socket == null) return true;

            try
            {
                return socket.isClosed();
            }
            catch (Exception e)
            {
                return true;
            }
        }

        public static void safeClose(final Socket socket)
        {
            if (socket == null) return;

            try
            {
                socket.close();
            }
            catch (Exception ignored)
            {
            }
        }

        public static void safeClose(final Closeable c)
        {
            if (c == null) return;

            try
            {
                c.close();
            }
            catch (Exception ignored)
            {
            }
        }
    }

    public static class TelnetCallOnComplete implements Runnable
    {
        protected WebExpress WEB_EXPRESS;

        public TelnetCallOnComplete(final WebExpress WEB_EXPRESS)
        {
            this.WEB_EXPRESS = WEB_EXPRESS;
        }

        @Override
        public void run()
        {
            if (this.WEB_EXPRESS == null || this.WEB_EXPRESS.TELNET_COMMUNICATION_PROXY == null || this.WEB_EXPRESS.TELNET_COMMUNICATION_PROXY.process == null)
            {
                return;
            }

            try
            {
                this.WEB_EXPRESS.TELNET_COMMUNICATION_PROXY.process.waitFor();
            }
            catch (InterruptedException ie)
            {
                Thread.currentThread().interrupt();
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }
}
