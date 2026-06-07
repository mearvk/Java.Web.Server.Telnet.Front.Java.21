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
    public static void setExceptionSink(final java.util.function.Consumer<Exception> SINK)
    {
        if (SINK != null) EXCEPTION_SINK = SINK;
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
    private static String resolveOidColor(final String SIMPLECLASSNAME)
    {
        if (SIMPLECLASSNAME == null) return OID_DEFAULT;

        String low = SIMPLECLASSNAME.toLowerCase();

        if (low.equals("main"))
            return "\033[31m";

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

    /**
     * Maps a class name to a grayscale ANSI 256 shade based on its proximity to US law.
     * ANSI 256 grayscale ramp: 232 (near-black) → 255 (near-white).
     *
     * Theory of term:
     *   - Classes that embody or enforce US law (security, national ID, auth, exceptions,
     *     encryption, admin, signatory) are most lawful → darkest (toward black, 232).
     *   - Classes that are pure infrastructure / utility with no legal character
     *     (messaging, timing, sim, telnet I/O) → lightest (toward white, 255).
     *   - All others fall in between proportionally.
     *
     * Scale (ANSI grayscale code):
     *   232  most lawful   — security, national authority, authentication
     *   236                — encryption, admin, exceptions
     *   240                — database, finance, bitcoin
     *   245                — connections, server infrastructure
     *   250                — commons, output, printing
     *   255  least lawful  — messaging, timing, sim, telnet I/O
     */
    /** Two shades darker than terminal reset (255); used for [Current: @ClassName] field. */
    private static final String ANSI_NEAR_RESET_DARK2 = "\033[38;5;253m";

    /**
     * Scores a class name across four concern axes and maps the sum to an ANSI-256 grayscale color.
     *
     * AXES & MAX POINTS (total = 13):
     *
     * 1. Platonic Form proximity (0–4):
     *    How near to the Form of the Good (Republic).
     *    4 = Philosopher-King (sovereign, guardian, identity)
     *    3 = Episteme / anamnesis (knowledge, record, truth-preservation)
     *    2 = Demiourgoi / sophrosyne (commerce, material stewardship)
     *    1 = Auxiliaries / andreia (infrastructure, coordination)
     *    0 = Eikasia / shadow (raw conduit, simulation, I/O)
     *
     * 2. Etymology — civic rootedness (0–3):
     *    3 = Latin/Greek civic origin: nationalis, securitas, authentikos, signatorius
     *    2 = Latin disciplinary origin: exceptio, persistere, kryptos
     *    1 = Romance/Germanic utility: connectere, servire, communis
     *    0 = Modern portmanteau or purely technical: queue, telnet, sim
     *
     * 3. Social program — contribution to the polis (0–3):
     *    3 = Direct: state protection, lawful identity, civic record
     *    2 = Indirect: economic participation, infrastructure enabling cooperation
     *    1 = Facilitative: shared language, utilities all classes depend on
     *    0 = Neutral conduit: carries meaning without producing civic value
     *
     * 4. Ethics — weight of obligation (0–3):
     *    3 = Deontological duty (justice, protection of the governed)
     *    2 = Stewardship (proportional exchange, accountability)
     *    1 = Virtue of reliability (service, accessibility)
     *    0 = Instrumental (value from what is conveyed, not the conveying)
     *
     * SPECTRUM:
     *    score 0  → ANSI 238 (darkest in range — least normative, pure shadow)
     *    score 13 → ANSI 255 (pure white / at reset — most lawful, nearest Form of the Good)
     *    intermediate scores interpolate linearly across 238–255 (17-step range, ~1.31 per point)
     */
    private static String resolveLawfulness(final String SIMPLECLASSNAME)
    {
        if (SIMPLECLASSNAME == null || !USE_COLORED_OUTPUT) return "";
        String low = SIMPLECLASSNAME.toLowerCase();

        int plato = 0, etym = 0, social = 0, ethics = 0;

        // ── Platonic Form proximity ───────────────────────────────────────────
        if (low.contains("national") || low.contains("security") || low.contains("auth")
                || low.contains("admin") || low.contains("signatory") || low.contains("bodi")
                || low.contains("port") || low.contains("cia") || low.contains("fbi"))
            plato = 4;
        else if (low.contains("encrypt") || low.contains("exception") || low.contains("persistence")
                || low.contains("listener") || low.contains("handler"))
            plato = 3;
        else if (low.contains("finance") || low.contains("store") || low.contains("datasource")
                || low.contains("bitcoin") || low.contains("trader") || low.contains("wallet")
                || low.contains("ascii") || low.contains("signature") || low.contains("module"))
            plato = 2;
        else if (low.contains("connection") || low.contains("server") || low.contains("express")
                || low.contains("nitro") || low.contains("poller") || low.contains("installer")
                || low.contains("driver") || low.contains("status") || low.contains("shutdown"))
            plato = 1;
        // else plato = 0 (eikasia: messaging, queue, sim, telnet, raw I/O)

        // ── Etymology — civic rootedness ──────────────────────────────────────
        if (low.contains("national") || low.contains("security") || low.contains("auth")
                || low.contains("signatory") || low.contains("admin"))
            etym = 3;
        else if (low.contains("encrypt") || low.contains("exception") || low.contains("persist")
                || low.contains("handler") || low.contains("finance") || low.contains("store"))
            etym = 2;
        else if (low.contains("connect") || low.contains("server") || low.contains("common")
                || low.contains("arith") || low.contains("driver") || low.contains("module"))
            etym = 1;
        // else etym = 0 (queue, telnet, sim, bitcoin portmanteau, raw I/O)

        // ── Social program — contribution to the polis ────────────────────────
        if (low.contains("national") || low.contains("security") || low.contains("auth")
                || low.contains("signatory") || low.contains("admin") || low.contains("bodi"))
            social = 3;
        else if (low.contains("finance") || low.contains("bitcoin") || low.contains("store")
                || low.contains("connection") || low.contains("server") || low.contains("encrypt")
                || low.contains("exception") || low.contains("installer") || low.contains("module"))
            social = 2;
        else if (low.contains("common") || low.contains("rail") || low.contains("arith")
                || low.contains("handler") || low.contains("driver") || low.contains("status"))
            social = 1;
        // else social = 0 (neutral conduit)

        // ── Ethics — weight of obligation ─────────────────────────────────────
        if (low.contains("national") || low.contains("security") || low.contains("auth")
                || low.contains("signatory") || low.contains("admin"))
            ethics = 3;
        else if (low.contains("finance") || low.contains("store") || low.contains("exception")
                || low.contains("persist") || low.contains("encrypt") || low.contains("bitcoin"))
            ethics = 2;
        else if (low.contains("server") || low.contains("connect") || low.contains("common")
                || low.contains("handler") || low.contains("driver") || low.contains("module"))
            ethics = 1;
        // else ethics = 0 (instrumental)

        // ── Map total score (0–13) → ANSI-256 grayscale (238–255) ────────────
        // Inverted: most lawful (score 13) → 255 (lightest, at/above reset)
        //           least lawful (score 0)  → 238 (darker, but above old floor)
        int score = plato + etym + social + ethics;                   // 0–13
        int code  = 238 + (int) Math.round(score * (17.0 / 13.0));   // 238–255
        return "\033[38;5;" + code + "m";
    }

    /** Return the same ANSI-256 color as resolveLawfulness but 2 shades darker (min 232). */
    private static String resolveLawfulnessDark2(final String SIMPLECLASSNAME)
    {
        String base = resolveLawfulness(SIMPLECLASSNAME);
        if (base.isEmpty()) return base;
        try
        {
            int s = base.indexOf(";5;") + 3;
            int e = base.indexOf('m', s);
            int code = Integer.parseInt(base.substring(s, e));
            return "\033[38;5;" + Math.max(232, code - 2) + "m";
        }
        catch (Exception ex) { return base; }
    }

    public static <T> Integer size(final ArrayList<T> LIST)
    {
        return LIST.size();
    }

    public static class International
    {
        public static class IranianWedding
        {
            public static void printSystemComponent(final Object OWNER)
            {
                String message = ". THE US (USA) WERE FINE AND IN FACT RELATED TO AN IRANIAN WEDDING OF REMARKABLE PRECEDENT .\n";

                CommonRails.IranianWedding.printInternationalGregorianRhetoric(OWNER, message);
            }
        }

        public static class IranWedding
        {
            public static void printSystemComponent(final Object OWNER)
            {
                String message = ". THE US United States of America (USA) were fine and in fact related to an IRAN WEDDING of REMARKABLE PRECEDENT .\n";

                CommonRails.IranianWedding.printInternationalGregorianRhetoric(OWNER, message);
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

    public static void printSystemComponent(final Object OBJECT, final Integer HASHCODE, final String LINE)
    {
        // Build the [Current: ...] field and pad the content inside the brackets to the desired total width
        String inner = "Current: @" + OBJECT.getClass().getSimpleName();
        int innerPad = Math.max(0, CLASSNAME_TOTAL_WIDTH - inner.length());
        String classname = "[" + inner + " ".repeat(innerPad) + "]";

        // classname is already the fixed-width bracketed field; use as-is
        String classnamePadded = USE_COLORED_OUTPUT
            ? resolveLawfulnessDark2(OBJECT.getClass().getSimpleName()) + classname + ANSI_RESET
            : classname;

        String compliant_hashcode = String.format("%010d", HASHCODE);

        // Color the numeric digits by OBJECT category when color output is enabled
        String colored_hashcode = USE_COLORED_OUTPUT
            ? resolveOidColor(OBJECT.getClass().getSimpleName()) + compliant_hashcode + ANSI_RESET
            : compliant_hashcode;

        String object_id = "-- : [Object ID: "+colored_hashcode+"]";

        // Use full date/time in EST for the Date field
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
        formatter.setTimeZone(TimeZone.getTimeZone("America/New_York"));

        String date = "[Date: "+formatter.format(new Date())+"]";

        // Uppercase the first alphanumeric token in the provided LINE (the fourth printed field)
        String lineFixed = LINE;
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

                    // class/OBJECT keywords
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

        // Uppercase specific keywords anywhere in the LINE when they appear as whole words
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

    public static void delayableFinePrinter(final String TEXT, final int DELAY)
    {
        // When colored output is disabled, just print a single plain line and ensure ANSI reset.
        if (!USE_COLORED_OUTPUT)
        {
            try
            {
                System.out.println(TEXT);

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
                System.out.print("\033[38;5;" + color + "m" + TEXT + "\r");

                // per-grade DELAY fixed at 20ms for a smoother, more emotive fade
                Thread.sleep(20);
            }

            System.out.print("\u001B[0m");

            Thread.sleep(200L);

            System.out.println(TEXT);

            System.out.print("\u001B[0m");
        }
        catch (Exception e)
        {
            EXCEPTION_SINK.accept(e);
            e.printStackTrace(System.err);
        }
    }

    public static boolean isConnected(final BufferedWriter WRITER)
    {
        try
        {
            WRITER.flush();

            return true;
        }
        catch (IOException e)
        {
            return false;
        }
    }

    protected static void _long(final String ORGASM, final WebExpress WEB_EXPRESS, final Integer NOT_LESS_THAN)
    {
        try
        {
            Thread.sleep(NOT_LESS_THAN);
        }
        catch (Exception e)
        {
            EXCEPTION_SINK.accept(e);
            e.printStackTrace(System.err);
        }

        switch (ORGASM)
        {
            case "TelnetCommunicator Close Hook":

                try
                {
                    TelnetCallOnComplete call_on_complete = new TelnetCallOnComplete(WEB_EXPRESS);

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
        public static Boolean isSocketConnected(final Socket SOCKET)
        {
            try
            {
                SOCKET.getOutputStream().write("".getBytes());
            }
            catch (Exception e)
            {
                return false;
            }

            return true;
        }

        public static Boolean isSocketClosed(final Socket SOCKET)
        {
            try
            {
                SOCKET.getOutputStream().write("".getBytes());
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
    public static synchronized void registerProcess(final ProcessBuilder PB, final Process PROCESS, final Object OWNER)
    {
        if (PROCESS == null) return;

        REGISTERED_PROCESSES.add(PROCESS);

        Object printer = (OWNER == null) ? CommonRails.class : OWNER;

        // derive a PROCESS descriptor from ProcessBuilder or Process info
        final String procDesc = getProcessDescriptor(PB, PROCESS);

        try
        {
            CommonRails.printSystemComponent(printer, PROCESS.hashCode(), ". CommonRails REGISTERED: " + PROCESS + " [proc: " + procDesc + "] . ");

            // Attach onExit listener
            PROCESS.onExit().thenAccept(p -> {
                try
                {
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails processExited >> PROCESS closed: " + p + " exit=" + p.exitValue() + " [proc: " + procDesc + "] . ");
                }
                catch (Throwable t)
                {
                    // Best-effort printing
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails processExited >> PROCESS closed: " + p + " [proc: " + procDesc + "] . ");
                }
                finally
                {
                    REGISTERED_PROCESSES.remove(p);
                }
            });

            // Supervisor: ensure PROCESS is not left running beyond timeout (2 hours)
            new Thread(() -> {
                try
                {
                    if (!PROCESS.waitFor(2, TimeUnit.HOURS))
                    {
                        CommonRails.printSystemComponent(printer, PROCESS.hashCode(), ". CommonRails PROCESS timeout (2 hours) exceeded; destroying: " + PROCESS + " [proc: " + procDesc + "] . ");

                        try { PROCESS.destroyForcibly(); } catch (Throwable ignored) {}
                    }
                }
                catch (Throwable t)
                {
                    // ignore supervision errors
                }
            }, "CommonRails-ProcessTimeout-" + PROCESS.hashCode()).start();
        }
        catch (Throwable t)
        {
            // Fallback: spawn a watcher thread that waits for the PROCESS
            new Thread(() -> {
                try
                {
                    boolean finished = PROCESS.waitFor(2, TimeUnit.HOURS);

                    if (finished)
                    {
                        int rv = PROCESS.exitValue();

                        CommonRails.printSystemComponent(printer, PROCESS.hashCode(), ". CommonRails processExited(watcher) >> PROCESS closed: " + PROCESS + " exit=" + rv + " [proc: " + getProcessDescriptor(null, PROCESS) + "] . ");
                    }
                    else
                    {
                        CommonRails.printSystemComponent(printer, PROCESS.hashCode(), ". CommonRails PROCESS watcher timeout (2 hours) exceeded; destroying: " + PROCESS + " [proc: " + getProcessDescriptor(null, PROCESS) + "] . ");

                        try { PROCESS.destroyForcibly(); } catch (Throwable ignored) {}
                    }
                }
                catch (Exception e)
                {
                    EXCEPTION_SINK.accept(e);
                    e.printStackTrace(System.err);
                }
                finally
                {
                    REGISTERED_PROCESSES.remove(PROCESS);
                }
            }, "CommonRails-ProcessWatcher-" + PROCESS.hashCode()).start();
        }
    }

    /**
     * Derive a human-friendly process descriptor for printing.
     */
    protected static String getProcessDescriptor(final ProcessBuilder PB, final Process PROCESS)
    {
        try
        {
            if (PB != null)
            {
                try
                {
                    java.util.List<String> cmd = PB.command();
                    if (cmd != null && !cmd.isEmpty()) return String.join(" ", cmd);
                }
                catch (Throwable ignored) {}
            }

            if (PROCESS != null)
            {
                try
                {
                    ProcessHandle.Info info = PROCESS.info();
                    if (info.command().isPresent())
                    {
                        String cmd = info.command().get();
                        String[] args = info.arguments().orElse(new String[0]);
                        if (args.length > 0) return cmd + " " + String.join(" ", args);
                        return cmd;
                    }
                }
                catch (Throwable ignored) {}

                return PROCESS.toString();
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

        public TelnetCallOnComplete(final WebExpress WEBEXPRESS)
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
        public static void printInternationalGregorianRhetoric(final Object OWNER, final String TEXT)
        {
            if (TEXT == null) return;

            String output = TEXT;

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

                //CommonRails.printSystemComponent(OWNER == null ? CommonRails.class : OWNER, (OWNER==null?CommonRails.class.hashCode():OWNER.hashCode()), ". IranianWedding presentation printed .");
            }
            catch (Exception e)
            {
                EXCEPTION_SINK.accept(e);
                e.printStackTrace(System.err);
            }
        }
    }

    /** Print a line in lime green (ANSI 118) — used for positive status reports. */
    public static void printLimeGreen(final String TEXT)
    {
        System.out.println("\033[38;5;118m" + TEXT + ANSI_RESET);
    }

    /** Print a line in deep red (ANSI 160) — used for failure/warning status reports. */
    public static void printDeepRed(final String TEXT)
    {
        System.out.println(ANSI_DEEP_RED + TEXT + ANSI_RESET);
    }

    /**
     * Print a shutdown signal in the standard component format.
     * Uses deep red for the port number to distinguish shutdown events.
     */
    public static void printShutdownSignal(final Object OWNER, final int PORT, final String PHASE)
    {
        String module;
        switch (PORT)
        {
            case 49152: module = "WebExpress";               break;
            case 49155: module = "ConnectionStatusServer";   break;
            case 49166: module = "ModuleInstallationService";break;
            case 49177: module = "ASCIICreatorServer";       break;
            case  5512: module = "AES";                      break;
            case  6682: module = "Bitcoin";                  break;
            default:    module = "Unknown";                  break;
        }
        printSystemComponent(OWNER, OWNER.hashCode(),
            "[shutdown] " + PHASE + " " + module + " port " + PORT);
    }

    /**
     * Same as printSystemComponent but uses an explicit ANSI color for the Object ID digits.
     * Delegates to the standard method after patching the OID color — identical animation, no blink.
     */
    public static void printSystemComponent(final Object OBJECT, final Integer HASHCODE, final String LINE, final String OIDCOLOR)
    {
        // Temporarily override resolveOidColor by building the reference manually only for the HASHCODE
        // then delegating the full pipeline to the standard method via a thin wrapper OBJECT
        // whose class name maps to a known color — instead, we patch at the reference level directly.

        String inner     = "Current: @" + OBJECT.getClass().getSimpleName();
        int    innerPad  = Math.max(0, CLASSNAME_TOTAL_WIDTH - inner.length());
        String classname = "[" + inner + " ".repeat(innerPad) + "]";
        String classnamePadded = USE_COLORED_OUTPUT
            ? resolveLawfulnessDark2(OBJECT.getClass().getSimpleName()) + classname + ANSI_RESET
            : classname;

        String compliant_hashcode = String.format("%010d", HASHCODE);
        String colored_hashcode   = USE_COLORED_OUTPUT
            ? OIDCOLOR + compliant_hashcode + ANSI_RESET
            : compliant_hashcode;

        String object_id = "-- : [Object ID: " + colored_hashcode + "]";

        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
        formatter.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        String date = "[Date: " + formatter.format(new Date()) + "]";

        // Run the same token-uppercasing and keyword pipeline as the standard method
        String lineFixed = LINE;
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

        String reference = object_id + " " + date + " " + classnamePadded + " " + lineFixed;

        try { NationalDriver.record(reference); } catch (Throwable ignored) {}

        CommonRails.delayableFinePrinter(reference, 21);
    }

    // Expose OID color constants for external callers (e.g. DB status)
    public static final String COLOR_LIME_GREEN     = "\033[38;5;118m";  // connected
    public static final String COLOR_TANGERINE      = "\033[38;5;214m";  // XML fallback
    public static final String COLOR_STANDARD_RED   = "\033[38;5;160m";  // full failure
    public static final String COLOR_YELLOW         = "\033[38;5;226m";  // warning / stopped
}
