package commons;

import commons.printing.ComponentPrinter;
import commons.process.ProcessRegistry;

public final class CommonRails
{
    public static java.util.function.Consumer<Exception> EXCEPTION_SINK = e -> {e.printStackTrace(System.err);};

    private static final Boolean USE_COLORED_OUTPUT = true;

    private CommonRails() {}

    public static void printSystemComponent(Object owner, int hash, String line) {
        ComponentPrinter.print(owner, hash, line);
    }

    public static void printSystemComponent(Object owner, int hash, String line, String oidColor) {
        ComponentPrinter.print(owner, hash, line);
    }

    public static void registerProcess(ProcessBuilder pb, Process p, Object owner) {
        ProcessRegistry.register(pb, p, owner);
    }

    public static void printShutdownSignal(final Object OWNER, final int PORT, final String PHASE)
    {
        String module = switch (PORT)
        {
            case 49152  -> "WebExpress";
            case 49155  -> "ConnectionStatusServer";
            case 49166  -> "ModuleInstallationService";
            case 49177  -> "ASCIICreatorServer";
            case 5512   -> "AES";
            case 6682   -> "Bitcoin";
            case 7743   -> "RSA";
            default     -> "Unknown";
        };

        printSystemComponent(OWNER, OWNER.hashCode(), "[shutdown] " + PHASE + " " + module + " port " + PORT);
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
                //EXCEPTION_SINK.accept(e);

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
            //EXCEPTION_SINK.accept(e);

            e.printStackTrace(System.err);
        }
    }

    public static void setExceptionSink(final java.util.function.Consumer<Exception> SINK)
    {
        if (SINK != null) EXCEPTION_SINK = SINK;
    }
}
