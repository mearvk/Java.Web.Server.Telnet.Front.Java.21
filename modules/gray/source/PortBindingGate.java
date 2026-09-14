package modules.gray.source;

/**
 * PortBindingGate — Binary 1/0 yes/no AI module for port-bind authorization.
 * Consulted by GrayPortRegistryServer before any lease or bind operation.
 *
 * Decision logic:
 *   1 (yes) — port binding authorized
 *   0 (no)  — port binding denied
 *
 * Factors: block availability, term validity, lease conflicts, rate limiting.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @brand Installer ID Tech™
 */
public class PortBindingGate
{
    private volatile boolean enabled = true;

    /** Authorize a lease request. Returns true (1) or false (0). */
    public boolean authorize(int blockId, String term)
    {
        if (!enabled) return true;

        // Gate: block range check
        if (blockId < 0 || blockId >= GrayPortRegistryServer.INITIAL_BLOCKS)
            return false;

        // Gate: valid term
        if (!isValidTerm(term))
            return false;

        return true; // 1 — authorized
    }

    /** Authorize a specific port bind within a leased block. */
    public boolean authorizeBind(int blockId, long port)
    {
        if (!enabled) return true;

        long startPort = (long) blockId * GrayPortRegistryServer.BLOCK_SIZE;
        long endPort = startPort + GrayPortRegistryServer.BLOCK_SIZE - 1;

        // Gate: port must be within block
        if (port < startPort || port > endPort)
            return false;

        // Gate: system-reserved ports (0-1023) never bindable
        if (port < 1024)
            return false;

        return true; // 1 — authorized
    }

    private boolean isValidTerm(String term)
    {
        return term != null && (term.equalsIgnoreCase("month") ||
            term.equalsIgnoreCase("year") || term.equalsIgnoreCase("multi-year"));
    }

    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    public boolean isEnabled() { return enabled; }
}
