import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.HexFormat;

/**
 * NWE Module Installer — Standalone JAR
 * =======================================
 * Listens on port 8888. Accepts module JARs ONLY from verified NWE installations.
 *
 * Protocol:
 *   1. Client connects on port 8888
 *   2. Client sends: INSTALL <filename> <sha256hex> <bytecount>\r\n
 *   3. Server verifies sender is NWE (checks public.key on GitHub)
 *   4. Server responds: READY\r\n
 *   5. Client sends raw bytes
 *   6. Server verifies SHA-256, installs if match
 *
 * Copy feature:
 *   - COPY <target-host>\r\n
 *   - Sends this JAR via HTTP POST to target:80 if target has public.key on GitHub
 *
 * This is NOT part of NWE. It is a standalone, downloadable, system-aware installer.
 */
public class NWEModuleInstaller
{
    private static final int PORT = 8888;
    private static final String MODULES_DIR = "modules";
    private static final String PUBLIC_KEY_URL =
        "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    private static final String SELF_JAR = "nwe-module-installer.jar";

    public static void main(String[] args) throws Exception
    {
        Files.createDirectories(Path.of(MODULES_DIR));
        System.out.println("[NWE Module Installer] Listening on port " + PORT);
        System.out.println("[NWE Module Installer] Accepts modules from NWE only.");

        try (ServerSocket server = new ServerSocket(PORT))
        {
            while (true)
            {
                Socket client = server.accept();
                Thread.ofVirtual().start(() -> handle(client));
            }
        }
    }

    private static void handle(Socket client)
    {
        String remoteIp = client.getInetAddress().getHostAddress();
        System.out.println("[NWE Module Installer] Connection from " + remoteIp);

        try (
            BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
            OutputStream out = client.getOutputStream()
        )
        {
            // Verify sender is NWE (public.key must be on GitHub)
            if (!verifyPublicKey())
            {
                out.write("DENIED public.key not found on GitHub\r\n".getBytes());
                out.flush();
                return;
            }

            String line = in.readLine();
            if (line == null) return;

            if (line.startsWith("INSTALL "))
                handleInstall(line, client.getInputStream(), out);
            else if (line.startsWith("COPY "))
                handleCopy(line, out);
            else
                out.write("UNKNOWN COMMAND\r\n".getBytes());

            out.flush();
        }
        catch (Exception e) { System.err.println("[ERROR] " + e.getMessage()); }
        finally { try { client.close(); } catch (Exception ignored) {} }
    }

    private static void handleInstall(String header, InputStream rawIn, OutputStream out) throws Exception
    {
        // INSTALL <filename> <sha256hex> <bytecount>
        String[] parts = header.split("\\s+", 4);
        if (parts.length < 4)
        {
            out.write("ERROR Usage: INSTALL <filename> <sha256> <bytecount>\r\n".getBytes());
            return;
        }

        String filename = parts[1];
        String expectedSha = parts[2].toLowerCase();
        int byteCount = Integer.parseInt(parts[3]);

        if (byteCount <= 0 || byteCount > 100 * 1024 * 1024)
        {
            out.write("ERROR Invalid byte count\r\n".getBytes());
            return;
        }

        out.write("READY\r\n".getBytes());
        out.flush();

        // Read bytes
        byte[] data = new byte[byteCount];
        int read = 0;
        while (read < byteCount)
        {
            int r = rawIn.read(data, read, byteCount - read);
            if (r == -1) break;
            read += r;
        }

        // Verify SHA-256
        String actualSha = sha256(data);
        if (!actualSha.equals(expectedSha))
        {
            out.write(("REJECTED SHA mismatch: expected " + expectedSha + " got " + actualSha + "\r\n").getBytes());
            System.out.println("[REJECTED] " + filename + " SHA mismatch");
            return;
        }

        // Install
        Path dest = Path.of(MODULES_DIR, filename);
        Files.write(dest, data);
        out.write(("INSTALLED " + filename + " (" + byteCount + " bytes, SHA verified)\r\n").getBytes());
        System.out.println("[INSTALLED] " + filename + " — " + byteCount + " bytes, SHA OK");
    }

    private static void handleCopy(String header, OutputStream out) throws Exception
    {
        // COPY <target-host>
        String[] parts = header.split("\\s+", 2);
        if (parts.length < 2)
        {
            out.write("ERROR Usage: COPY <target-host>\r\n".getBytes());
            return;
        }

        String targetHost = parts[1].trim();

        // Verify target has public.key (authorized NWE installation)
        if (!verifyPublicKey())
        {
            out.write("DENIED Cannot copy — public.key not verified\r\n".getBytes());
            return;
        }

        // Send this JAR to target:80 via HTTP POST
        Path jarPath = Path.of(SELF_JAR);
        if (!Files.exists(jarPath))
        {
            out.write("ERROR Self JAR not found at: nwe-module-installer.jar\r\n".getBytes());
            return;
        }

        byte[] jarBytes = Files.readAllBytes(jarPath);
        String sha = sha256(jarBytes);

        URL url = URI.create("http://" + targetHost + ":80/install").toURL();
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setRequestProperty("Content-Type", "application/octet-stream");
        conn.setRequestProperty("X-Filename", SELF_JAR);
        conn.setRequestProperty("X-SHA256", sha);
        conn.setRequestProperty("Content-Length", String.valueOf(jarBytes.length));
        conn.getOutputStream().write(jarBytes);
        conn.getOutputStream().flush();

        int code = conn.getResponseCode();
        if (code == 200)
        {
            out.write(("COPIED " + SELF_JAR + " to " + targetHost + ":80 (SHA: " + sha + ")\r\n").getBytes());
            System.out.println("[COPIED] JAR sent to " + targetHost + ":80");
        }
        else
        {
            out.write(("FAILED HTTP " + code + " from " + targetHost + "\r\n").getBytes());
        }
    }

    private static boolean verifyPublicKey()
    {
        try
        {
            HttpURLConnection conn = (HttpURLConnection) URI.create(PUBLIC_KEY_URL).toURL().openConnection();
            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            return conn.getResponseCode() == 200;
        }
        catch (Exception e) { return false; }
    }

    private static String sha256(byte[] data)
    {
        try
        {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(data));
        }
        catch (Exception e) { return ""; }
    }
}
