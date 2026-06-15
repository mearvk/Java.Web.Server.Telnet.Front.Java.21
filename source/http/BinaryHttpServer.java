package http;

import commons.CommonRails;
import configuration.NitroWebExpressConfig;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.UUID;

/**
 * BinaryHttpServer — port 49144
 *
 * Accepts a raw TCP connection. Client sends:
 *   PUT <filename>\n<binary-bytes>
 *   GET <url>\n
 *
 * PUT: reads binary data, writes it to APACHE_DIR/<uuid>-<filename>,
 *      returns the resulting HTTP URL.
 *
 * GET: downloads the given URL, saves it to APACHE_DIR/<uuid>-<basename>,
 *      returns the resulting HTTP URL.
 *
 * The Apache2 document root is read from nwe-config.xml <apache-root>
 * (default: /var/www/html/nwe).  The public base URL is read from
 * <apache-url> (default: http://localhost/nwe).
 */
public class BinaryHttpServer extends Thread
{
    public static final int PORT = 49144;

    /** Apache2 document-root subdirectory where files are stored. */
    private static final Path   APACHE_DIR  = resolveApacheDir();
    private static final String APACHE_URL  = resolveApacheUrl();

    private final String HOST;
    private ServerSocket SERVER_SOCKET;

    public BinaryHttpServer(final String HOST)
    {
        if (HOST == null) throw new SecurityException("//bodi/connect");
        this.HOST = HOST;
        this.setName("BinaryHttpServer");
        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            SERVER_SOCKET = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". BinaryHttpServer listening on port " + PORT
                + " | apache-dir=" + APACHE_DIR + " | base-url=" + APACHE_URL + " .");
            while (!Thread.currentThread().isInterrupted())
            {
                Socket client = SERVER_SOCKET.accept();
                Thread h = new Thread(() -> handle(client));
                h.setDaemon(true);
                h.start();
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private void handle(final Socket CLIENT)
    {
        try (
            DataInputStream  in  = new DataInputStream(new BufferedInputStream(CLIENT.getInputStream()));
            BufferedWriter   out = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream()))
        ) {
            // First line: "<COMMAND> <arg>"
            String header = readLine(in);
            if (header == null || header.isBlank()) { writeLine(out, "ERR empty command"); return; }

            String[] parts = header.split(" ", 2);
            if (parts.length < 2) { writeLine(out, "ERR usage: PUT <filename> | GET <url>"); return; }

            String cmd = parts[0].toUpperCase();
            String arg = parts[1].trim();

            switch (cmd)
            {
                case "PUT" -> writeLine(out, handlePut(arg, in));
                case "GET" -> writeLine(out, handleGet(arg));
                default    -> writeLine(out, "ERR unknown command: " + cmd);
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        finally { try { CLIENT.close(); } catch (Exception ignored) {} }
    }

    /** Read binary payload from stream, write to apache dir, return URL. */
    private String handlePut(final String FILENAME, final DataInputStream IN) throws Exception
    {
        String safe  = safeName(FILENAME);
        String uid   = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        Path   dest  = APACHE_DIR.resolve(uid + "-" + safe);

        // Read 4-byte big-endian length prefix, then that many bytes
        int len = IN.readInt();
        if (len <= 0 || len > 256 * 1024 * 1024)
            return "ERR invalid length: " + len;

        byte[] data = new byte[len];
        IN.readFully(data);
        Files.write(dest, data);

        String url = APACHE_URL + "/" + dest.getFileName();
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". BinaryHttpServer PUT " + safe + " (" + len + "B) → " + url + " .");
        return "OK " + url;
    }

    /** Download a URL, save to apache dir, return new local URL. */
    private String handleGet(final String URL_STR) throws Exception
    {
        // Validate: must be http or https only
        if (!URL_STR.startsWith("http://") && !URL_STR.startsWith("https://"))
            return "ERR only http/https URLs accepted";

        URL url = new URI(URL_STR).toURL();

        String basename  = safeName(Path.of(url.getPath()).getFileName() != null
            ? Path.of(url.getPath()).getFileName().toString() : "file");
        String uid  = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        Path   dest = APACHE_DIR.resolve(uid + "-" + basename);

        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setConnectTimeout(10_000);
        conn.setReadTimeout(30_000);
        conn.setRequestProperty("User-Agent", "NWE-BinaryHttpServer/1.0");

        try (InputStream is = conn.getInputStream();
             OutputStream os = new FileOutputStream(dest.toFile()))
        {
            is.transferTo(os);
        }

        String result = APACHE_URL + "/" + dest.getFileName();
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". BinaryHttpServer GET " + URL_STR + " → " + result + " .");
        return "OK " + result;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /** Strip everything except safe filename characters. */
    private static String safeName(final String NAME)
    {
        String base = Path.of(NAME).getFileName().toString();
        return base.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    /** Read a newline-terminated line from a DataInputStream (no buffering of binary). */
    private static String readLine(final DataInputStream IN) throws Exception
    {
        StringBuilder sb = new StringBuilder();
        int b;
        while ((b = IN.read()) != -1)
        {
            if (b == '\n') break;
            if (b != '\r') sb.append((char) b);
        }
        return sb.toString();
    }

    private static void writeLine(final BufferedWriter OUT, final String LINE)
    {
        try { OUT.write(LINE + "\r\n"); OUT.flush(); } catch (Exception ignored) {}
    }

    private static Path resolveApacheDir()
    {
        String configured = null;
        try { configured = NitroWebExpressConfig.get("apache-root"); } catch (Exception ignored) {}
        Path preferred = Paths.get(configured != null && !configured.isBlank() ? configured : "/var/www/html/nwe");
        try
        {
            Files.createDirectories(preferred);
            if (Files.isWritable(preferred)) return preferred;
        }
        catch (Exception ignored) {}

        // Not writable — diagnose and fall back
        boolean apacheInstalled = new java.io.File("/usr/sbin/apache2").exists()
            || new java.io.File("/usr/sbin/httpd").exists();
        if (!apacheInstalled)
            System.out.println("[BinaryHttpServer] Apache2 not installed — run: bash bash/NWE.install.sh");
        else
            System.out.println("[BinaryHttpServer] " + preferred + " not writable — start NWE via: bash scripts/Startup.sh (auto-escalates to sudo)");

        Path fallback = Paths.get("nwe-files");
        try { Files.createDirectories(fallback); } catch (Exception ignored) {}
        System.out.println("[BinaryHttpServer] Using local fallback: " + fallback.toAbsolutePath());
        return fallback;
    }

    private static String resolveApacheUrl()
    {
        try
        {
            String v = NitroWebExpressConfig.get("apache-url");
            return (v != null && !v.isBlank()) ? v : "http://localhost/nwe";
        }
        catch (Exception e) { return "http://localhost/nwe"; }
    }
}
