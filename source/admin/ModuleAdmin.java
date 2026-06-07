package admin;

import commons.CommonRails;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Basic administrator for ModuleInstallationService.
 * Admin credentials are loaded from the system property or env:
 *   module.admin.password  /  MODULE_ADMIN_PASSWORD
 * Defaults to "n21admin" if neither is set.
 *
 * An authenticated session token is stored in SESSIONS for the lifetime
 * of the TCP connection.
 */
public class ModuleAdmin
{
    private static final String PASSWORD = resolvePassword();

    /** Active session tokens — keyed by token string, value = nationalId of admin. */
    private static final ConcurrentHashMap<String, Long> SESSIONS = new ConcurrentHashMap<>();

    /**
     * Attempt login.  Returns a session token on success, null on failure.
     */
    public static String login(final String SUBMITTED_PASSWORD, final long NATIONAL_ID)
    {
        if (SUBMITTED_PASSWORD == null || !SUBMITTED_PASSWORD.equals(PASSWORD))
        {
            CommonRails.printSystemComponent(
                new ModuleAdmin(), ModuleAdmin.class.hashCode(),
                ". ModuleAdmin login FAILED for National ID " + NATIONAL_ID + " .");
            return null;
        }
        String token = Long.toHexString(System.nanoTime()) + Long.toHexString(NATIONAL_ID);
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

    private static String resolvePassword()
    {
        String prop = System.getProperty("module.admin.password");
        if (prop != null && !prop.isEmpty()) return prop;
        String env = System.getenv("MODULE_ADMIN_PASSWORD");
        if (env != null && !env.isEmpty()) return env;
        return "n21admin";
    }
}
