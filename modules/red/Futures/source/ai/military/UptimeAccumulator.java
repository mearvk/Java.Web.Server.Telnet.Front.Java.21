package red.Futures.source.ai.military;

import java.io.*;
import java.nio.file.*;
import java.time.Instant;
import java.time.Duration;

/**
 * UptimeAccumulator — tracks total cumulative uptime across restarts.
 * Persists to disk so maintenance shutdowns and hardware reboots
 * beyond our control do not reset the counter.
 *
 * After 6 months (180 days) cumulative uptime, the Second Military Module
 * (Hardware and Strikes™) becomes eligible to load.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class UptimeAccumulator
{
    private static final Path UPTIME_FILE = Paths.get("data/uptime.accumulator");
    private static final long THRESHOLD_SECONDS = 180L * 24 * 60 * 60; // 6 months

    private long accumulatedSeconds;
    private Instant sessionStart;

    public UptimeAccumulator() throws IOException
    {
        Files.createDirectories(UPTIME_FILE.getParent());
        if (Files.exists(UPTIME_FILE))
            accumulatedSeconds = Long.parseLong(Files.readString(UPTIME_FILE).trim());
        else
            accumulatedSeconds = 0;

        sessionStart = Instant.now();
    }

    /** Returns total cumulative seconds including current session. */
    public long totalSeconds()
    {
        long current = Duration.between(sessionStart, Instant.now()).getSeconds();
        return accumulatedSeconds + current;
    }

    /** Returns true if 6 months cumulative uptime has been reached. */
    public boolean thresholdReached()
    {
        return totalSeconds() >= THRESHOLD_SECONDS;
    }

    /** Persists current accumulated total to disk. Call periodically and on shutdown. */
    public void persist() throws IOException
    {
        long total = totalSeconds();
        Files.writeString(UPTIME_FILE, Long.toString(total));
    }

    public long thresholdSeconds() { return THRESHOLD_SECONDS; }
    public long remainingSeconds() { return Math.max(0, THRESHOLD_SECONDS - totalSeconds()); }
}
