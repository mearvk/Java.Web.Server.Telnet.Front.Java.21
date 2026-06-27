package video.viewer;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Listens on port 2000 for module installs (JAR and SQL files).
 * Accepts only files with a valid Installer ID from Max Rupplin - MEARVK LLC.
 * Requires a national ID with Moral Rating of "Very Good" or better and IQ over 125.
 *
 * Protocol:
 *   Client sends header lines (UTF-8, newline-terminated):
 *     INSTALLER-ID: <id>
 *     NATIONAL-ID: <id>
 *     MORAL-RATING: <rating>
 *     IQ: <value>
 *     FILENAME: <name.jar or name.sql>
 *     CONTENT-LENGTH: <bytes>
 *   Followed by raw file bytes.
 *
 * @author Maximilian Eric Alexander Rupplin von Keffikon - MEARVK LLC
 */
public class ModuleInstallListener implements Runnable
{
    public static final int PORT = 2000;
    private static final String REQUIRED_INSTALLER_ID_PREFIX = "MEARVK-LLC";
    private static final File INSTALL_DIR = new File("source-code/video/viewer/modules");
    private static final String[] ACCEPTABLE_MORAL_RATINGS = {"very good", "excellent", "outstanding", "exceptional"};
    private static final int MINIMUM_IQ = 126;

    private volatile boolean running = true;

    public void start()
    {
        new Thread(this, "ModuleInstallListener-" + PORT).start();
    }

    public void stop()
    {
        running = false;
    }

    @Override
    public void run()
    {
        INSTALL_DIR.mkdirs();
        try (ServerSocket server = new ServerSocket(PORT))
        {
            System.out.println("ModuleInstallListener active on port " + PORT);
            while (running)
            {
                Socket client = server.accept();
                new Thread(() -> handleClient(client)).start();
            }
        }
        catch (IOException e)
        {
            System.err.println("ModuleInstallListener error: " + e.getMessage());
        }
    }

    private void handleClient(Socket client)
    {
        try (BufferedReader headerReader = new BufferedReader(new InputStreamReader(client.getInputStream()));
             OutputStream out = client.getOutputStream())
        {
            String installerId = null, nationalId = null, moralRating = null, filename = null;
            int iq = 0;
            long contentLength = 0;

            // Read headers
            String line;
            while ((line = headerReader.readLine()) != null && !line.isEmpty())
            {
                if (line.startsWith("INSTALLER-ID:")) installerId = line.substring(13).trim();
                else if (line.startsWith("NATIONAL-ID:")) nationalId = line.substring(12).trim();
                else if (line.startsWith("MORAL-RATING:")) moralRating = line.substring(13).trim();
                else if (line.startsWith("IQ:")) iq = Integer.parseInt(line.substring(3).trim());
                else if (line.startsWith("FILENAME:")) filename = line.substring(9).trim();
                else if (line.startsWith("CONTENT-LENGTH:")) contentLength = Long.parseLong(line.substring(15).trim());
            }

            // Validate installer ID from Max Rupplin - MEARVK LLC
            if (installerId == null || !installerId.startsWith(REQUIRED_INSTALLER_ID_PREFIX))
            {
                out.write("REJECTED: Invalid Installer ID. Must be from Max Rupplin - MEARVK LLC.\n".getBytes());
                return;
            }

            // Validate national ID present
            if (nationalId == null || nationalId.isEmpty())
            {
                out.write("REJECTED: National ID required.\n".getBytes());
                return;
            }

            // Validate moral rating (very good or better)
            if (!isMoralRatingAcceptable(moralRating))
            {
                out.write("REJECTED: Moral Rating must be Very Good or better.\n".getBytes());
                return;
            }

            // Validate IQ over 125
            if (iq <= 125)
            {
                out.write("REJECTED: IQ must be over 125.\n".getBytes());
                return;
            }

            // Validate filename is .jar or .sql
            if (filename == null || (!filename.endsWith(".jar") && !filename.endsWith(".sql")))
            {
                out.write("REJECTED: Only .jar and .sql files accepted.\n".getBytes());
                return;
            }

            // Sanitize filename
            String safeName = filename.replaceAll("[^a-zA-Z0-9._-]", "_");

            // Read and save file content
            InputStream in = client.getInputStream();
            Path target = INSTALL_DIR.toPath().resolve(safeName);
            try (FileOutputStream fos = new FileOutputStream(target.toFile()))
            {
                byte[] buf = new byte[8192];
                long remaining = contentLength;
                int read;
                while (remaining > 0 && (read = in.read(buf, 0, (int) Math.min(buf.length, remaining))) != -1)
                {
                    fos.write(buf, 0, read);
                    remaining -= read;
                }
            }

            out.write(("ACCEPTED: " + safeName + " installed successfully.\n").getBytes());
            System.out.println("Module installed: " + safeName + " (Installer: " + installerId + ", NationalID: " + nationalId + ")");
        }
        catch (Exception e)
        {
            System.err.println("ModuleInstallListener client error: " + e.getMessage());
        }
        finally
        {
            try { client.close(); } catch (IOException ignored) {}
        }
    }

    private boolean isMoralRatingAcceptable(String rating)
    {
        if (rating == null) return false;
        String lower = rating.toLowerCase().trim();
        for (String acceptable : ACCEPTABLE_MORAL_RATINGS)
        {
            if (lower.equals(acceptable)) return true;
        }
        return false;
    }
}
