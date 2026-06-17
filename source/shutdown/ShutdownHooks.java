package shutdown;

import antivirus.AntivirusScanner;
import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.File;
import java.net.Socket;

/**
 * Centralises all JVM shutdown hook registration and shutdown printing via CommonRails.
 * The bash script performs the actual OS-level kills silently; all console output goes
 * through CommonRails.printShutdownSignal / printSystemComponent.
 */
public class ShutdownHooks
{
    public static final int[] PORTS = { 49152, 49155, 49188, 49199, 49144, 49133, 5512, 6682 };

    public static void register()
    {
        Runtime.getRuntime().addShutdownHook(new Thread(ShutdownHooks::run, "ShutdownHook"));
    }

    private static void run()
    {
        ShutdownHooks owner = new ShutdownHooks();

        CommonRails.printSystemComponent(owner, owner.hashCode(), ". [shutdown] Closing server ports: 49152(WebExpress) 49155(Status) 49188(ModuleLoader) 49199(Communicator) 49144(BinaryHttp) 49133(Weather) 5512(AES) 6682(Bitcoin) .", commons.color.ColorPalette.COLOR_SHUTDOWN);

        for (int port : PORTS)
            CommonRails.printShutdownSignal(owner, port, "SIGTERM");

        // run script silently — it performs the actual kills
        try
        {
            File scriptFile = new File("scripts/bash/Shutdown.sh");

            if (!scriptFile.exists())
            {
                ExceptionHandler.dispatchShutdown(
                    new java.io.FileNotFoundException("Shutdown script not found: " + scriptFile.getAbsolutePath()));
                return;
            }

            Process proc = new ProcessBuilder("bash", scriptFile.getAbsolutePath())
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
            ExceptionHandler.dispatchShutdown(e);
        }

        stopClamAV();

        CommonRails.printSystemComponent(owner, owner.hashCode(), ". [shutdown] Done .", commons.color.ColorPalette.COLOR_SHUTDOWN);
    }

    /** Stop freshclam daemon gracefully during shutdown; log warnings to logging/clamav.log. */
    private static void stopClamAV()
    {
        try
        {
            Process p = new ProcessBuilder("systemctl", "stop", "clamav-freshclam")
                .redirectErrorStream(true)
                .start();

            String output = new java.io.BufferedReader(new java.io.InputStreamReader(p.getInputStream()))
                .lines()
                .collect(java.util.stream.Collectors.joining("\n"));

            int exit = p.waitFor();

            if (exit != 0 || !output.isBlank())
                AntivirusScanner.logClamWarning("[shutdown] clamav-freshclam stop (exit=" + exit + "): " + output);
            else
                AntivirusScanner.logClamWarning("[shutdown] clamav-freshclam stopped cleanly");
        }
        catch (Exception e)
        {
            AntivirusScanner.logClamWarning("[shutdown] clamav-freshclam stop failed: " + e.getMessage());
        }
    }

    private static boolean portStillOpen(final int PORT)
    {
        try (Socket s = new Socket("localhost", PORT)) { return true; }
        catch (Exception e) { return false; }
    }
}
