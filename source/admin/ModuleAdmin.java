package admin;

import commons.CommonRails;

import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HexFormat;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Basic administrator for ModuleInstallationService.
 * Admin credentials are loaded from the system property or env:
 *   module.admin.password  /  MODULE_ADMIN_PASSWORD
 * The server REFUSES to start if no password is configured (no default).
 *
 * An authenticated session token is stored in SESSIONS for the lifetime
 * of the TCP connection.
 */
public class ModuleAdmin
{
    private static volatile String PASSWORD = resolvePassword();

    /** Called by NweConfig after loading nwe-config.xml to apply the configured admin password. */
    public static void setPassword(final String NEW_PASSWORD)
    {
        if (NEW_PASSWORD != null && !NEW_PASSWORD.isEmpty()
            && !NEW_PASSWORD.equals("CHANGE_ME_BEFORE_DEPLOY")
            && !NEW_PASSWORD.equals("n21admin"))
            PASSWORD = NEW_PASSWORD;
    }

    /** Active session tokens — keyed by token string, value = nationalId of admin. */
    private static final ConcurrentHashMap<String, Long> SESSIONS = new ConcurrentHashMap<>();

    /** Brute-force protection: track failed attempts per IP (simple in-memory). */
    private static final ConcurrentHashMap<String, AtomicInteger> FAILED_ATTEMPTS = new ConcurrentHashMap<>();
    private static final int MAX_FAILED_ATTEMPTS = 5;

    /** SecureRandom for token generation. */
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    /**
     * Check if an IP is locked out due to too many failed attempts.
     */
    public static boolean isLockedOut(final String IP)
    {
        AtomicInteger attempts = FAILED_ATTEMPTS.get(IP);
        return attempts != null && attempts.get() >= MAX_FAILED_ATTEMPTS;
    }

    /**
     * Attempt login.  Returns a session token on success, null on failure.
     * Uses timing-safe comparison to prevent side-channel attacks.
     */
    public static String login(final String SUBMITTED_PASSWORD, final long NATIONAL_ID)
    {
        if (SUBMITTED_PASSWORD == null || PASSWORD == null)
        {
            CommonRails.printSystemComponent(
                new ModuleAdmin(), ModuleAdmin.class.hashCode(),
                ". ModuleAdmin login FAILED for National ID " + NATIONAL_ID + " — no password configured .");
            return null;
        }

        // Timing-safe comparison using MessageDigest.isEqual
        byte[] submitted = SUBMITTED_PASSWORD.getBytes();
        byte[] expected = PASSWORD.getBytes();
        if (!MessageDigest.isEqual(submitted, expected))
        {
            CommonRails.printSystemComponent(
                new ModuleAdmin(), ModuleAdmin.class.hashCode(),
                ". ModuleAdmin login FAILED for National ID " + NATIONAL_ID + " .");
            return null;
        }

        // Generate cryptographically secure session token
        byte[] tokenBytes = new byte[32];
        SECURE_RANDOM.nextBytes(tokenBytes);
        String token = HexFormat.of().formatHex(tokenBytes);

        SESSIONS.put(token, NATIONAL_ID);
        CommonRails.printSystemComponent(
            new ModuleAdmin(), ModuleAdmin.class.hashCode(),
            ". ModuleAdmin login SUCCESS for National ID " + NATIONAL_ID + " .");
        return token;
    }

    /** Returns true if the token belongs to an authenticated admin session. */
    public static boolean isAdmin(final String TOKEN)
    {
        return TOKEN != null && SESSIONS.containsKey(TOKEN);
    }

    /** Invalidate a session token on logout/disconnect. */
    public static void logout(final String TOKEN)
    {
        Long id = SESSIONS.remove(TOKEN);
        if (id != null)
            CommonRails.printSystemComponent(
                new ModuleAdmin(), ModuleAdmin.class.hashCode(),
                ". ModuleAdmin session ended for National ID " + id + " .");
    }

    /** Record a failed login attempt for brute-force protection. */
    public static void recordFailedAttempt(final String IP)
    {
        FAILED_ATTEMPTS.computeIfAbsent(IP, k -> new AtomicInteger(0)).incrementAndGet();
    }

    /** Reset failed attempts (e.g., after successful login). */
    public static void resetFailedAttempts(final String IP)
    {
        FAILED_ATTEMPTS.remove(IP);
    }

    private static String resolvePassword()
    {
        String prop = System.getProperty("module.admin.password");
        if (prop != null && !prop.isEmpty()) return prop;
        String env = System.getenv("MODULE_ADMIN_PASSWORD");
        if (env != null && !env.isEmpty()) return env;
        // No default password — must be explicitly configured
        System.err.println("[SECURITY] ModuleAdmin: No admin password configured!");
        System.err.println("           Set MODULE_ADMIN_PASSWORD env var or -Dmodule.admin.password system property.");
        return null;
    }
}
