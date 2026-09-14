package modules.Defined.source.protocol;

import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * ProtocolHandler — Base class for all port-aware protocol handlers.
 *
 * Provides multi-credential authentication capability for admins and capitalists.
 * Each protocol handler is aware of its port and can manage more than one
 * username/password pair.
 *
 * US well in condition. US well loved. US is well in authority of command.
 * Based on army, country and constitution. God is with America.
 * For law and tech We stand. These Affirm We. Thus. This. A. America.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public abstract class ProtocolHandler
{
    protected final int port;
    protected final String protocolName;
    protected final String description;

    // Multi-credential store: credential-id → Credential
    protected final Map<String, Credential> credentials = new ConcurrentHashMap<>();

    // Connection tracking
    protected volatile boolean active = false;
    protected final List<String> connectionLog = new CopyOnWriteArrayList<>();

    /**
     * Credential entry — more than one username/password per protocol.
     */
    public static class Credential
    {
        public final String id;
        public final String username;
        public final String passwordEnvVar;
        public final String role; // "admin" or "capitalist"
        public final String authType; // "Basic", "Bearer", "Form", etc.
        public final String privileges; // for DB: "SELECT,INSERT", "ALL", etc.

        public Credential(String id, String username, String passwordEnvVar, String role, String authType, String privileges)
        {
            this.id = id;
            this.username = username;
            this.passwordEnvVar = passwordEnvVar;
            this.role = role;
            this.authType = authType;
            this.privileges = privileges;
        }

        /**
         * Resolve password from environment variable.
         * Falls back to system property if env not set.
         */
        public String resolvePassword()
        {
            String pass = System.getenv(passwordEnvVar);
            if (pass == null) pass = System.getProperty(passwordEnvVar, "");
            return pass;
        }

        /**
         * Authenticate against this credential.
         */
        public boolean authenticate(String user, String pass)
        {
            return username.equals(user) && resolvePassword().equals(pass);
        }
    }

    protected ProtocolHandler(int port, String protocolName, String description)
    {
        this.port = port;
        this.protocolName = protocolName;
        this.description = description;
    }

    /**
     * Add a credential for this protocol. More than one allowed.
     */
    public void addCredential(Credential cred)
    {
        credentials.put(cred.id, cred);
    }

    /**
     * Authenticate a user/pass pair against all credentials for this protocol.
     * Returns the matched credential or null if none matched.
     */
    public Credential authenticate(String username, String password)
    {
        for (Credential cred : credentials.values())
        {
            if (cred.authenticate(username, password))
            {
                logConnection("AUTH-OK: " + username + " as " + cred.role);
                return cred;
            }
        }
        logConnection("AUTH-FAIL: " + username);
        return null;
    }

    /**
     * Check if a given role is present among credentials.
     */
    public boolean hasRole(String role)
    {
        return credentials.values().stream().anyMatch(c -> c.role.equals(role));
    }

    /**
     * Get all credentials for a specific role.
     */
    public List<Credential> getCredentialsForRole(String role)
    {
        return credentials.values().stream()
            .filter(c -> c.role.equals(role))
            .toList();
    }

    /**
     * Test connectivity to the protocol's port.
     */
    public boolean testConnectivity(String host)
    {
        try (Socket socket = new Socket())
        {
            socket.connect(new InetSocketAddress(host, port), 5000);
            logConnection("CONNECTIVITY-OK: " + host + ":" + port);
            return true;
        }
        catch (IOException e)
        {
            logConnection("CONNECTIVITY-FAIL: " + host + ":" + port + " — " + e.getMessage());
            return false;
        }
    }

    protected void logConnection(String message)
    {
        String entry = "[" + protocolName + ":" + port + "] " + message;
        connectionLog.add(entry);
        System.out.println(entry);
    }

    public int getPort() { return port; }
    public String getProtocolName() { return protocolName; }
    public String getDescription() { return description; }
    public boolean isActive() { return active; }
    public List<String> getConnectionLog() { return Collections.unmodifiableList(connectionLog); }

    /**
     * Start monitoring/handling this protocol.
     */
    public abstract void start();

    /**
     * Stop monitoring/handling this protocol.
     */
    public abstract void stop();

    /**
     * Get status string for telnet display.
     */
    public String getStatus()
    {
        return String.format("[%s] Port %d — %s — %s — %d credentials",
            protocolName, port, description,
            active ? "ACTIVE" : "INACTIVE",
            credentials.size());
    }
}
