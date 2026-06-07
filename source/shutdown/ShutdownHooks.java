package shutdown;

import commons.CommonRails;

import java.io.File;
import java.net.Socket;

/**
 * Centralises all JVM shutdown hook registration and shutdown printing via CommonRails.
 * The bash script performs the actual OS-level kills silently; all console output goes
 * through CommonRails.printShutdownSignal / printSystemComponent.
 */
public class ShutdownHooks
{
    public static final int[] PORTS = { 49152, 49155, 49166, 49177, 5512, 6682 };

    public static void register()
    {
        Runtime.getRuntime().addShutdownHook(new Thread(ShutdownHooks::run, "ShutdownHook"));
    }

    private static void run()
    {
        ShutdownHooks owner = new ShutdownHooks();

        CommonRails.printSystemComponent(owner, owner.hashCode(), "[shutdown] Closing server ports: 49152 49155 5512 6682");

        for (int port : PORTS)
            CommonRails.printShutdownSignal(owner, port, "SIGTERM");

        // run script silently — it performs the actual kills
        try
        {
            String script = new File("scripts/shutdown.sh").getAbsolutePath();
            Process proc = new ProcessBuilder("bash", script)
                    .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                    .redirectError(ProcessBuilder.Redirect.DISCARD)
                    .start();

            // grace period mirrors the script's sleep 2
            Thread.sleep(2000);

            // report any ports that needed SIGKILL
            for (int port : PORTS)
            {
                if (portStillOpen(port))
                    CommonRails.printShutdownSignal(owner, port, "SIGKILL");
            }

            proc.waitFor();
        }
        catch (Exception e)
        {
            CommonRails.EXCEPTION_SINK.accept(e);
        }

        CommonRails.printSystemComponent(owner, owner.hashCode(), "[shutdown] Done.");
    }

    private static boolean portStillOpen(final int PORT)
    {
        try (Socket s = new Socket("localhost", PORT)) { return true; }
        catch (Exception e) { return false; }
    }
}
