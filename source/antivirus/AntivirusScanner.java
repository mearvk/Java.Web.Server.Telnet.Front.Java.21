package antivirus;

import commons.CommonRails;
import configuration.NitroWebExpressConfig;
import exceptions.ExceptionHandler;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.stream.Stream;

/**
 * AntivirusScanner — schedules ClamAV scans and file-integrity checks
 * on NWE contents at a configurable interval read from nwe-config.xml.
 *
 * schedule values: hourly | daily | weekly | monthly | yearly
 * scan-path:       directory to scan (relative to CWD or absolute)
 *
 * On each trigger:
 *   1. Runs `clamscan -r --suppress-ok-results <scan-path>` and logs output.
 *   2. Re-hashes every .java/.class/.jar/.sh under scan-path and compares
 *      against the baseline captured at first run; reports any changes.
 *
 * @author Max Rupplin
 * @date June 09 2026
 */
public class AntivirusScanner
{
    private String schedule = null;
    private Path   scanPath = null;

    /** SHA-256 baseline: relative-path → hex digest captured on first scan. */
    private final Map<String, String> baseline = new ConcurrentHashMap<>();

    public AntivirusScanner()
    {
        String rawSchedule = NitroWebExpressConfig.antivirusSchedule();

        if (rawSchedule == null || rawSchedule.isBlank())
            this.schedule = "daily";
        else
            this.schedule = rawSchedule.trim().toLowerCase();

        String rawPath = NitroWebExpressConfig.antivirusScanPath();

        try
        {
            Path p;

            if (rawPath == null || rawPath.isBlank())
            {
                p = Path.of(".").toAbsolutePath().normalize();
            }
            else
            {
                p = Path.of(rawPath).toAbsolutePath().normalize();
            }

            if (!Files.exists(p) || !Files.isDirectory(p))
            {
                CommonRails.printSystemComponent(
                        this, this.hashCode(),
                        ". AntivirusScanner >> WARNING: scan-path does not exist or is not a directory: "
                                + rawPath + " — falling back to '.' ."
                );

                p = Path.of(".").toAbsolutePath().normalize();
            }

            this.scanPath = p;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            this.scanPath = Path.of(".").toAbsolutePath().normalize();
        }

        CommonRails.printSystemComponent(
                this, this.hashCode(),
                ". AntivirusScanner initialized — schedule=" + this.schedule
                        + " path=" + this.scanPath + " ."
        );
    }

    /** Start the scheduled executor. Returns immediately; scans run in background. */
    public void start()
    {
        long period = periodSeconds(schedule);
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". AntivirusScanner starting — schedule=" + schedule
            + " (" + period + "s) path=" + scanPath + " .");

        Executors.newSingleThreadScheduledExecutor(r ->
        {
            Thread t = new Thread(r, "AntivirusScanner");
            t.setDaemon(true);
            return t;
        }).scheduleAtFixedRate(this::scan, 0, period, TimeUnit.SECONDS);
    }

    private void scan()
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". AntivirusScanner >> starting scan of " + scanPath + " .");
        runClamScan();
        runIntegrityCheck();
    }

    private void runClamScan()
    {
        if (!clamAvailable())
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". AntivirusScanner >> clamscan not found on PATH — skipping AV scan .");
            return;
        }
        try
        {
            Process p = Runtime.getRuntime().exec(new String[]{"clamscan", "-r", "--suppress-ok-results", scanPath.toString()});

            String out = new BufferedReader(new InputStreamReader(p.getInputStream())).lines().collect(java.util.stream.Collectors.joining("\n"));

            String err = new BufferedReader(new InputStreamReader(p.getErrorStream())).lines().collect(java.util.stream.Collectors.joining("\n"));

            int exit = p.waitFor();

            if (exit == 0)
            {
                CommonRails.printSystemComponent(this, this.hashCode(), ". AntivirusScanner >> ClamAV scan CLEAN .");
            }
            else
            {
                CommonRails.printSystemComponent(this, this.hashCode(), ". AntivirusScanner >> ClamAV ALERT (exit=" + exit + "):\n" + out + "\n" + err + " .");
            }
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
    }

    private void runIntegrityCheck()
    {
        try
        {
            boolean firstRun = baseline.isEmpty();

            int changed = 0; int added = 0;

            try (Stream<Path> walk = Files.walk(scanPath))
            {
                Iterable<Path> files = () -> walk
                    .filter(Files::isRegularFile)
                    .filter(p -> {
                        String n = p.getFileName().toString();
                        return n.endsWith(".java") || n.endsWith(".class")
                            || n.endsWith(".jar")  || n.endsWith(".sh")
                            || n.endsWith(".xml")  || n.endsWith(".properties");
                    }).iterator();

                for (Path f : files)
                {
                    String key    = scanPath.relativize(f).toString();

                    String digest = sha256(Files.readAllBytes(f));

                    if (firstRun)
                    {
                        baseline.put(key, digest);

                        added++;
                    }
                    else
                    {
                        String prev = baseline.put(key, digest);

                        if (prev == null)
                        {
                            CommonRails.printSystemComponent(this, this.hashCode(), ". AntivirusScanner >> INTEGRITY NEW FILE: " + key + " .");

                            added++;
                        }
                        else if (!prev.equals(digest))
                        {
                            CommonRails.printSystemComponent(this, this.hashCode(), ". AntivirusScanner >> INTEGRITY CHANGED: " + key + " .");

                            changed++;
                        }
                    }
                }
            }

            if (firstRun)
                CommonRails.printSystemComponent(this, this.hashCode(), ". AntivirusScanner >> integrity baseline captured (" + added + " files) .");
            else
                CommonRails.printSystemComponent(this, this.hashCode(), ". AntivirusScanner >> integrity check complete — changed=" + changed + " new=" + added + " .");
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private static boolean clamAvailable()
    {
        try { return Runtime.getRuntime().exec(new String[]{"which", "clamscan"}).waitFor() == 0; }
        catch (Exception e) { return false; }
    }

    private static String sha256(final byte[] data) throws Exception
    {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(data));
    }

    /** Convert schedule name to period in seconds. */
    private static long periodSeconds(final String schedule)
    {
        return switch (schedule)
        {
            case "hourly"  -> 3_600L;
            case "weekly"  -> 7   * 86_400L;
            case "monthly" -> 30  * 86_400L;
            case "yearly"  -> 365 * 86_400L;
            default        -> 86_400L;  // daily
        };
    }
}
