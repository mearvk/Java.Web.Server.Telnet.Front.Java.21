package commons;

import server.nitro.WebExpress;

import java.net.Socket;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Collections;

public class CommonRails
{
    protected String hash = "0xDA717018470E213F";

    public static boolean USE_COLORED_OUTPUT = true;

    private static final String ANSI_RESET        = "\u001B[0m";

    // Object-ID category colors (applied to the numeric digits only)
    private static final String OID_SECURITY    = "\033[38;5;196m"; // bright red
    private static final String OID_TELNET      = "\033[38;5;51m";  // cyan
    private static final String OID_ENCRYPTION  = "\033[38;5;208m"; // orange
    private static final String OID_BITCOIN     = "\033[38;5;220m"; // gold
    private static final String OID_LOGGING     = "\033[38;5;147m"; // lavender
    private static final String OID_MESSAGING   = "\033[38;5;118m"; // lime green
    private static final String OID_CONNECTIONS = "\033[38;5;75m";  // sky blue
    private static final String OID_SERVER      = "\033[38;5;214m"; // amber
    private static final String OID_LIVENESS    = "\033[38;5;46m";  // bright green
    private static final String OID_DEFAULT     = "\033[38;5;250m"; // silver

    private static String resolveOidColor(String simpleClassName)
    {
        if (simpleClassName == null) return OID_DEFAULT;
        String low = simpleClassName.toLowerCase();
        if (low.contains("security") || low.contains("port") || low.contains("auth"))
            return OID_SECURITY;
        if (low.contains("telnet") || low.contains("proxy") || low.contains("communicator"))
            return OID_TELNET;
        if (low.contains("encrypt") || low.contains("aes") || low.contains("cipher"))
            return OID_ENCRYPTION;
        if (low.contains("bitcoin") || low.contains("trader") || low.contains("wallet"))
            return OID_BITCOIN;
        if (low.contains("common") || low.contains("rail") || low.contains("logger")
                || low.contains("national") || low.contains("driver") || low.contains("iranian")
                || low.contains("wedding"))
            return OID_LOGGING;
        if (low.contains("message") || low.contains("queue") || low.contains("sorter")
                || low.contains("handler") || low.contains("orderer"))
            return OID_MESSAGING;
        if (low.contains("connection") || low.contains("poller") || low.contains("socket")
                || low.contains("galactic") || low.contains("international") || low.contains("recorded"))
            return OID_CONNECTIONS;
        if (low.contains("server") || low.contains("express") || low.contains("nitro")
                || low.contains("base") || low.contains("installer"))
            return OID_SERVER;
        if (low.contains("liveness") || low.contains("monitor"))
            return OID_LIVENESS;
        return OID_DEFAULT;
    }

    public CommonRails()
    {

    }

    public static <T> Integer size(ArrayList<T> list)
    {
        return list.size();
    }

    public static void printSystemComponent(Object object, Integer hashcode, String line)
    {
        String classname = "[Current: "+object.getClass().getSimpleName()+"]";

        String compliant_hashcode = USE_COLORED_OUTPUT
                ? resolveOidColor(object.getClass().getSimpleName()) + String.format("%010d", hashcode) + ANSI_RESET
                : String.format("%010d", hashcode);

        String object_id = "-- : [Object ID: "+compliant_hashcode+"]";

        SimpleDateFormat formatter = new SimpleDateFormat("HH:mm:ss");

        String date = "[Date: "+formatter.format(new Date())+"]";

        String reference = object_id + " "+ date + " " + classname + " " + line;

        CommonRails.delayableFinePrinter(reference, 21);

        //System.out.println("\u001B[0m");
    }

    public static void delayableFinePrinter(String text, int delay)
    {
        int[] codes = {232, 233, 234, 235, 236, 237, 238, 241, 244, 247, 250, 253, 188};

        try
        {
            for(int color : codes)
            {
                System.out.print("\033[38;5;" + color + "m" + text + "\r");

                Thread.sleep(delay);
            }

            Thread.sleep(400L);

            System.out.println(text);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
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
            case "TelnetCommunicator Close Hook":

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

    // Registry for started Processes so CommonRails can monitor them and print on exit
    protected static final List<Process> REGISTERED_PROCESSES = Collections.synchronizedList(new ArrayList<Process>());

    /**
     * Register a started Process with CommonRails. CommonRails will attach a listener
     * to the process' onExit CompletableFuture (Java 9+) and print when the process exits.
     * If onExit is unavailable/throws, a watcher thread using waitFor is started as a fallback.
     */
    public static synchronized void registerProcess(ProcessBuilder pb, Process process, Object owner)
    {
        if (process == null) return;

        REGISTERED_PROCESSES.add(process);

        Object printer = (owner == null) ? CommonRails.class : owner;

        try
        {
            CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails registerProcess >> registered process: " + process);

            // Attach onExit listener
            process.onExit().thenAccept(p -> {
                try
                {
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails processExited >> process closed: " + p + " exit=" + p.exitValue());
                }
                catch (Throwable t)
                {
                    // Best-effort printing
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails processExited >> process closed: " + p);
                }
                finally
                {
                    REGISTERED_PROCESSES.remove(p);
                }
            });
        }
        catch (Throwable t)
        {
            // Fallback: spawn a watcher thread that waits for the process
            new Thread(() -> {
                try
                {
                    int rv = process.waitFor();

                    CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails processExited(watcher) >> process closed: " + process + " exit=" + rv);
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }
                finally
                {
                    REGISTERED_PROCESSES.remove(process);
                }
            }, "CommonRails-ProcessWatcher-" + process.hashCode()).start();
        }
    }

    public static synchronized List<Process> getRegisteredProcesses()
    {
        return new ArrayList<>(REGISTERED_PROCESSES);
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
                int return_value = this.web_express.TELNET_COMMUNICATION_PROXY.process.waitFor();
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }

    /**
     * Support class for a themed startup decorator — IranianWedding presentation.
     * Provides a burgundy-colored single-line print used during program init.
     */
    public static class IranianWedding
    {
        private static final String BURGUNDY_ANSI = "\033[38;5;88m";
        private static final String RESET_ANSI = "\u001B[0m";

        /**
         * Print a single-line burgundy presentation. Respects USE_COLORED_OUTPUT flag;
         * when disabled, prints plain text without ANSI codes.
         */
        public static void printBurgundyPresentation(Object owner, String text)
        {
            if (text == null) return;

            String output = text;

            try
            {
                if (USE_COLORED_OUTPUT)
                {
                    System.out.print(BURGUNDY_ANSI);
                    System.out.print(output);
                    System.out.print(RESET_ANSI);
                    System.out.print("\n");
                }
                else
                {
                    System.out.println(output);
                }

                //CommonRails.printSystemComponent(owner == null ? CommonRails.class : owner, (owner==null?CommonRails.class.hashCode():owner.hashCode()), ". IranianWedding presentation printed .");
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }

        public static void printInternationalGregorianRhetoric(Object owner, String text)
        {
            printBurgundyPresentation(owner, text);
        }
    }
}
