package red.Futures.source.ai.server;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.*;
import java.util.concurrent.*;

/**
 * DiskAwarenessMonitor — makes MySQL aware of server hard disk space.
 * Periodically checks disk usage and writes to server_disk_status table.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class DiskAwarenessMonitor
{
    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
    private final String jdbcUrl;

    public DiskAwarenessMonitor(String jdbcUrl)
    {
        this.jdbcUrl = jdbcUrl;
    }

    public void start()
    {
        scheduler.scheduleAtFixedRate(this::checkAndStore, 0, 5, TimeUnit.MINUTES);
    }

    private void checkAndStore()
    {
        try
        {
            Process proc = Runtime.getRuntime().exec(new String[]{"df", "-B1", "--output=target,size,used,avail"});
            BufferedReader reader = new BufferedReader(new InputStreamReader(proc.getInputStream()));
            String header = reader.readLine(); // skip header

            String hostname = java.net.InetAddress.getLocalHost().getHostName();
            String line;

            try (Connection conn = DriverManager.getConnection(jdbcUrl))
            {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO server_disk_status (hostname, mount_point, total_bytes, used_bytes, free_bytes, percent_used) VALUES (?,?,?,?,?,?)");

                while ((line = reader.readLine()) != null)
                {
                    String[] parts = line.trim().split("\\s+");
                    if (parts.length < 4) continue;

                    String mount = parts[0];
                    long total = Long.parseLong(parts[1]);
                    long used = Long.parseLong(parts[2]);
                    long free = Long.parseLong(parts[3]);
                    float pct = total > 0 ? (float) used / total * 100 : 0;

                    ps.setString(1, hostname);
                    ps.setString(2, mount);
                    ps.setLong(3, total);
                    ps.setLong(4, used);
                    ps.setLong(5, free);
                    ps.setFloat(6, pct);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
            proc.waitFor();
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
    }

    public void stop()
    {
        scheduler.shutdownNow();
    }
}
