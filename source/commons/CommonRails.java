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
        ComponentPrinter.print(owner, hash, line, oidColor);
    }

    public static void registerProcess(ProcessBuilder pb, Process p, Object owner) {
        ProcessRegistry.register(pb, p, owner);
    }

    public static void printShutdownSignal(final Object OWNER, final int PORT, final String PHASE)
    {
        String module = switch (PORT)
        {
            case 49152 -> "NitroWebExpress";
            case 49155 -> "ConnectionStatus";
            case 49166 -> "ModuleInstallation";
            case 49177 -> "AsciiCreator";
            case 49188 -> "ModuleLoaderDaemon";
            case 49199 -> "Communicator";
            case 49200 -> "TerminalMenu";
            case 49201 -> "JapanSignalServer";
            case 49202 -> "RussiaSignalServer";
            case 49203 -> "MexicoSignalServer";
            case 49204 -> "GreeceInternationalSignalServer";
            case 49144 -> "BinaryHttp";
            case 49133 -> "Weather";
            case 5512 -> "AesCompliant";
            case 6682 -> "BitcoinCompliant";
            case 7743 -> "RsaCompliant";
            case 7744 -> "DsaCompliant";
            case 8888 -> "MiddleDirectorServer";
            default -> "Port-" + PORT;
        };

        printSystemComponent(OWNER, OWNER.hashCode(), ". [shutdown] " + PHASE + " " + module + " port " + PORT + " .", commons.color.ColorPalette.COLOR_SHUTDOWN);
    }

    public static void delayableFinePrinter(final String TEXT, final int DELAY)
    {
        if (!USE_COLORED_OUTPUT)
        {
            try
            {
                System.out.println(TEXT);
                System.out.print("\u001B[0m");
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
            return;
        }

        // Grayscale fade-in: dark grey -> full white using ANSI 256-color codes 236..255 (20 steps)
        int[] codes = new int[20];
        for (int k = 0; k < 20; k++) codes[k] = 236 + k;

        try
        {
            for (int color : codes)
            {
                System.out.print("\033[38;5;" + color + "m" + TEXT + "\r");
                Thread.sleep(21);
            }

            System.out.print("\u001B[0m");
            System.out.println(TEXT);
            System.out.print("\u001B[0m");
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }

    public static void setExceptionSink(final java.util.function.Consumer<Exception> SINK)
    {
        if (SINK != null) EXCEPTION_SINK = SINK;
    }
}
