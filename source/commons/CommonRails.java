package commons;

import national.NationalDriver;
import server.nitro.WebExpress;

import java.io.BufferedWriter;
import java.io.IOException;
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

    /** Pluggable exception sink — set by ExceptionHandler at startup to avoid circular import. */
    public static java.util.function.Consumer<Exception> EXCEPTION_SINK = e -> {};

    /** Called by ExceptionHandler once to wire itself in. */
    public static void setExceptionSink(java.util.function.Consumer<Exception> sink)
    {
        if (sink != null) EXCEPTION_SINK = sink;
    }

    // Desired total width for the text inside the [Current: ...] brackets
    protected static final int CLASSNAME_TOTAL_WIDTH = 39;

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

    // Color constants
    private static final String ANSI_YELLOW = "\u001B[33m";
    private static final String ANSI_WHITE        = "\033[38;5;15m";
    private static final String ANSI_DEEP_RED     = "\033[38;5;160m";
    private static final String ANSI_SILVER       = "\033[38;5;250m";
    private static final String ANSI_IMPERIAL_GRAY= "\u001B[38;5;242m";
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

    /**
     * Resolve which Object-ID color to use based on the owner's simple class name.
     */
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

    public static <T> Integer size(ArrayList<T> list)
    {
        return list.size();
    }

    public static class International
    {
        public static class IranianWedding
        {
            public static void printSystemComponent(Object owner)
            {
                String message = ". THE US (USA) WERE FINE AND IN FACT RELATED TO AN IRANIAN WEDDING OF REMARKABLE PRECEDENT .\n";

                CommonRails.IranianWedding.printInternationalGregorianRhetoric(owner, message);
            }
        }

        public static class IranWedding
        {
            public static void printSystemComponent(Object owner)
            {
                String message = ". THE US United States of America (USA) were fine and in fact related to an IRAN WEDDING of REMARKABLE PRECEDENT .\n";

                CommonRails.IranianWedding.printInternationalGregorianRhetoric(owner, message);
            }
        }
    }

    public static void printStartRecipeSpinner()
    {
        for(int i=0; i<3; i++)
        {
            try
            {
                System.out.print("- Loading Java National Finance Engine v.2811.\r");

                Thread.sleep(500);

                System.out.print("+ Loading Java National Finance Engine v.2811..\r");

                Thread.sleep(500);

                System.out.print("- Loading Java National Finance Engine v.2811...\r");

                Thread.sleep(500);

                System.out.print("+ Loading Java National Finance Engine v.2811\r");
            }
            catch (Exception e)
            {
                EXCEPTION_SINK.accept(e);
                e.printStackTrace(System.err);
            }
        }

        System.out.print("\r");
    }

    public static void printSystemComponent(Object object, Integer hashcode, String line)
    {
        // Build the [Current: ...] field and pad the content inside the brackets to the desired total width
        String inner = "Current: @" + object.getClass().getSimpleName();
        int innerPad = Math.max(0, CLASSNAME_TOTAL_WIDTH - inner.length());
        String classname = "[" + inner + " ".repeat(innerPad) + "]";

        // classname is already the fixed-width bracketed field; use as-is
        String classnamePadded = classname;

        String compliant_hashcode = String.format("%010d", hashcode);

        // Color the numeric digits by object category when color output is enabled
        String colored_hashcode = USE_COLORED_OUTPUT
            ? resolveOidColor(object.getClass().getSimpleName()) + compliant_hashcode + ANSI_RESET
            : compliant_hashcode;

        String object_id = "-- : [Object ID: "+colored_hashcode+"]";

        // Use full date/time in EST for the Date field
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
        formatter.setTimeZone(TimeZone.getTimeZone("America/New_York"));

        String date = "[Date: "+formatter.format(new Date())+"]";

        // Uppercase the first alphanumeric token in the provided line (the fourth printed field)
        String lineFixed = line;
        if (lineFixed != null && lineFixed.length() > 0)
        {
            int len = lineFixed.length();
            int i = 0;
            // skip non-alphanumeric leading characters (punctuation, spaces)
            while (i < len && !Character.isLetterOrDigit(lineFixed.charAt(i))) i++;

            int start1 = i;
            while (i < len && (Character.isLetterOrDigit(lineFixed.charAt(i)) || lineFixed.charAt(i) == '_')) i++;
            int end1 = i;

            if (start1 < end1)
            {
                String token1 = lineFixed.substring(start1, end1);

                // Replace token1 with fully uppercased form
                String upper1 = token1.toUpperCase();

                lineFixed = lineFixed.substring(0, start1) + upper1 + lineFixed.substring(end1);

                // find the second token; allow dots, colons and dashes (for IPs/hosts/ports)
                len = lineFixed.length();
                i = start1 + upper1.length();

                // helper to identify token characters for second token
                java.util.function.IntPredicate isTokenChar = c -> (Character.isLetterOrDigit((char)c) || c == '_' || c == '.' || c == ':' || c == '-');

                // skip non-token characters
                while (i < len && !isTokenChar.test(lineFixed.charAt(i))) i++;

                int start2 = i;
                while (i < len && isTokenChar.test(lineFixed.charAt(i))) i++;
                int end2 = i;

                if (start2 < end2)
                {
                    String token2 = lineFixed.substring(start2, end2);

                    boolean shouldUppercaseSecond = false;

                    // localhost exact match
                    if (token2.equalsIgnoreCase("localhost")) shouldUppercaseSecond = true;

                    // class/object keywords
                    if (token2.equalsIgnoreCase("class") || token2.equalsIgnoreCase("classname") || token2.equalsIgnoreCase("object")) shouldUppercaseSecond = true;

                    // IP-like (contains dot or colon) or numeric IP pattern
                    if (token2.contains(".") || token2.contains(":")) shouldUppercaseSecond = true;

                    // if second token looks like an IPv4 numeric segment sequence
                    if (token2.matches("\\d{1,3}(?:\\.\\d{1,3}){1,3}(?::\\d+)?")) shouldUppercaseSecond = true;

                    if (shouldUppercaseSecond)
                    {
                        String upper2 = token2.toUpperCase();
                        lineFixed = lineFixed.substring(0, start2) + upper2 + lineFixed.substring(end2);
                    }
                }
            }
        }

        // Uppercase specific keywords anywhere in the line when they appear as whole words
        if (lineFixed != null)
        {
            String[] keywords = new String[]{"telnet", "proxy", "installer", "communicator", "webexpress", "messagequeuesorter", "messagequeuehandler", "serversocket"};
            for (String kw : keywords)
            {
                // (?i) for case-insensitive, \b for word boundary, use Pattern.quote to avoid accidental regex metacharacters
                lineFixed = lineFixed.replaceAll("(?i)\\b" + java.util.regex.Pattern.quote(kw) + "\\b", kw.toUpperCase());
            }

            // Colorize JAVA and TM symbol: make JAVA full white, TM in deep red-burgundy
            try
            {
                // Replace standalone JAVA (case-insensitive) with white-colored version
                lineFixed = lineFixed.replaceAll("(?i)\\bJAVA\\b", ANSI_WHITE + "JAVA" + ANSI_RESET);

                // Replace trademark symbol ™ with deep red color
                lineFixed = lineFixed.replaceAll("™", ANSI_DEEP_RED + "™" + ANSI_RESET);

                // Color NitroExpress and "National Finance" in white-silver
                lineFixed = lineFixed.replaceAll("(?i)\\bNitroExpress\\b", ANSI_SILVER + "NitroExpress" + ANSI_RESET);
                lineFixed = lineFixed.replaceAll("(?i)National Finance", ANSI_SILVER + "National Finance" + ANSI_RESET);
            }
            catch (Throwable ignored) {}
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
                EXCEPTION_SINK.accept(e);
                e.printStackTrace(System.err);
            }

            return;
        }

        // Grayscale fade: dark grey -> full white using ANSI 256-color codes 236..255 (20 steps)
        int[] codes = new int[20];
        for (int k = 0; k < 20; k++) codes[k] = 236 + k; // 236..255

        try
        {
            for(int color : codes)
            {
                System.out.print("\033[38;5;" + color + "m" + text + "\r");

                // per-grade delay fixed at 20ms for a smoother, more emotive fade
                Thread.sleep(20);
            }

            System.out.print("\u001B[0m");

            Thread.sleep(200L);

            System.out.println(text);

            System.out.print("\u001B[0m");
        }
        catch (Exception e)
        {
            EXCEPTION_SINK.accept(e);
            e.printStackTrace(System.err);
        }
    }

    public static boolean isConnected(BufferedWriter writer)
    {
        try
        {
            writer.flush();

            return true;
        }
        catch (IOException e)
        {
            return false;
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
            EXCEPTION_SINK.accept(e);
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
                    EXCEPTION_SINK.accept(e);
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

        // derive a process descriptor from ProcessBuilder or Process info
        final String procDesc = getProcessDescriptor(pb, process);

        try
        {
            CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails REGISTERED: " + process + " [proc: " + procDesc + "] . ");

            // Attach onExit listener
            process.onExit().thenAccept(p -> {
                try
                {
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails processExited >> process closed: " + p + " exit=" + p.exitValue() + " [proc: " + procDesc + "] . ");
                }
                catch (Throwable t)
                {
                    // Best-effort printing
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails processExited >> process closed: " + p + " [proc: " + procDesc + "] . ");
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
                        CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails process timeout (2 hours) exceeded; destroying: " + process + " [proc: " + procDesc + "] . ");

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

                        CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails processExited(watcher) >> process closed: " + process + " exit=" + rv + " [proc: " + getProcessDescriptor(null, process) + "] . ");
                    }
                    else
                    {
                        CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails process watcher timeout (2 hours) exceeded; destroying: " + process + " [proc: " + getProcessDescriptor(null, process) + "] . ");

                        try { process.destroyForcibly(); } catch (Throwable ignored) {}
                    }
                }
                catch (Exception e)
                {
                    EXCEPTION_SINK.accept(e);
                    e.printStackTrace(System.err);
                }
                finally
                {
                    REGISTERED_PROCESSES.remove(process);
                }
            }, "CommonRails-ProcessWatcher-" + process.hashCode()).start();
        }
    }

    /**
     * Derive a human-friendly process descriptor for printing.
     */
    protected static String getProcessDescriptor(ProcessBuilder pb, Process process)
    {
        try
        {
            if (pb != null)
            {
                try
                {
                    java.util.List<String> cmd = pb.command();
                    if (cmd != null && !cmd.isEmpty()) return String.join(" ", cmd);
                }
                catch (Throwable ignored) {}
            }

            if (process != null)
            {
                try
                {
                    ProcessHandle.Info info = process.info();
                    if (info.command().isPresent())
                    {
                        String cmd = info.command().get();
                        String[] args = info.arguments().orElse(new String[0]);
                        if (args.length > 0) return cmd + " " + String.join(" ", args);
                        return cmd;
                    }
                }
                catch (Throwable ignored) {}

                return process.toString();
            }
        }
        catch (Throwable ignored) {}

        return "<unknown>";
    }

    public static synchronized List<Process> getRegisteredProcesses()
    {
        return new ArrayList<>(REGISTERED_PROCESSES);
    }

    public static class TelnetCallOnComplete implements Runnable
    {
        protected WebExpress WEBEXPRESS;

        public TelnetCallOnComplete(WebExpress WEBEXPRESS)
        {
            this.WEBEXPRESS = WEBEXPRESS;
        }

        @Override
        public void run()
        {
            try
            {
                Process p = this.WEBEXPRESS.TELNET_COMMUNICATION_PROXY.process;

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
                EXCEPTION_SINK.accept(e);
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
        private static final String BURGUNDY_ANSI = "\033[38;5;160m";

        private static final String SILVER_GRAY = "\033[38;2;149;157;153;1m";

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
                    System.out.print(SILVER_GRAY);
                    System.out.print(output);
                    System.out.print(RESET_ANSI);
                }
                else
                {
                    System.out.println(output);
                }

                //CommonRails.printSystemComponent(owner == null ? CommonRails.class : owner, (owner==null?CommonRails.class.hashCode():owner.hashCode()), ". IranianWedding presentation printed .");
            }
            catch (Exception e)
            {
                EXCEPTION_SINK.accept(e);
                e.printStackTrace(System.err);
            }
        }
    }

    /** Print a line in lime green (ANSI 118) — used for positive status reports. */
    public static void printLimeGreen(String text)
    {
        System.out.println("\033[38;5;118m" + text + ANSI_RESET);
    }

    /** Print a line in deep red (ANSI 160) — used for failure/warning status reports. */
    public static void printDeepRed(String text)
    {
        System.out.println(ANSI_DEEP_RED + text + ANSI_RESET);
    }

    /**
     * Same as printSystemComponent but uses an explicit ANSI color for the Object ID digits.
     * Delegates to the standard method after patching the OID color — identical animation, no blink.
     */
    public static void printSystemComponent(Object object, Integer hashcode, String line, String oidColor)
    {
        // Temporarily override resolveOidColor by building the reference manually only for the hashcode
        // then delegating the full pipeline to the standard method via a thin wrapper object
        // whose class name maps to a known color — instead, we patch at the reference level directly.

        String inner     = "Current: @" + object.getClass().getSimpleName();
        int    innerPad  = Math.max(0, CLASSNAME_TOTAL_WIDTH - inner.length());
        String classname = "[" + inner + " ".repeat(innerPad) + "]";

        String compliant_hashcode = String.format("%010d", hashcode);
        String colored_hashcode   = USE_COLORED_OUTPUT
            ? oidColor + compliant_hashcode + ANSI_RESET
            : compliant_hashcode;

        String object_id = "-- : [Object ID: " + colored_hashcode + "]";

        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
        formatter.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        String date = "[Date: " + formatter.format(new Date()) + "]";

        // Run the same token-uppercasing and keyword pipeline as the standard method
        String lineFixed = line;
        if (lineFixed != null && !lineFixed.isEmpty())
        {
            int len = lineFixed.length(), i = 0;
            while (i < len && !Character.isLetterOrDigit(lineFixed.charAt(i))) i++;
            int s1 = i;
            while (i < len && (Character.isLetterOrDigit(lineFixed.charAt(i)) || lineFixed.charAt(i) == '_')) i++;
            if (s1 < i)
                lineFixed = lineFixed.substring(0, s1) + lineFixed.substring(s1, i).toUpperCase() + lineFixed.substring(i);

            String[] keywords = {"telnet","proxy","installer","communicator","webexpress","messagequeuesorter","messagequeuehandler","serversocket"};
            for (String kw : keywords)
                lineFixed = lineFixed.replaceAll("(?i)\\b" + java.util.regex.Pattern.quote(kw) + "\\b", kw.toUpperCase());

            try
            {
                lineFixed = lineFixed.replaceAll("(?i)\\bJAVA\\b", ANSI_WHITE + "JAVA" + ANSI_RESET);
                lineFixed = lineFixed.replaceAll("™", ANSI_DEEP_RED + "™" + ANSI_RESET);
                lineFixed = lineFixed.replaceAll("(?i)\\bNitroExpress\\b", ANSI_SILVER + "NitroExpress" + ANSI_RESET);
                lineFixed = lineFixed.replaceAll("(?i)National Finance", ANSI_SILVER + "National Finance" + ANSI_RESET);
            }
            catch (Throwable ignored) {}
        }

        String reference = object_id + " " + date + " " + classname + " " + lineFixed;

        try { NationalDriver.record(reference); } catch (Throwable ignored) {}

        CommonRails.delayableFinePrinter(reference, 21);
    }

    // Expose OID color constants for external callers (e.g. DB status)
    public static final String COLOR_LIME_GREEN     = "\033[38;5;118m";  // connected
    public static final String COLOR_TANGERINE      = "\033[38;5;214m";  // XML fallback
    public static final String COLOR_STANDARD_RED   = "\033[38;5;160m";  // full failure
    public static final String COLOR_YELLOW         = "\033[38;5;226m";  // warning / stopped
}
