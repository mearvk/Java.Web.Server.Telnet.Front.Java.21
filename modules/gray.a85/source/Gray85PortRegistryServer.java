package modules.gray.85.source;

import java.io.*;
import java.net.*;
import java.nio.*;
import java.nio.channels.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Gray85PortRegistryServer — Crème Port Registry (Installer ID Tech™).
 *
 * Same as GrayPortRegistryServer but 15 out of every 100 ports are
 * implicitly and tightly Crème-locked — auditor control already clean, planetary.
 * Crème ports unlock for $1000 USD donation, 1 hour minimum.
 *
 * Port 10085. NIO. 127.0.X.X connectors.
 *
 * Protocol:
 *   LEASE|<block_id>|<term>|<btc_txid>          — lease open ports (85%)
 *   UNLOCK|<block_id>|<port_offset>|<hours>|<btc_txid>  — unlock Crème port ($1000+)
 *   BIND|<block_id>|<port>                       — bind a port (AI gated)
 *   STATUS|<block_id>                            — check block status
 *   CREME|<block_id>                             — list Crème-locked ports
 *   LIST                                         — list active leases
 *   QUIT
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @brand Installer ID Tech™
 */
public class Gray85PortRegistryServer extends Thread
{
    public static final int PORT = 10085;
    public static final int BLOCK_SIZE = 30_000_000;
    public static final int INITIAL_BLOCKS = 1000;
    public static final int CREME_RATIO = 15; // 15 out of 100 locked
    public static final double CREME_UNLOCK_USD = 1000.00;

    private static final String BANNER =
        "═══════════════════════════════════════════════════════════════\r\n" +
        " Installer ID Tech™ — Gray.85 Crème Port Registry\r\n" +
        " 85/100 ports open ($10 USD) | 15/100 Crème-locked (planetary)\r\n" +
        " Crème unlock: $1000 USD donation — 1 hour minimum\r\n" +
        " Bitcoin/Dashcoin accepted\r\n" +
        "═══════════════════════════════════════════════════════════════\r\n" +
        " Commands: LEASE|UNLOCK|BIND|STATUS|CREME|LIST|QUIT\r\n" +
        "═══════════════════════════════════════════════════════════════\r\n";

    private static final String DB_URL = "jdbc:mysql://localhost:3306/nwe_gray85_registry";
    private static final String DB_USER = "nwe";
    private static final String DB_PASS = "";

    private final Map<Integer, PortBlockLease> activeLeases = new ConcurrentHashMap<>();
    private final Map<String, CremeUnlock> activeCremeUnlocks = new ConcurrentHashMap<>();
    private final PortBindingGate85 aiGate = new PortBindingGate85();
    private volatile boolean running = true;

