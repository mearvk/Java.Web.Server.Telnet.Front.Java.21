package modules.gray.source;

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
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * GrayPortRegistryServer — Control-loop independent port registry.
 * Installer ID Tech™ brand.
 *
 * Listens on port 9999 for client connections.
 * Leases blocks of 30,000,000 ports for monthly/yearly terms.
 * Accepts Bitcoin/Dashcoin as payment.
 * AI binary gate authorizes each port binding.
 * Persists all connection data to nwe_gray_registry MySQL database.
 *
 * Protocol:
 *   LEASE|<block_id>|<term>|<btc_txid>
 *   STATUS|<block_id>
 *   BIND|<block_id>|<port>
 *   LIST
 *   QUIT
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @brand Installer ID Tech™
 */
public class GrayPortRegistryServer extends Thread
{
    public static final int PORT = 9999;
    public static final int BLOCK_SIZE = 30_000_000;
    public static final int INITIAL_BLOCKS = 1000;

    private static final String BANNER =
        "╔═══════════════════════════════════════════════════════════════════════════╗\r\n" +
        "║  INSTALLER ID TECH™ — Port Registry Service                              ║\r\n" +
        "║  Port 9999 — Gray — NitroWebExpress™                                     ║\r\n" +
        "║                                                                           ║\r\n" +
        "║  US well in condition. US well loved. US is well in authority of command   ║\r\n" +
        "║  of the United States. Well affirmed. Based on army, country and          ║\r\n" +
        "║  constitution. God is with America. And Max Rupplin.                      ║\r\n" +
        "║                                                                           ║\r\n" +
        "║  For law and tech We stand. These Affirm We. Thus. This. A. America.     ║\r\n" +
        "╚═══════════════════════════════════════════════════════════════════════════╝\r\n" +
        "\r\n" +
        " $10 USD minimum donation — Bitcoin/Dashcoin accepted\r\n" +
        " 30,000,000 ports per block — 1000 blocks available\r\n" +
        " National ID: identify <8-digit-id> | Rank Upgrades: github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions\r\n" +
        " Bitcoin/National Banking: port 6682 | Progress toward US digital currency standard.\r\n" +
        "═══════════════════════════════════════════════════════════════\r\n" +
        " Commands: LEASE|STATUS|BIND|LIST|QUIT\r\n" +
        "═══════════════════════════════════════════════════════════════\r\n";

    private static final String DB_URL = "jdbc:mysql://localhost:3306/nwe_gray_registry";
    private static final String DB_USER = "nwe";
    private static final String DB_PASS = "";

    private final Map<Integer, PortBlockLease> activeLeases = new ConcurrentHashMap<>();
    private final PortBindingGate aiGate = new PortBindingGate();
    private volatile boolean running = true;
    private ServerSocketChannel serverChannel;

    public GrayPortRegistryServer()
    {
        setName("GrayPortRegistryServer-9999");
        setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            serverChannel = ServerSocketChannel.open();
            serverChannel.bind(new InetSocketAddress("localhost", PORT));
            serverChannel.configureBlocking(false);

            Selector selector = Selector.open();
            serverChannel.register(selector, SelectionKey.OP_ACCEPT);

            commons.CommonRails.printSystemComponent(this, this.hashCode(),
                ". Installer ID Tech™ Port Registry listening on port " + PORT + " .");

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

        // Send banner
        client.write(ByteBuffer.wrap(BANNER.getBytes(StandardCharsets.UTF_8)));

        // Log connection
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

        switch (cmd)
        {
            case "LEASE":
                if (parts.length < 4) return "ERROR|Usage: LEASE|<block_id>|<term>|<btc_txid>";
                return handleLease(Integer.parseInt(parts[1]), parts[2], parts[3], client);

            case "STATUS":
                if (parts.length < 2) return "ERROR|Usage: STATUS|<block_id>";
                return handleStatus(Integer.parseInt(parts[1]));

            case "BIND":
                if (parts.length < 3) return "ERROR|Usage: BIND|<block_id>|<port>";
                return handleBind(Integer.parseInt(parts[1]), Long.parseLong(parts[2]));

            case "LIST":
                return handleList();

            case "QUIT":
                client.close();
                return null;

            default:
                return "ERROR|Unknown command: " + cmd;
        }
    }

