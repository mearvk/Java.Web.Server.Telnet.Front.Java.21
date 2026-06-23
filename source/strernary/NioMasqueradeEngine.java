/**
 * NioMasqueradeEngine — NIO-based front layer for local IP bindings.
 *
 * Binds ServerSocketChannels on 127.0.0.1 through 127.0.0.17 using NIO
 * Selectors. Bridges incoming NIO connections to the existing blocking
 * architecture by forwarding data transparently.
 *
 * In "standard" mode (0-65535): binds only 127.0.0.1 for managed ports.
 * In "extended" mode (0-1048576): distributes across 127.0.0.1-17 where
 * each IP handles a 65536-port slice (logical ports mapped to physical 1-65535).
 *
 * Configuration: configuration/nio-masquerade-config.xml
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 23 2026 EST
 */

package strernary;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import org.w3c.dom.*;
import javax.xml.parsers.*;

import java.io.*;
import java.net.*;
import java.nio.*;
import java.nio.channels.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

public class NioMasqueradeEngine implements Runnable
{
    private static final String CONFIG_PATH = "configuration/nio-masquerade-config.xml";
    private static final String THREAD_NAME = "NIO_MASQUERADE";

    // Config
    private volatile boolean enabled = true;
    private volatile boolean extendedMode = false; // false = standard (0-65535)
    private volatile int portsPerIp = 65536;
    private volatile int readBufferSize = 8192;
    private volatile int idleTimeoutMs = 30000;
    private final List<Integer> managedPorts = new CopyOnWriteArrayList<>();

    // State
    private volatile boolean running = true;
    private Selector selector;
    private final ConcurrentHashMap<SocketChannel, SocketChannel> bridgeMap = new ConcurrentHashMap<>();
    private final List<ServerSocketChannel> serverChannels = new CopyOnWriteArrayList<>();
    private final ConcurrentHashMap<String, Integer> moduleRegistry = new ConcurrentHashMap<>();