    public Gray85PortRegistryServer()
    {
        setName("Gray85PortRegistryServer-10085");
        setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            ServerSocketChannel serverChannel = ServerSocketChannel.open();
            serverChannel.bind(new InetSocketAddress("0.0.0.0", PORT));
            serverChannel.configureBlocking(false);

            Selector selector = Selector.open();
            serverChannel.register(selector, SelectionKey.OP_ACCEPT);

            commons.CommonRails.printSystemComponent(this, this.hashCode(),
                ". Installer ID Tech™ Gray.85 Crème Registry listening on port " + PORT + " .");

            while (running)
            {
                selector.select(1000);
                Iterator<SelectionKey> keys = selector.selectedKeys().iterator();
                while (keys.hasNext())
                {
                    SelectionKey key = keys.next();
                    keys.remove();
                    if (key.isAcceptable()) accept(key, selector);
                    else if (key.isReadable()) read(key);
                }
            }
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private void accept(SelectionKey key, Selector selector) throws IOException
    {
        SocketChannel client = ((ServerSocketChannel) key.channel()).accept();
        if (client == null) return;
        client.configureBlocking(false);
        client.register(selector, SelectionKey.OP_READ);
        client.write(ByteBuffer.wrap(BANNER.getBytes(StandardCharsets.UTF_8)));

        InetSocketAddress remote = (InetSocketAddress) client.getRemoteAddress();
        logConnection(remote.getAddress().getHostAddress(), remote.getHostName());
    }

    private void read(SelectionKey key) throws IOException
    {
        SocketChannel client = (SocketChannel) key.channel();
        ByteBuffer buf = ByteBuffer.allocate(4096);
        int read = client.read(buf);
        if (read <= 0) { client.close(); return; }

        buf.flip();
        String input = StandardCharsets.UTF_8.decode(buf).toString().trim();
        String response = processCommand(input, client);
        if (response != null)
            client.write(ByteBuffer.wrap((response + "\r\n").getBytes(StandardCharsets.UTF_8)));
    }

    private String processCommand(String input, SocketChannel client) throws IOException
    {
        String[] parts = input.split("\\|");
        String cmd = parts[0].toUpperCase();

        return switch (cmd) {
            case "LEASE" -> {
                if (parts.length < 4) yield "ERROR|Usage: LEASE|<block_id>|<term>|<btc_txid>";
                yield handleLease(Integer.parseInt(parts[1]), parts[2], parts[3], client);
            }
            case "UNLOCK" -> {
                if (parts.length < 5) yield "ERROR|Usage: UNLOCK|<block_id>|<port_offset>|<hours>|<btc_txid>";
                yield handleCremeUnlock(Integer.parseInt(parts[1]), Integer.parseInt(parts[2]),
                    Integer.parseInt(parts[3]), parts[4], client);
            }
            case "BIND" -> {
                if (parts.length < 3) yield "ERROR|Usage: BIND|<block_id>|<port>";
                yield handleBind(Integer.parseInt(parts[1]), Long.parseLong(parts[2]));
            }
            case "STATUS" -> {
                if (parts.length < 2) yield "ERROR|Usage: STATUS|<block_id>";
                yield handleStatus(Integer.parseInt(parts[1]));
            }
            case "CREME" -> {
                if (parts.length < 2) yield "ERROR|Usage: CREME|<block_id>";
                yield handleCremeInfo(Integer.parseInt(parts[1]));
            }
            case "LIST" -> handleList();
            case "QUIT" -> { client.close(); yield null; }
            default -> "ERROR|Unknown command: " + cmd;
        };
    }

    private String handleLease(int blockId, String term, String btcTxid, SocketChannel client) throws IOException
    {
        if (blockId < 0 || blockId >= INITIAL_BLOCKS)
            return "ERROR|Block ID must be 0-" + (INITIAL_BLOCKS - 1);
        if (activeLeases.containsKey(blockId))
            return "ERROR|Block " + blockId + " already leased";
        if (!aiGate.authorize(blockId, term))
            return "DENIED|AI gate rejected lease";

        InetSocketAddress remote = (InetSocketAddress) client.getRemoteAddress();
        PortBlockLease lease = new PortBlockLease(blockId, term, btcTxid,
            remote.getAddress().getHostAddress(), LocalDateTime.now());
        activeLeases.put(blockId, lease);
        persistLease(lease);

        int openPorts = (BLOCK_SIZE / 100) * 85;
        return "LEASED|block=" + blockId + "|open_ports=" + openPorts +
               "|creme_locked=" + (BLOCK_SIZE - openPorts) + "|term=" + term;
    }

    private String handleCremeUnlock(int blockId, int portOffset, int hours, String btcTxid,
                                     SocketChannel client) throws IOException
    {
        if (!activeLeases.containsKey(blockId))
            return "ERROR|Block " + blockId + " not leased — lease first";

        int cremeCount = (BLOCK_SIZE / 100) * CREME_RATIO;
        if (portOffset < 0 || portOffset >= cremeCount)
            return "ERROR|Port offset must be 0-" + (cremeCount - 1) + " (within Crème range)";

        if (hours < 1)
            return "ERROR|Minimum unlock duration: 1 hour";

        // AI gate consult for Crème unlock
        if (!aiGate.authorizeCremeUnlock(blockId, portOffset))
            return "DENIED|AI gate rejected Crème unlock — planetary clean";

        InetSocketAddress remote = (InetSocketAddress) client.getRemoteAddress();
        LocalDateTime now = LocalDateTime.now();
        CremeUnlock unlock = new CremeUnlock(blockId, portOffset, hours, btcTxid,
            remote.getAddress().getHostAddress(), now);

        String key = blockId + ":" + portOffset;
        activeCremeUnlocks.put(key, unlock);
        persistCremeUnlock(unlock);
        persistPayment(btcTxid, blockId, "creme_unlock", remote.getAddress().getHostAddress(),
            CREME_UNLOCK_USD * hours);

        long absolutePort = resolveCremePort(blockId, portOffset);
        return "UNLOCKED|block=" + blockId + "|creme_offset=" + portOffset +
               "|absolute_port=" + absolutePort + "|hours=" + hours +
               "|expires=" + now.plusHours(hours) + "|donation=$" + (CREME_UNLOCK_USD * hours);
    }

    private String handleBind(int blockId, long port)
    {
        if (!activeLeases.containsKey(blockId))
            return "ERROR|Block " + blockId + " not leased";

        // Check if port is in Crème range
        if (isCremePort(blockId, port))
        {
            int offset = getCremeOffset(blockId, port);
            String key = blockId + ":" + offset;
            CremeUnlock unlock = activeCremeUnlocks.get(key);
            if (unlock == null || unlock.isExpired())
                return "DENIED|Port " + port + " is Crème-locked (planetary clean) — $1000 USD to unlock";
        }

        if (!aiGate.authorizeBind(blockId, port))
            return "DENIED|AI gate rejected bind";

        return "BOUND|block=" + blockId + "|port=" + port + "|ip=" + resolveIp(port);
    }

    private String handleStatus(int blockId)
    {
        PortBlockLease lease = activeLeases.get(blockId);
        if (lease == null) return "STATUS|block=" + blockId + "|available";
        int openPorts = (BLOCK_SIZE / 100) * 85;
        int cremePorts = BLOCK_SIZE - openPorts;
        return "STATUS|block=" + blockId + "|leased|open=" + openPorts +
               "|creme_locked=" + cremePorts + "|term=" + lease.term;
    }

    private String handleCremeInfo(int blockId)
    {
        int cremePorts = (BLOCK_SIZE / 100) * CREME_RATIO;
        long basePort = (long) blockId * BLOCK_SIZE;
        // Crème ports are the last 15% of each block
        long cremeStart = basePort + ((long)(BLOCK_SIZE / 100) * 85);
        long cremeEnd = basePort + BLOCK_SIZE - 1;
        return "CREME|block=" + blockId + "|range=" + cremeStart + "-" + cremeEnd +
               "|count=" + cremePorts + "|status=locked|unlock=$1000/hr";
    }

    private String handleList()
    {
        if (activeLeases.isEmpty()) return "LIST|No active leases";
        StringBuilder sb = new StringBuilder("LIST|");
        activeLeases.forEach((id, l) -> sb.append("block=").append(id).append("/").append(l.term).append(" "));
        return sb.toString().trim();
    }

    /** Crème ports occupy the last 15% of each block */
    private boolean isCremePort(int blockId, long port)
    {
        long basePort = (long) blockId * BLOCK_SIZE;
        long cremeStart = basePort + ((long)(BLOCK_SIZE / 100) * 85);
        return port >= cremeStart;
    }

    private int getCremeOffset(int blockId, long port)
    {
        long basePort = (long) blockId * BLOCK_SIZE;
        long cremeStart = basePort + ((long)(BLOCK_SIZE / 100) * 85);
        return (int)(port - cremeStart);
    }

    private long resolveCremePort(int blockId, int offset)
    {
        long basePort = (long) blockId * BLOCK_SIZE;
        return basePort + ((long)(BLOCK_SIZE / 100) * 85) + offset;
    }

    private String resolveIp(long port)
    {
        int ipIndex = (int) (port / 65536);
        int localPort = (int) (port % 65536);
        return "127.0." + (ipIndex / 256) + "." + Math.max(1, ipIndex % 256) + ":" + localPort;
    }

    private void logConnection(String ip, String domain)
    {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO connections (ip, domain, connected_at) VALUES (?, ?, NOW())"))
        { ps.setString(1, ip); ps.setString(2, domain); ps.executeUpdate(); }
        catch (SQLException ignored) {}
    }

    private void persistLease(PortBlockLease lease)
    {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO leases (block_id, term, btc_txid, client_ip, leased_at, expires_at) VALUES (?,?,?,?,?,?)"))
        {
            ps.setInt(1, lease.blockId); ps.setString(2, lease.term);
            ps.setString(3, lease.btcTxid); ps.setString(4, lease.clientIp);
            ps.setString(5, lease.leasedAt.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            ps.setString(6, lease.expiresAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            ps.executeUpdate();
        } catch (SQLException ignored) {}
    }

    private void persistCremeUnlock(CremeUnlock unlock)
    {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO creme_unlocks (block_id, port_offset, btc_txid, client_ip, donation_usd, duration_hours, unlocked_at, expires_at) VALUES (?,?,?,?,?,?,?,?)"))
        {
            ps.setInt(1, unlock.blockId); ps.setInt(2, unlock.portOffset);
            ps.setString(3, unlock.btcTxid); ps.setString(4, unlock.clientIp);
            ps.setDouble(5, CREME_UNLOCK_USD * unlock.hours); ps.setInt(6, unlock.hours);
            ps.setString(7, unlock.unlockedAt.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            ps.setString(8, unlock.unlockedAt.plusHours(unlock.hours).format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            ps.executeUpdate();
        } catch (SQLException ignored) {}
    }

    private void persistPayment(String txid, int blockId, String type, String ip, double usd)
    {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO payments (btc_txid, block_id, term, payment_type, client_ip, amount_usd, paid_at) VALUES (?,?,?,?,?,?,NOW())"))
        {
            ps.setString(1, txid); ps.setInt(2, blockId); ps.setString(3, type);
            ps.setString(4, type); ps.setString(5, ip); ps.setDouble(6, usd);
            ps.executeUpdate();
        } catch (SQLException ignored) {}
    }

    public void shutdown() { running = false; }

    static class PortBlockLease
    {
        final int blockId; final String term; final String btcTxid;
        final String clientIp; final LocalDateTime leasedAt;

        PortBlockLease(int blockId, String term, String btcTxid, String clientIp, LocalDateTime leasedAt)
        { this.blockId = blockId; this.term = term; this.btcTxid = btcTxid; this.clientIp = clientIp; this.leasedAt = leasedAt; }

        LocalDateTime expiresAt() {
            return switch (term.toLowerCase()) {
                case "year" -> leasedAt.plusYears(1);
                case "multi-year" -> leasedAt.plusYears(3);
                default -> leasedAt.plusMonths(1);
            };
        }
    }

    static class CremeUnlock
    {
        final int blockId; final int portOffset; final int hours;
        final String btcTxid; final String clientIp; final LocalDateTime unlockedAt;

        CremeUnlock(int blockId, int portOffset, int hours, String btcTxid, String clientIp, LocalDateTime unlockedAt)
        { this.blockId = blockId; this.portOffset = portOffset; this.hours = hours;
          this.btcTxid = btcTxid; this.clientIp = clientIp; this.unlockedAt = unlockedAt; }

        boolean isExpired() { return LocalDateTime.now().isAfter(unlockedAt.plusHours(hours)); }
    }
}
