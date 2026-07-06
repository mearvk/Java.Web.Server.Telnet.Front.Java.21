package red.Futures.source.ai.server;

import java.io.*;
import java.nio.file.*;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.concurrent.*;
import java.util.stream.Stream;

/**
 * OutboundPortAwareness — monitors outgoing ports 80, 443, 25, 22, 21.
 * Stores PKS/SSL certs and cookies as required.
 * Deletes stored credentials after 19+ days.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class OutboundPortAwareness
{
    private static final int[] AWARE_PORTS = {80, 443, 25, 22, 21};
    private static final int EXPIRY_DAYS = 19;
    private static final Path CERT_STORE = Paths.get("data/certs");
    private static final Path COOKIE_STORE = Paths.get("data/cookies");

    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();

    public void start() throws IOException
    {
        Files.createDirectories(CERT_STORE);
        Files.createDirectories(COOKIE_STORE);

        // Purge expired certs/cookies every hour
        scheduler.scheduleAtFixedRate(this::purgeExpired, 0, 1, TimeUnit.HOURS);

        System.out.println("[OutboundPortAwareness] Aware ports: 80, 443, 25, 22, 21");
        System.out.println("[OutboundPortAwareness] Cert store: " + CERT_STORE);
        System.out.println("[OutboundPortAwareness] Cookie store: " + COOKIE_STORE);
        System.out.println("[OutboundPortAwareness] Expiry: " + EXPIRY_DAYS + " days");
    }

    public boolean isAwarePort(int port)
    {
        for (int p : AWARE_PORTS) if (p == port) return true;
        return false;
    }

    public void storeCert(String name, byte[] certData) throws IOException
    {
        Path file = CERT_STORE.resolve(name);
        Files.write(file, certData);
    }

    public void storeCookie(String name, byte[] cookieData) throws IOException
    {
        Path file = COOKIE_STORE.resolve(name);
        Files.write(file, cookieData);
    }

    public byte[] loadCert(String name) throws IOException
    {
        Path file = CERT_STORE.resolve(name);
        return Files.exists(file) ? Files.readAllBytes(file) : null;
    }

    public byte[] loadCookie(String name) throws IOException
    {
        Path file = COOKIE_STORE.resolve(name);
        return Files.exists(file) ? Files.readAllBytes(file) : null;
    }

    private void purgeExpired()
    {
        Instant cutoff = Instant.now().minus(EXPIRY_DAYS, ChronoUnit.DAYS);
        purgeDir(CERT_STORE, cutoff);
        purgeDir(COOKIE_STORE, cutoff);
    }

    private void purgeDir(Path dir, Instant cutoff)
    {
        try (Stream<Path> files = Files.list(dir))
        {
            files.filter(Files::isRegularFile).forEach(file ->
            {
                try
                {
                    Instant modified = Files.getLastModifiedTime(file).toInstant();
                    if (modified.isBefore(cutoff))
                    {
                        Files.delete(file);
                        System.out.println("[OutboundPortAwareness] PURGED (>" + EXPIRY_DAYS + "d): " + file.getFileName());
                    }
                }
                catch (IOException ignored) {}
            });
        }
        catch (IOException ignored) {}
    }

    public void stop() { scheduler.shutdownNow(); }
}
