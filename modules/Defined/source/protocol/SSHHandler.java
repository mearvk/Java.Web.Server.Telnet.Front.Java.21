package modules.Defined.source.protocol;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.*;

/**
 * SSHHandler — Protocol handler for SSH (port 22).
 * Outbound connections for secure data retrieval and queries.
 * Uses UFW to open port before use and close after execution.
 *
 * Supports key-based authentication and password fallback.
 * Multiple credentials for admins and capitalists.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class SSHHandler extends ProtocolHandler
{
    private String keyType = "RSA-4096";
    private Path knownHostsFile = Paths.get("data/ssh/known_hosts");
    private final UFWFirewallManager ufwManager;

    public SSHHandler(UFWFirewallManager ufwManager)
    {
        super(22, "SSH", "SSH — Secure Shell (outbound data retrieval)");
        this.ufwManager = ufwManager;
    }

    /**
     * Execute an outbound SSH command on a remote host.
     * Opens port 22 via UFW before use, closes after execution.
     */
    public String executeRemoteCommand(String host, String command, Credential cred) throws Exception
    {
        // Open port via UFW before use
        ufwManager.openPort(22, "out");

        try
        {
            // Build SSH command
            List<String> sshCmd = new ArrayList<>();
            sshCmd.add("ssh");
            sshCmd.add("-o"); sshCmd.add("StrictHostKeyChecking=accept-new");
            sshCmd.add("-o"); sshCmd.add("UserKnownHostsFile=" + knownHostsFile);
            sshCmd.add("-o"); sshCmd.add("ConnectTimeout=10");

            // Use key file if available
            String keyFile = getKeyFileForCredential(cred);
            if (keyFile != null && Files.exists(Paths.get(keyFile)))
            {
                sshCmd.add("-i"); sshCmd.add(keyFile);
            }

            sshCmd.add(cred.username + "@" + host);
            sshCmd.add(command);

            ProcessBuilder pb = new ProcessBuilder(sshCmd);
            pb.redirectErrorStream(true);
            Process proc = pb.start();

            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(proc.getInputStream())))
            {
                String line;
                while ((line = reader.readLine()) != null)
                {
                    output.append(line).append("\n");
                }
            }

            int exitCode = proc.waitFor();
            logConnection("SSH " + host + " cmd=\"" + command + "\" exit=" + exitCode);
            return output.toString();
        }
        finally
        {
            // Close port via UFW after execution
            ufwManager.closePort(22, "out");
        }
    }

    /**
     * SCP file retrieval — download a file from remote host.
     * Opens port 22 via UFW before use, closes after.
     */
    public boolean scpDownload(String host, String remotePath, Path localPath, Credential cred) throws Exception
    {
        ufwManager.openPort(22, "out");

        try
        {
            List<String> scpCmd = new ArrayList<>();
            scpCmd.add("scp");
            scpCmd.add("-o"); scpCmd.add("StrictHostKeyChecking=accept-new");
            scpCmd.add("-o"); scpCmd.add("ConnectTimeout=10");

            String keyFile = getKeyFileForCredential(cred);
            if (keyFile != null && Files.exists(Paths.get(keyFile)))
            {
                scpCmd.add("-i"); scpCmd.add(keyFile);
            }

            scpCmd.add(cred.username + "@" + host + ":" + remotePath);
            scpCmd.add(localPath.toString());

            ProcessBuilder pb = new ProcessBuilder(scpCmd);
            pb.redirectErrorStream(true);
            Process proc = pb.start();
            int exitCode = proc.waitFor();

            logConnection("SCP " + host + ":" + remotePath + " → " + localPath + " exit=" + exitCode);
            return exitCode == 0;
        }
        finally
        {
            ufwManager.closePort(22, "out");
        }
    }

    private String getKeyFileForCredential(Credential cred)
    {
        // Key file naming convention: data/ssh/id_rsa_<role-suffix>
        if (cred.id.contains("admin-1")) return "data/ssh/id_rsa_admin";
        if (cred.id.contains("admin-2")) return "data/ssh/id_rsa_ops";
        if (cred.id.contains("capitalist")) return "data/ssh/id_rsa_data";
        return null;
    }

    public void setKeyType(String type) { this.keyType = type; }
    public void setKnownHostsFile(Path path) { this.knownHostsFile = path; }

    @Override
    public void start()
    {
        active = true;
        // Ensure SSH data directory exists
        try { Files.createDirectories(Paths.get("data/ssh")); } catch (IOException ignored) {}
        logConnection("SSH handler started (key-type=" + keyType + ", UFW-managed)");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("SSH handler stopped");
    }
}
