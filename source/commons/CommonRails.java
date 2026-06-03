package commons;

import national.NationalDriver;
import server.nitro.WebExpress;

import java.net.Socket;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Collections;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

public class CommonRails
{
    protected String hash = "0xDA717018470E213F";

    // Desired total width for the text inside the [Current: ...] brackets
    protected static final int CLASSNAME_TOTAL_WIDTH = 35;

    /**
     * If true, CommonRails will emit ANSI-coloured animated output in delayableFinePrinter.
     * Can be overridden with system property `commonrails.color` or env var `COMMONRAILS_COLOR`.
     */
    public static boolean USE_COLORED_OUTPUT = true;
    static
    {
        try
        {
            String prop = System.getProperty("commonrails.color");

            if(prop!=null)
            {
                USE_COLORED_OUTPUT = Boolean.parseBoolean(prop);
            }
            else
            {
                String env = System.getenv("COMMONRAILS_COLOR");

                if(env!=null)
                {
                    USE_COLORED_OUTPUT = Boolean.parseBoolean(env);
                }
            }
        }
        catch (Throwable t)
        {
            // best-effort; keep default
        }
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
        // Build the [Current: ...] field and pad the content inside the brackets to the desired total width
        String inner = "Current: " + object.getClass().getSimpleName();
        int innerPad = Math.max(0, CLASSNAME_TOTAL_WIDTH - inner.length());
        String classname = "[" + inner + " ".repeat(innerPad) + "]";

        // classname is already the fixed-width bracketed field; use as-is
        String classnamePadded = classname;

        String compliant_hashcode = String.format("%010d", hashcode);

        String object_id = "-- : [Object ID: "+compliant_hashcode+"]";

        // Use full date/time in EST for the Date field
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
        formatter.setTimeZone(TimeZone.getTimeZone("America/New_York"));

        String date = "[Date: "+formatter.format(new Date())+"]";

        // Uppercase the first alphanumeric token in the provided line (the fourth printed field)
        String lineFixed = line;
        if (lineFixed != null && lineFixed.length() > 0)
        {
            int i = 0;
            // skip non-alphanumeric leading characters (punctuation, spaces)
            while (i < lineFixed.length() && !Character.isLetterOrDigit(lineFixed.charAt(i))) i++;

            int start = i;
            while (i < lineFixed.length() && (Character.isLetterOrDigit(lineFixed.charAt(i)) || lineFixed.charAt(i) == '_')) i++;

            if (start < i)
            {
                String token = lineFixed.substring(start, i);

                // Replace token with fully uppercased form
                String upper = token.toUpperCase();

                lineFixed = lineFixed.substring(0, start) + upper + lineFixed.substring(i);
            }
        }

        String reference = object_id + " " + date + " " + classnamePadded + " " + lineFixed;

        // Record reference order for startup ordering backend (best-effort)
        try
        {
            NationalDriver.record(reference);
        }
        catch (Throwable t)
        {
            // non-fatal: continue printing even if recording fails
        }

        CommonRails.delayableFinePrinter(reference, 21);

        //System.out.println("\u001B[0m");
    }

    public static void delayableFinePrinter(String text, int delay)
    {
        // When colored output is disabled, just print a single plain line and ensure ANSI reset.
        if (!USE_COLORED_OUTPUT)
        {
            try
            {
                System.out.println(text);

                // ensure terminal color state is reset
                System.out.print("\u001B[0m");
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }

            return;
        }

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

            // reset terminal color state after animation
            System.out.print("\u001B[0m");
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
            CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails registerProcess >> registered process: " + process + " . ");

            // Attach onExit listener
            process.onExit().thenAccept(p -> {
                try
                {
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails processExited >> process closed: " + p + " exit=" + p.exitValue() + " . ");
                }
                catch (Throwable t)
                {
                    // Best-effort printing
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails processExited >> process closed: " + p + " . ");
                }
                finally
                {
                    REGISTERED_PROCESSES.remove(p);
                }
            });

            // Supervisor: ensure process is not left running beyond timeout (2 hours)
            new Thread(() -> {
                try
                {
                    if (!process.waitFor(2, TimeUnit.HOURS))
                    {
                        CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails process timeout (2 hours) exceeded; destroying: " + process + " . ");

                        try { process.destroyForcibly(); } catch (Throwable ignored) {}
                    }
                }
                catch (Throwable t)
                {
                    // ignore supervision errors
                }
            }, "CommonRails-ProcessTimeout-" + process.hashCode()).start();
        }
        catch (Throwable t)
        {
            // Fallback: spawn a watcher thread that waits for the process
            new Thread(() -> {
                try
                {
                    boolean finished = process.waitFor(2, TimeUnit.HOURS);

                    if (finished)
                    {
                        int rv = process.exitValue();

                        CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails processExited(watcher) >> process closed: " + process + " exit=" + rv + " . ");
                    }
                    else
                    {
                        CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails process watcher timeout (2 hours) exceeded; destroying: " + process + " . ");

                        try { process.destroyForcibly(); } catch (Throwable ignored) {}
                    }
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
                Process p = this.web_express.TELNET_COMMUNICATION_PROXY.process;

                boolean finished = p.waitFor(2, TimeUnit.HOURS);

                if (finished)
                {
                    int return_value = p.exitValue();

                    CommonRails.printSystemComponent(this, p.hashCode(), ". TelnetCallOnComplete >> process exited: " + p + " exit=" + return_value + " . ");
                }
                else
                {
                    CommonRails.printSystemComponent(this, p.hashCode(), ". TelnetCallOnComplete >> timeout (2 hours) exceeded; destroying process: " + p);

                    try { p.destroyForcibly(); } catch (Throwable ignored) {}
                }
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
        public static void printInternationalGregorianRhetoric(Object owner, String text)
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
    }
}