    private String handleLease(int blockId, String term, String btcTxid, SocketChannel client) throws IOException
    {
        if (blockId < 0 || blockId >= INITIAL_BLOCKS)
            return "ERROR|Block ID must be 0-" + (INITIAL_BLOCKS - 1);

        if (activeLeases.containsKey(blockId))
            return "ERROR|Block " + blockId + " already leased";

        // AI gate consult
        if (!aiGate.authorize(blockId, term))
            return "DENIED|AI gate rejected lease for block " + blockId;

        InetSocketAddress remote = (InetSocketAddress) client.getRemoteAddress();
        PortBlockLease lease = new PortBlockLease(blockId, term, btcTxid,
            remote.getAddress().getHostAddress(), LocalDateTime.now());

        activeLeases.put(blockId, lease);
        persistLease(lease);
        persistPayment(btcTxid, blockId, term, remote.getAddress().getHostAddress());

        long startPort = (long) blockId * BLOCK_SIZE;
        long endPort = startPort + BLOCK_SIZE - 1;
        return "LEASED|block=" + blockId + "|ports=" + startPort + "-" + endPort +
               "|term=" + term + "|txid=" + btcTxid;
    }

    private String handleStatus(int blockId)
    {
        PortBlockLease lease = activeLeases.get(blockId);
        if (lease == null) return "STATUS|block=" + blockId + "|available";
        return "STATUS|block=" + blockId + "|leased|term=" + lease.term +
               "|expires=" + lease.expiresAt() + "|ip=" + lease.clientIp;
    }

    private String handleBind(int blockId, long port)
    {
        PortBlockLease lease = activeLeases.get(blockId);
        if (lease == null) return "ERROR|Block " + blockId + " not leased";

        long startPort = (long) blockId * BLOCK_SIZE;
        long endPort = startPort + BLOCK_SIZE - 1;
        if (port < startPort || port > endPort)
            return "ERROR|Port " + port + " not in block " + blockId + " range (" + startPort + "-" + endPort + ")";

        // AI gate consult for binding
        if (!aiGate.authorizeBind(blockId, port))
            return "DENIED|AI gate rejected bind for port " + port;

        return "BOUND|block=" + blockId + "|port=" + port + "|ip=" + resolveIp(port);
    }

    private String handleList()
    {
        if (activeLeases.isEmpty()) return "LIST|No active leases";
        StringBuilder sb = new StringBuilder("LIST|");
        activeLeases.forEach((id, lease) ->
            sb.append("block=").append(id).append("/term=").append(lease.term).append(" "));
        return sb.toString().trim();
    }

    /** Resolve 127.0.X.X IP for a given absolute port number */
    private String resolveIp(long port)
    {
        int ipIndex = (int) (port / 65536);
        int localPort = (int) (port % 65536);
        int octet3 = ipIndex / 256;
        int octet4 = ipIndex % 256;
        return "127.0." + octet3 + "." + Math.max(1, octet4) + ":" + localPort;
    }

    private void logConnection(String ip, String domain)
    {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO connections (ip, domain, connected_at, geo) VALUES (?, ?, NOW(), ?)"))
        {
            ps.setString(1, ip);
            ps.setString(2, domain);
            ps.setString(3, "");
            ps.executeUpdate();
        }
        catch (SQLException ignored) {}
    }

    private void persistLease(PortBlockLease lease)
    {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO leases (block_id, term, btc_txid, client_ip, leased_at, expires_at) VALUES (?,?,?,?,?,?)"))
        {
            ps.setInt(1, lease.blockId);
            ps.setString(2, lease.term);
            ps.setString(3, lease.btcTxid);
            ps.setString(4, lease.clientIp);
            ps.setString(5, lease.leasedAt.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            ps.setString(6, lease.expiresAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            ps.executeUpdate();
        }
        catch (SQLException ignored) {}
    }

    private void persistPayment(String txid, int blockId, String term, String ip)
    {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO payments (btc_txid, block_id, term, client_ip, paid_at) VALUES (?,?,?,?,NOW())"))
        {
            ps.setString(1, txid);
            ps.setInt(2, blockId);
            ps.setString(3, term);
            ps.setString(4, ip);
            ps.executeUpdate();
        }
        catch (SQLException ignored) {}
    }

    public void shutdown() { running = false; }

    /** Lease record */
    static class PortBlockLease
    {
        final int blockId;
        final String term;
        final String btcTxid;
        final String clientIp;
        final LocalDateTime leasedAt;

        PortBlockLease(int blockId, String term, String btcTxid, String clientIp, LocalDateTime leasedAt)
        {
            this.blockId = blockId;
            this.term = term;
            this.btcTxid = btcTxid;
            this.clientIp = clientIp;
            this.leasedAt = leasedAt;
        }

        LocalDateTime expiresAt()
        {
            return switch (term.toLowerCase()) {
                case "year" -> leasedAt.plusYears(1);
                case "multi-year" -> leasedAt.plusYears(3);
                default -> leasedAt.plusMonths(1);
            };
        }
    }

    /** Standalone entry point — allows start-backend.sh to launch directly. */
    public static void main(String[] args) throws InterruptedException
    {
        GrayPortRegistryServer server = new GrayPortRegistryServer();
        server.start();
        server.join();
    }
}
