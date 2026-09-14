/**
 * StrernaryDirectoryServer — Port 2000 directory/menu server.
 *
 * Provides a basic telnet menu allowing clients to:
 *   1. Query IPs/domains for port 20000 (Strernary) servers
 *   2. Query IPs/domains for port 49152 (NationalFinanceID) servers
 *   3. Register a Rank 4 JWSTNJ21 server (requires public.key verification)
 *
 * Also accepts XML packets for NIO masquerade forwarding:
 *   <nwe-route><port>N</port><payload>...</payload></nwe-route>
 *
 * Behavior is governed by configuration/port-2000-directory-config.xml
 * and configuration/nio-masquerade-config.xml.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 23 2026 EST
 */

package strernary;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CopyOnWriteArrayList;

import org.w3c.dom.*;
import javax.xml.parsers.*;

public class StrernaryDirectoryServer implements Runnable
{
    public static final int PORT = 2000;
    public static final String THREAD_NAME = "STRERNARY_DIRECTORY_2000";

    private static final String CONFIG_PATH = "configuration/port-2000-directory-config.xml";
    private static final String SERVERS_20000_PATH = "configuration/known.port.20000.servers.xml";
    private static final String SERVERS_49152_PATH = "configuration/known.port.49152.servers.xml";
    private static final String PUBLIC_KEY_URL = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";

    private final String host;
    private volatile boolean running = true;

    // Config flags (loaded from XML)
    private volatile boolean port20000Enabled = true;
    private volatile boolean port49152Enabled = true;
    private volatile boolean port20000RequiresNid = false;
    private volatile boolean port49152RequiresNid = true;
    private volatile boolean rank4Enabled = true;
    private volatile boolean rank4RequiresKey = true;
    private volatile boolean xmlForwardingEnabled = true;

    // NIO masquerade engine reference
    private NioMasqueradeEngine nioEngine;
    private NioModuleScanner moduleScanner;

    // Registered Rank 4 servers
    private final CopyOnWriteArrayList<String> registeredRank4Servers = new CopyOnWriteArrayList<>();

    // Cached public.key bytes from GitHub
    private volatile byte[] cachedPublicKey = null;

    public StrernaryDirectoryServer(String host)
    {
        this.host = host;
        loadConfig();
        fetchPublicKey();
        this.nioEngine = new NioMasqueradeEngine();
        this.moduleScanner = new NioModuleScanner(nioEngine);
        Thread.ofVirtual().name(THREAD_NAME).start(this);
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary™ DirectoryServer now starting on port " + PORT + " .");
    }