    public NioMasqueradeEngine()
    {
        loadConfig();
        if (!enabled) return;
        Thread.ofVirtual().name(THREAD_NAME).start(this);
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". NioMasquerade™ engine starting — mode=" + (extendedMode ? "extended" : "standard") + " .");
    }

    @Override
    public void run()
    {
        try
        {
            selector = Selector.open();
            bindLocalIPs();

            while (running)
            {
                selector.select(1000);
                Set<SelectionKey> keys = selector.selectedKeys();
                Iterator<SelectionKey> it = keys.iterator();

                while (it.hasNext())
                {
                    SelectionKey key = it.next();
                    it.remove();

                    if (!key.isValid()) continue;

                    if (key.isAcceptable())
                        accept(key);
                    else if (key.isReadable())
                        read(key);
                }
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        finally { cleanup(); }
    }

    private void bindLocalIPs()
    {
        try
        {
            if (!extendedMode)
            {
                // Standard mode: bind managed ports on 127.0.0.1 only
                for (int port : managedPorts)
                    bindChannel("127.0.0.1", port);
            }
            else
            {
                // Extended mode: bind port 1 on each 127.0.0.X (control channel)
                // Actual port resolution happens via the masquerade forwarding
                for (int i = 1; i <= 17; i++)
                {
                    String ip = "127.0.0." + i;
                    bindChannel(ip, 1);
                }
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private void bindChannel(String ip, int port)
    {
        try
        {
            ServerSocketChannel ssc = ServerSocketChannel.open();
            ssc.configureBlocking(false);
            ssc.bind(new InetSocketAddress(ip, port));
            ssc.register(selector, SelectionKey.OP_ACCEPT, ip + ":" + port);
            serverChannels.add(ssc);
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". NioMasquerade™ bound " + ip + ":" + port + " .");
        }
        catch (BindException e)
        {
            // Port already in use by existing architecture — expected in standard mode
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". NioMasquerade™ skipped " + ip + ":" + port + " (in use) .");
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private void accept(SelectionKey key)
    {
        try
        {
            ServerSocketChannel ssc = (ServerSocketChannel) key.channel();
            SocketChannel client = ssc.accept();
            if (client == null) return;
            client.configureBlocking(false);
            client.register(selector, SelectionKey.OP_READ, key.attachment());
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private void read(SelectionKey key)
    {
        SocketChannel client = (SocketChannel) key.channel();
        ByteBuffer buf = ByteBuffer.allocate(readBufferSize);

        try
        {
            int bytesRead = client.read(buf);
            if (bytesRead == -1) { closeChannel(client); return; }

            buf.flip();
            byte[] data = new byte[buf.remaining()];
            buf.get(data);

            // Check if there's already a bridge established
            SocketChannel bridge = bridgeMap.get(client);
            if (bridge != null && bridge.isOpen())
            {
                bridge.write(ByteBuffer.wrap(data));
                return;
            }

            // No bridge yet — forward to existing architecture on localhost
            String bindInfo = (String) key.attachment();
            int targetPort = resolveTargetPort(bindInfo, data);

            if (targetPort > 0)
            {
                SocketChannel target = SocketChannel.open();
                target.configureBlocking(false);
                target.connect(new InetSocketAddress("127.0.0.1", targetPort));

                // Wait for connection (non-blocking with brief spin)
                long start = System.currentTimeMillis();
                while (!target.finishConnect() && System.currentTimeMillis() - start < 3000)
                    Thread.onSpinWait();

                if (target.isConnected())
                {
                    bridgeMap.put(client, target);
                    target.register(selector, SelectionKey.OP_READ, "bridge-back:" + bindInfo);
                    bridgeMap.put(target, client);
                    target.write(ByteBuffer.wrap(data));
                }
                else
                {
                    target.close();
                    client.write(ByteBuffer.wrap("ERROR|CONNECT_FAILED\n".getBytes(StandardCharsets.UTF_8)));
                }
            }
        }
        catch (Exception e)
        {
            closeChannel(client);
            ExceptionHandler.dispatch(e);
        }
    }

    /**
     * Resolves the target port for forwarding based on the binding info
     * and the incoming data (which may contain the port in extended mode).
     */
    private int resolveTargetPort(String bindInfo, byte[] data)
    {
        if (!extendedMode)
        {
            // Standard mode: target port = the port we're bound on
            String[] parts = bindInfo.split(":");
            return Integer.parseInt(parts[1]);
        }

        // Extended mode: compute from IP binding
        // 127.0.0.X -> base port = (X-1) * portsPerIp
        // Actual target = basePort + logical port from data (mod 65536 for physical)
        String[] parts = bindInfo.split(":");
        String ip = parts[0];
        int octet = Integer.parseInt(ip.substring(ip.lastIndexOf('.') + 1));
        int baseLogical = (octet - 1) * portsPerIp;

        // The physical port is the logical port mod 65536
        // In extended mode the actual NWE service maps to physical ports
        return baseLogical > 65535 ? (baseLogical % 65536) + 1 : Integer.parseInt(parts[1]);
    }

    /**
     * Resolves the local IP and physical port for a given logical port number.
     * Used by port 2000 XML forwarding.
     *
     * @param logicalPort port 0-1048576
     * @return InetSocketAddress on the correct 127.0.0.X with physical port
     */
    public InetSocketAddress resolveAddress(int logicalPort)
    {
        if (!extendedMode || logicalPort <= 65535)
            return new InetSocketAddress("127.0.0.1", logicalPort);

        int ipIndex = (logicalPort / portsPerIp) + 1;
        int physicalPort = (logicalPort % portsPerIp);
        if (physicalPort == 0) physicalPort = 1; // Avoid port 0
        if (ipIndex > 17) ipIndex = 17; // Cap at 127.0.0.17

        return new InetSocketAddress("127.0.0." + ipIndex, physicalPort);
    }

    /**
     * Returns whether extended port range (0-1048576) is active.
     */
    public boolean isExtendedMode() { return extendedMode; }

    /**
     * Returns maximum valid port number for current mode.
     */
    public int getMaxPort() { return extendedMode ? 1048576 : 65535; }

    /**
     * Registers a masquerade-aware module with its logical port.
     * Called by NioModuleScanner during startup discovery.
     */
    public void registerModule(String moduleId, int port)
    {
        moduleRegistry.put(moduleId, port);
        if (!managedPorts.contains(port)) managedPorts.add(port);
    }

    /**
     * Returns all registered module IDs and their ports.
     */
    public Map<String, Integer> getRegisteredModules() { return Collections.unmodifiableMap(moduleRegistry); }

    private void closeChannel(SocketChannel ch)
    {
        try
        {
            SocketChannel bridge = bridgeMap.remove(ch);
            if (bridge != null) { bridgeMap.remove(bridge); bridge.close(); }
            ch.close();
        }
        catch (Exception e) { /* ignore */ }
    }

    private void cleanup()
    {
        for (ServerSocketChannel ssc : serverChannels)
            try { ssc.close(); } catch (Exception e) { /* ignore */ }
        try { if (selector != null) selector.close(); } catch (Exception e) { /* ignore */ }
    }

    private void loadConfig()
    {
        try
        {
            File f = new File(CONFIG_PATH);
            if (!f.exists()) return;
            DocumentBuilder db = DocumentBuilderFactory.newInstance().newDocumentBuilder();
            Document doc = db.parse(f);

            enabled = getBool(doc, "enabled", true);
            String mode = getText(doc, "port-range-mode");
            extendedMode = "extended".equalsIgnoreCase(mode);

            NodeList ppn = doc.getElementsByTagName("ports-per-ip");
            if (ppn.getLength() > 0) portsPerIp = Integer.parseInt(ppn.item(0).getTextContent().trim());

            NodeList rbs = doc.getElementsByTagName("read-buffer-size");
            if (rbs.getLength() > 0) readBufferSize = Integer.parseInt(rbs.item(0).getTextContent().trim());

            NodeList ito = doc.getElementsByTagName("idle-timeout-ms");
            if (ito.getLength() > 0) idleTimeoutMs = Integer.parseInt(ito.item(0).getTextContent().trim());

            NodeList ports = doc.getElementsByTagName("managed-ports");
            if (ports.getLength() > 0)
            {
                NodeList portNodes = ((Element) ports.item(0)).getElementsByTagName("port");
                for (int i = 0; i < portNodes.getLength(); i++)
                    managedPorts.add(Integer.parseInt(portNodes.item(i).getTextContent().trim()));
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private boolean getBool(Document doc, String tag, boolean def)
    {
        NodeList nl = doc.getElementsByTagName(tag);
        if (nl.getLength() == 0) return def;
        return Boolean.parseBoolean(nl.item(0).getTextContent().trim());
    }

    private String getText(Document doc, String tag)
    {
        NodeList nl = doc.getElementsByTagName(tag);
        return nl.getLength() > 0 ? nl.item(0).getTextContent().trim() : "";
    }

    public void stop() { running = false; if (selector != null) selector.wakeup(); }
}
