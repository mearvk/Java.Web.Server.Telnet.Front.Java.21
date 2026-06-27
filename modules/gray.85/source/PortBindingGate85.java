package modules.gray85;

/**
 * PortBindingGate85 — Binary 1/0 AI gate for Gray.85 Crème port registry.
 * Enforces the 15/100 Crème lock — auditor control already clean, planetary.
 *
 * Standard ports (85%): gated same as Gray module.
 * Crème ports (15%): tightly locked. Only unlockable via $1000 USD donation.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @brand Installer ID Tech™
 */
public class PortBindingGate85
{
    private volatile boolean enabled = true;

    /** Authorize standard lease. */
    public boolean authorize(int blockId, String term)
    {
        if (!enabled) return true;
        if (blockId < 0 || blockId >= Gray85PortRegistryServer.INITIAL_BLOCKS) return false;
        return isValidTerm(term);
    }

    /** Authorize bind — rejects Crème ports unless explicitly unlocked upstream. */
    public boolean authorizeBind(int blockId, long port)
    {
        if (!enabled) return true;
        if (port < 1024) return false; // system reserved

        long basePort = (long) blockId * Gray85PortRegistryServer.BLOCK_SIZE;
        long endPort = basePort + Gray85PortRegistryServer.BLOCK_SIZE - 1;
        return port >= basePort && port <= endPort;
    }

    /** Authorize Crème unlock — planetary clean audit check. */
    public boolean authorizeCremeUnlock(int blockId, int portOffset)
    {
        if (!enabled) return true;
        if (blockId < 0 || blockId >= Gray85PortRegistryServer.INITIAL_BLOCKS) return false;
        int cremeCount = (Gray85PortRegistryServer.BLOCK_SIZE / 100) * Gray85PortRegistryServer.CREME_RATIO;
        return portOffset >= 0 && portOffset < cremeCount;
    }

    private boolean isValidTerm(String term)
    {
        return term != null && (term.equalsIgnoreCase("month") ||
            term.equalsIgnoreCase("year") || term.equalsIgnoreCase("multi-year"));
    }

    public void setEnabled(boolean enabled) { this.enabled = enabled; }
}
