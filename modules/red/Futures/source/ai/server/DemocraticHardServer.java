package red.Futures.source.ai.server;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.InetAddress;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * DemocraticHardServer — hardened backend server on port 5000.
 * Handles democratic connections: questions, registrations, deregistrations.
 *
 * Modeled after NationalAwareHardService from:
 * github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21
 *
 * Hardening:
 * • MAX_CONNECTIONS = 5040
 * • MAX_PER_IP = 1
 * • Socket timeout = 58 minutes
 * • Backlog 128, SO_REUSEADDR, TcpNoDelay, KeepAlive
 * • Graceful shutdown via volatile flag
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class DemocraticHardServer extends Thread
{
    private static final int PORT = 5000;
    private static final int MAX_CONNECTIONS = 5040;
    private static final int MAX_PER_IP = 1;
    private static final int TIMEOUT_MS = 58 * 60 * 1000;
    private static final int BACKLOG = 128;

    private ServerSocket serverSocket;
    private volatile boolean running = true;
    private final AtomicInteger activeConnections = new AtomicInteger(0);
    private final ConcurrentHashMap<String, AtomicInteger> ipCount = new ConcurrentHashMap<>();
    private final ExecutorService pool = Executors.newFixedThreadPool(64);

    public DemocraticHardServer()
    {
        this.setName("DemocraticHardServer-" + PORT);
    }

    public void bind() throws IOException
    {
        this.serverSocket = new ServerSocket(PORT, BACKLOG, InetAddress.getByName("0.0.0.0"));
        this.serverSocket.setReuseAddress(true);
        System.out.println("[DemocraticHardServer] Bound port=" + PORT
            + " max=" + MAX_CONNECTIONS + " perIP=" + MAX_PER_IP);
    }

    @Override
    public void run()
    {
        while (running)
        {
            Socket socket = null;
            try
            {
                socket = serverSocket.accept();
                String remoteIp = socket.getInetAddress().getHostAddress();

                if (activeConnections.get() >= MAX_CONNECTIONS)
                {
                    reject(socket, remoteIp, "at capacity");
                    continue;
                }

                AtomicInteger count = ipCount.computeIfAbsent(remoteIp, k -> new AtomicInteger(0));
                if (count.get() >= MAX_PER_IP)
                {
                    reject(socket, remoteIp, "per-IP limit");
                    continue;
                }

                socket.setSoTimeout(TIMEOUT_MS);
                socket.setTcpNoDelay(true);
                socket.setKeepAlive(true);

                activeConnections.incrementAndGet();
                count.incrementAndGet();

                final Socket accepted = socket;
                pool.submit(() -> handleConnection(accepted, remoteIp));
            }
            catch (Exception e)
            {
                if (running) e.printStackTrace();
                try { if (socket != null && !socket.isClosed()) socket.close(); } catch (Exception ignored) {}
            }
        }
    }

    private void handleConnection(Socket socket, String ip)
    {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
             BufferedWriter out = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream())))
        {
            String line;
            while ((line = in.readLine()) != null)
            {
                String response = routeRequest(line.trim());
                out.write(response);
                out.newLine();
                out.flush();
            }
        }
        catch (Exception e)
        {
            // connection closed or timed out
        }
        finally
        {
            release(socket, ip);
        }
    }

    /**
     * Routes democratic requests:
     * REGISTER <data>       — democratic registration
     * DEREGISTER <id>       — democratic deregistration
     * QUESTION <text>       — democratic question
     * SPECULATE <features>  — AI tax defense speculation
     */
    private String routeRequest(String request)
    {
        if (request.startsWith("REGISTER "))
            return "ACK:REGISTERED:" + System.currentTimeMillis();
        else if (request.startsWith("DEREGISTER "))
            return "ACK:DEREGISTERED:" + System.currentTimeMillis();
        else if (request.startsWith("QUESTION "))
            return "ACK:QUESTION_RECEIVED:" + System.currentTimeMillis();
        else if (request.startsWith("SPECULATE "))
            return "ACK:SPECULATION_QUEUED:" + System.currentTimeMillis();
        else
            return "ERR:UNKNOWN_COMMAND";
    }

    private void reject(Socket s, String ip, String reason)
    {
        System.out.println("[DemocraticHardServer] REJECTED " + ip + " — " + reason);
        try { s.close(); } catch (Exception ignored) {}
    }

    private void release(Socket socket, String ip)
    {
        activeConnections.decrementAndGet();
        AtomicInteger count = ipCount.get(ip);
        if (count != null) count.decrementAndGet();
        try { if (!socket.isClosed()) socket.close(); } catch (Exception ignored) {}
    }

    public void shutdown()
    {
        running = false;
        pool.shutdownNow();
        try { if (serverSocket != null) serverSocket.close(); } catch (Exception ignored) {}
        System.out.println("[DemocraticHardServer] Shutdown complete.");
    }

    public static void main(String[] args) throws Exception
    {
        DemocraticHardServer server = new DemocraticHardServer();
        server.bind();
        server.start();
        Runtime.getRuntime().addShutdownHook(new Thread(server::shutdown));
    }
}
