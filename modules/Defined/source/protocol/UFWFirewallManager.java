package modules.Defined.source.protocol;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * UFWFirewallManager — Manages UFW (Uncomplicated Firewall) rules for the Defined™ module.
 *
 * Opens ports via 'sudo ufw allow' prior to use and closes them with 'sudo ufw delete'
 * after the execution of search, data query, or retrieval.
 *
 * This ensures the server maintains minimal attack surface — ports are only open
 * during active operations.
 *
 * Managed ports (opened/closed dynamically):
 *   22 (SSH), 443 (HTTPS), 465 (SMTPS), 587 (SMTP Submission), 993 (IMAPS), 990 (FTPS)
 *
 * Persistent ports (always open, not UFW-cycled):
 *   20, 21, 25, 80, 3306, 8080, 49220, 49221
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class UFWFirewallManager
{
    private boolean enabled = true;
    private boolean sudoRequired = true;
    private Path logFile = Paths.get("logging/ufw-actions.log");

    // Track which ports are currently open (to avoid redundant operations)
    private final Map<String, Boolean> portState = new ConcurrentHashMap<>();

    // Ports managed by UFW (opened/closed dynamically)
    private static final Set<Integer> MANAGED_PORTS = Set.of(22, 443, 465, 587, 993, 990);

    // Persistent ports (not cycled)
    private static final Set<Integer> PERSISTENT_PORTS = Set.of(20, 21, 25, 80, 3306, 8080, 49220, 49221);

    public UFWFirewallManager()
    {
        try { Files.createDirectories(logFile.getParent()); } catch (IOException ignored) {}
    }

    /**
     * Open a port via UFW before use.
     * Only operates on managed ports. Persistent ports are ignored.
     *
     * @param port Port number to open
     * @param direction "in", "out", or "both"
     */
    public synchronized void openPort(int port, String direction)
    {
        if (!enabled) return;
        if (PERSISTENT_PORTS.contains(port)) return; // persistent = already open
        if (!MANAGED_PORTS.contains(port))
        {
            log("SKIP-OPEN: Port " + port + " not in managed set");
            return;
        }

        String key = port + "/" + direction;
        if (Boolean.TRUE.equals(portState.get(key)))
        {
            log("ALREADY-OPEN: " + key);
            return;
        }

        try
        {
            String rule = buildAllowRule(port, direction);
            executeUFW(rule);
            portState.put(key, true);
            log("OPENED: " + key + " (rule: " + rule + ")");
        }
        catch (Exception e)
        {
            log("OPEN-ERROR: " + key + " — " + e.getMessage());
        }
    }

    /**
     * Close a port via UFW after execution of search/query/retrieval.
     * Only operates on managed ports.
     *
     * @param port Port number to close
     * @param direction "in", "out", or "both"
     */
    public synchronized void closePort(int port, String direction)
    {
        if (!enabled) return;
        if (PERSISTENT_PORTS.contains(port)) return;
        if (!MANAGED_PORTS.contains(port)) return;

        String key = port + "/" + direction;
        if (!Boolean.TRUE.equals(portState.get(key)))
        {
            log("ALREADY-CLOSED: " + key);
            return;
        }

        try
        {
            String rule = buildDeleteRule(port, direction);
            executeUFW(rule);
            portState.put(key, false);
            log("CLOSED: " + key + " (rule: " + rule + ")");
        }
        catch (Exception e)
        {
            log("CLOSE-ERROR: " + key + " — " + e.getMessage());
        }
    }

    /**
     * Close all managed ports. Called on shutdown.
     */
    public void closeAllManagedPorts()
    {
        for (Map.Entry<String, Boolean> entry : portState.entrySet())
        {
            if (Boolean.TRUE.equals(entry.getValue()))
            {
                String[] parts = entry.getKey().split("/");
                int port = Integer.parseInt(parts[0]);
                String direction = parts[1];
                closePort(port, direction);
            }
        }
        log("ALL-MANAGED-PORTS-CLOSED");
    }

    /**
     * Ensure persistent ports are open (called on startup).
     */
    public void ensurePersistentPorts()
    {
        for (int port : PERSISTENT_PORTS)
        {
            try
            {
                String rule = "allow " + port;
                executeUFW(rule);
                log("PERSISTENT-ENSURED: " + port);
            }
            catch (Exception e)
            {
                log("PERSISTENT-ERROR: " + port + " — " + e.getMessage());
            }
        }
    }

    /**
     * Get current status of all managed ports.
     */
    public Map<String, Boolean> getPortStates()
    {
        return Collections.unmodifiableMap(portState);
    }

    /**
     * Check if a port is currently open.
     */
    public boolean isPortOpen(int port, String direction)
    {
        return Boolean.TRUE.equals(portState.get(port + "/" + direction));
    }

    private String buildAllowRule(int port, String direction)
    {
        if ("out".equals(direction))
            return "allow out " + port + "/tcp";
        else if ("in".equals(direction))
            return "allow in " + port + "/tcp";
        else
            return "allow " + port + "/tcp";
    }

    private String buildDeleteRule(int port, String direction)
    {
        if ("out".equals(direction))
            return "delete allow out " + port + "/tcp";
        else if ("in".equals(direction))
            return "delete allow in " + port + "/tcp";
        else
            return "delete allow " + port + "/tcp";
    }

    /**
     * Execute a UFW command. Uses sudo if required.
     */
    private void executeUFW(String rule) throws Exception
    {
        List<String> cmd = new ArrayList<>();
        if (sudoRequired) cmd.add("sudo");
        cmd.add("ufw");
        cmd.addAll(Arrays.asList(rule.split("\\s+")));

        ProcessBuilder pb = new ProcessBuilder(cmd);
        pb.redirectErrorStream(true);
        Process proc = pb.start();

        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(proc.getInputStream())))
        {
            String line;
            while ((line = reader.readLine()) != null) output.append(line).append(" ");
        }

        int exit = proc.waitFor();
        if (exit != 0)
        {
            throw new RuntimeException("ufw exit " + exit + ": " + output.toString().trim());
        }
    }

    private void log(String message)
    {
        String ts = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String entry = "[" + ts + "] [UFW] " + message;
        System.out.println(entry);

        try
        {
            Files.writeString(logFile, entry + "\n",
                java.nio.file.StandardOpenOption.CREATE,
                java.nio.file.StandardOpenOption.APPEND);
        }
        catch (IOException ignored) {}
    }

    public void setEnabled(boolean e) { this.enabled = e; }
    public boolean isEnabled() { return enabled; }
    public void setSudoRequired(boolean s) { this.sudoRequired = s; }
    public void setLogFile(Path p) { this.logFile = p; }
}