    @Override
    public void run()
    {
        try (ServerSocket ss = new ServerSocket(PORT, 50, InetAddress.getByName(host)))
        {
            while (running)
            {
                Socket client = ss.accept();
                Thread.ofVirtual().start(() -> handleClient(client));
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private void handleClient(Socket client)
    {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             OutputStream out = client.getOutputStream())
        {
            // Peek for XML packet — if first data starts with <nwe-route>, handle as forwarding
            in.mark(8192);
            String firstLine = in.readLine();
            if (firstLine != null && xmlForwardingEnabled && firstLine.trim().startsWith("<nwe-route"))
            {
                in.reset();
                handleXmlForward(in, out, client);
                return;
            }
            in.reset();
            // Consume the peeked line if it wasn't XML (re-read after banner)
            if (firstLine != null && !firstLine.trim().startsWith("<nwe-route"))
                in.reset(); // let interactive mode re-read

            write(out, "\n══════════════════════════════════════════════════════\n");
            write(out, "  Strernary™ Directory Server — Port 2000\n");
            write(out, "  MEARVK LLC — NitroWebExpress™\n");
            write(out, "══════════════════════════════════════════════════════\n");
            write(out, "  Rank Upgrades / Installer IDs / Public Key Requests:\n");
            write(out, "  https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions\n");
            write(out, "══════════════════════════════════════════════════════\n\n");

            boolean authenticated = false;
            long nationalId = -1;

            // Main menu loop
            while (true)
            {
                write(out, "  MENU:\n");
                if (port20000Enabled)
                    write(out, "    1. Get port 20000 server IPs (Strernary™)" + (port20000RequiresNid ? " [NationalID required]" : "") + "\n");
                if (port49152Enabled)
                    write(out, "    2. Get port 49152 server IPs (NationalFinanceID)" + (port49152RequiresNid ? " [NationalID required]" : "") + "\n");
                if (rank4Enabled)
                    write(out, "    3. Register Rank 4 JWSTNJ21 server" + (rank4RequiresKey ? " [public.key required]" : "") + "\n");
                write(out, "    4. Quit\n");
                write(out, "\n  directory> ");
                out.flush();

                String choice = in.readLine();
                if (choice == null) break;
                choice = choice.trim();

                if ("4".equals(choice) || "quit".equalsIgnoreCase(choice)) break;

                if ("1".equals(choice) && port20000Enabled)
                {
                    if (port20000RequiresNid && nationalId < 0)
                    {
                        nationalId = promptNationalId(in, out);
                        if (nationalId < 0) { write(out, "  Access denied — NationalID required.\n\n"); continue; }
                    }
                    write(out, "\n  Port 20000 Servers (Strernary™):\n");
                    writeServerList(out, SERVERS_20000_PATH);
                    write(out, "\n");
                }
                else if ("2".equals(choice) && port49152Enabled)
                {
                    if (port49152RequiresNid && nationalId < 0)
                    {
                        nationalId = promptNationalId(in, out);
                        if (nationalId < 0) { write(out, "  Access denied — NationalID required.\n\n"); continue; }
                    }
                    write(out, "\n  Port 49152 Servers (NationalFinanceID):\n");
                    writeServerList(out, SERVERS_49152_PATH);
                    write(out, "\n");
                }
                else if ("3".equals(choice) && rank4Enabled)
                {
                    handleRank4Registration(in, out, client);
                }
                else
                {
                    write(out, "  Invalid selection.\n\n");
                }
            }

            write(out, "  Goodbye.\n");
            out.flush();
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private long promptNationalId(BufferedReader in, OutputStream out) throws IOException
    {
        write(out, "  Enter NationalID: ");
        out.flush();
        String line = in.readLine();
        if (line == null || line.trim().isEmpty()) return -1;
        try
        {
            long nid = Long.parseLong(line.trim());
            var profile = database.N21Store.loadNationalFinanceID(nid);
            if (profile != null) { write(out, "  Verified NationalID " + nid + ".\n"); return nid; }
            else { write(out, "  NationalID not found.\n"); return -1; }
        }
        catch (NumberFormatException e) { write(out, "  Invalid ID format.\n"); return -1; }
    }

    private void handleRank4Registration(BufferedReader in, OutputStream out, Socket client) throws IOException
    {
        if (!rank4RequiresKey)
        {
            write(out, "  Enter your server address (IP or domain): ");
            out.flush();
            String addr = in.readLine();
            if (addr != null && !addr.trim().isEmpty())
            {
                registeredRank4Servers.add(addr.trim());
                write(out, "  Registered: " + addr.trim() + "\n\n");
            }
            return;
        }

        write(out, "\n  Rank 4 JWSTNJ21 Registration\n");
        write(out, "  —————————————————————————————\n");
        write(out, "  Send your public.key contents (single line, base64):\n  > ");
        out.flush();

        String keyLine = in.readLine();
        if (keyLine == null || keyLine.trim().isEmpty())
        {
            write(out, "  Registration aborted — no key provided.\n\n");
            return;
        }

        // Byte-for-byte comparison against GitHub public.key
        if (cachedPublicKey == null) fetchPublicKey();

        if (cachedPublicKey == null)
        {
            write(out, "  ERROR: Cannot verify — public.key unavailable from GitHub.\n\n");
            return;
        }

        byte[] submitted = keyLine.trim().getBytes(StandardCharsets.UTF_8);
        if (!java.util.Arrays.equals(submitted, cachedPublicKey))
        {
            write(out, "  DENIED — public.key mismatch.\n\n");
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Strernary™ Directory: Rank 4 registration DENIED from " +
                client.getInetAddress().getHostAddress() + " .",
                commons.color.ColorPalette.COLOR_STANDARD_RED);
            return;
        }

        // Key verified — collect server address
        write(out, "  Key verified. Enter your Rank 4 server address (IP or domain): ");
        out.flush();
        String addr = in.readLine();
        if (addr != null && !addr.trim().isEmpty())
        {
            registeredRank4Servers.add(addr.trim());
            write(out, "  Rank 4 JWSTNJ21 server registered: " + addr.trim() + "\n\n");
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Strernary™ Directory: Rank 4 registered — " + addr.trim() + " .");
        }
        else
        {
            write(out, "  Registration aborted — no address provided.\n\n");
        }
    }

    /**
     * Handles XML packet forwarding: parses <nwe-route><port>N</port><payload>...</payload></nwe-route>
     * and routes payload to the appropriate local IP via NIO masquerade.
     */
    private void handleXmlForward(BufferedReader in, OutputStream out, Socket client) throws IOException
    {
        StringBuilder xml = new StringBuilder();
        String line;
        while ((line = in.readLine()) != null)
        {
            xml.append(line).append("\n");
            if (line.contains("</nwe-route>")) break;
        }

        try
        {
            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
            dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            DocumentBuilder db = dbf.newDocumentBuilder();
            Document doc = db.parse(new org.xml.sax.InputSource(new StringReader(xml.toString())));

            NodeList portNodes = doc.getElementsByTagName("port");
            NodeList payloadNodes = doc.getElementsByTagName("payload");

            if (portNodes.getLength() == 0)
            {
                write(out, "ERROR|NO_PORT_IN_PACKET\n");
                return;
            }

            int targetPort = Integer.parseInt(portNodes.item(0).getTextContent().trim());
            String payload = payloadNodes.getLength() > 0 ? payloadNodes.item(0).getTextContent().trim() : "";

            // Only allow forwarding to known NWE service ports
            int[] ALLOWED_FORWARD_PORTS = {2000, 5000, 5512, 6682, 7743, 7744, 9999, 10085, 20000, 49133, 49144, 49152, 49155, 49166, 49177, 49188, 49199, 49200, 49201, 49202, 49203, 49204, 49210, 49211, 49212, 49213, 49214};
            boolean portAllowed = false;
            for (int allowed : ALLOWED_FORWARD_PORTS)
                if (targetPort == allowed) { portAllowed = true; break; }
            if (!portAllowed)
            {
                write(out, "ERROR|PORT_NOT_WHITELISTED|" + targetPort + "\n");
                return;
            }

            int maxPort = nioEngine != null ? nioEngine.getMaxPort() : 65535;
            if (targetPort < 0 || targetPort > maxPort)
            {
                write(out, "ERROR|PORT_OUT_OF_RANGE|max=" + maxPort + "\n");
                return;
            }

            // Resolve target address via NIO masquerade
            InetSocketAddress target = nioEngine != null
                ? nioEngine.resolveAddress(targetPort)
                : new InetSocketAddress("127.0.0.1", targetPort);

            // Forward payload and relay response
            try (SocketChannel ch = SocketChannel.open())
            {
                ch.configureBlocking(true);
                ch.connect(target);
                ch.write(ByteBuffer.wrap((payload + "\n").getBytes(StandardCharsets.UTF_8)));

                ByteBuffer resp = ByteBuffer.allocate(8192);
                ch.socket().setSoTimeout(5000);
                int n = ch.read(resp);
                if (n > 0)
                {
                    resp.flip();
                    byte[] data = new byte[resp.remaining()];
                    resp.get(data);
                    out.write(data);
                }
                else
                {
                    write(out, "ERROR|NO_RESPONSE_FROM_PORT_" + targetPort + "\n");
                }
            }
            catch (Exception e)
            {
                write(out, "ERROR|FORWARD_FAILED|" + target + "|" + e.getMessage() + "\n");
            }
        }
        catch (Exception e)
        {
            write(out, "ERROR|INVALID_XML_PACKET\n");
            ExceptionHandler.dispatch(e);
        }
    }

    private void writeServerList(OutputStream out, String xmlPath) throws IOException
    {
        try
        {
            File f = new File(xmlPath);
            if (!f.exists()) { write(out, "    (config file not found)\n"); return; }
            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
            dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            DocumentBuilder db = dbf.newDocumentBuilder();
            Document doc = db.parse(f);
            NodeList servers = doc.getElementsByTagName("server");
            for (int i = 0; i < servers.getLength(); i++)
            {
                Element srv = (Element) servers.item(i);
                String name = getText(srv, "name");
                String host = getText(srv, "host");
                String port = getText(srv, "port");
                NodeList addrs = srv.getElementsByTagName("address");
                write(out, "    " + name + " (" + host + ")\n");
                for (int j = 0; j < addrs.getLength(); j++)
                    write(out, "      → " + addrs.item(j).getTextContent().trim() + ":" + port + "\n");
            }
        }
        catch (Exception e) { write(out, "    (error reading server list)\n"); }
    }

    private void fetchPublicKey()
    {
        Thread.ofVirtual().start(() -> {
            try
            {
                URL url = URI.create(PUBLIC_KEY_URL).toURL();
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(5000);
                conn.setReadTimeout(5000);
                if (conn.getResponseCode() == 200)
                {
                    cachedPublicKey = conn.getInputStream().readAllBytes();
                    // Trim trailing newline for consistent comparison
                    String s = new String(cachedPublicKey, StandardCharsets.UTF_8).trim();
                    cachedPublicKey = s.getBytes(StandardCharsets.UTF_8);
                }
            }
            catch (Exception e) { ExceptionHandler.dispatch(e); }
        });
    }

    private void loadConfig()
    {
        try
        {
            File f = new File(CONFIG_PATH);
            if (!f.exists()) return;
            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
            dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            DocumentBuilder db = dbf.newDocumentBuilder();
            Document doc = db.parse(f);

            port20000Enabled = getBool(doc, "port-20000", "enabled", true);
            port49152Enabled = getBool(doc, "port-49152", "enabled", true);
            port20000RequiresNid = getBool(doc, "port-20000", "require-national-id", false);
            port49152RequiresNid = getBool(doc, "port-49152", "require-national-id", true);
            rank4Enabled = getBool(doc, "rank4-registration", "enabled", true);
            rank4RequiresKey = getBool(doc, "rank4-registration", "require-public-key", true);
            xmlForwardingEnabled = getBool(doc, "port-2000-forwarding", "enabled", true);
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private boolean getBool(Document doc, String parent, String child, boolean defaultVal)
    {
        NodeList parents = doc.getElementsByTagName(parent);
        if (parents.getLength() == 0) return defaultVal;
        Element p = (Element) parents.item(0);
        NodeList children = p.getElementsByTagName(child);
        if (children.getLength() == 0) return defaultVal;
        return Boolean.parseBoolean(children.item(0).getTextContent().trim());
    }

    private String getText(Element parent, String tag)
    {
        NodeList nl = parent.getElementsByTagName(tag);
        return nl.getLength() > 0 ? nl.item(0).getTextContent().trim() : "";
    }

    private void write(OutputStream out, String s) throws IOException
    {
        out.write(s.getBytes(StandardCharsets.UTF_8));
    }

    public void stop() { running = false; if (nioEngine != null) nioEngine.stop(); }
}
