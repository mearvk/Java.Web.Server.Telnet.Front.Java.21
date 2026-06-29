package security;

import commons.CommonRails;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * ConnectionRateLimiter — per-IP rate limiting for all NWE service ports.
 *
 * Tracks connection attempts per IP within a sliding window. IPs exceeding
 * the threshold are blocked for a cooldown period. Integrates with
 * HeuristicClassifier for persistent threat scoring.
 *
 * @author Max Rupplin
 * @date June 29 2026
 */
public final class ConnectionRateLimiter {

    private static final int MAX_CONNECTIONS_PER_MINUTE = 30;
    private static final long WINDOW_MS = 60_000L;
    private static final long BLOCK_DURATION_MS = 300_000L; // 5 minutes

    private static final Map<String, WindowCounter> COUNTERS = new ConcurrentHashMap<>();
    private static final Map<String, Long> BLOCKED = new ConcurrentHashMap<>();

    private ConnectionRateLimiter() {}

    /** Returns true if the IP is allowed to connect; false if rate-limited. */
    public static boolean allow(String ip) {
        if (ip == null) return false;

        // Check block list
        Long blockedUntil = BLOCKED.get(ip);
        if (blockedUntil != null) {
            if (System.currentTimeMillis() < blockedUntil) return false;
            BLOCKED.remove(ip);
        }

        // Increment window counter
        WindowCounter counter = COUNTERS.computeIfAbsent(ip, k -> new WindowCounter());
        if (counter.incrementAndCheck()) {
            return true;
        } else {
            BLOCKED.put(ip, System.currentTimeMillis() + BLOCK_DURATION_MS);
            CommonRails.printSystemComponent(ConnectionRateLimiter.class,
                    ConnectionRateLimiter.class.hashCode(),
                    ". RATE LIMIT: " + ip + " blocked for 5 minutes (>" + MAX_CONNECTIONS_PER_MINUTE + "/min) .");
            return false;
        }
    }

    /** Check if an IP is currently blocked. */
    public static boolean isBlocked(String ip) {
        Long blockedUntil = BLOCKED.get(ip);
        if (blockedUntil == null) return false;
        if (System.currentTimeMillis() >= blockedUntil) {
            BLOCKED.remove(ip);
            return false;
        }
        return true;
    }

    /** Manually block an IP (used by HeuristicClassifier for threat IPs). */
    public static void block(String ip, long durationMs) {
        BLOCKED.put(ip, System.currentTimeMillis() + durationMs);
    }

    /** Periodic cleanup of expired entries. Call from a scheduled task. */
    public static void cleanup() {
        long now = System.currentTimeMillis();
        BLOCKED.entrySet().removeIf(e -> now >= e.getValue());
        COUNTERS.entrySet().removeIf(e -> now - e.getValue().windowStart > WINDOW_MS * 2);
    }

    private static class WindowCounter {
        volatile long windowStart = System.currentTimeMillis();
        final AtomicInteger count = new AtomicInteger(0);

        boolean incrementAndCheck() {
            long now = System.currentTimeMillis();
            if (now - windowStart > WINDOW_MS) {
                windowStart = now;
                count.set(1);
                return true;
            }
            return count.incrementAndGet() <= MAX_CONNECTIONS_PER_MINUTE;
        }
    }
}
