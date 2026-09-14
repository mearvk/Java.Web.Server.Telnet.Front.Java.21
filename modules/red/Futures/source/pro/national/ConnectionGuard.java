package red.Futures.source.pro.national;

import java.net.Socket;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;

/**
 * ConnectionGuard — Non-blocking intake using CompletableFuture.supplyAsync().
 * Accepts and classifies connections without stalling the main accept loop.
 * Enforces MAX_CONNECTIONS (5040) and MAX_PER_IP (1) before admission.
 */
public class ConnectionGuard
{
    private static final int MAX_CONNECTIONS = 5040;
    private static final int MAX_PER_IP = 1;

    private final ExecutorService executor;
    private final java.util.concurrent.atomic.AtomicInteger active = new java.util.concurrent.atomic.AtomicInteger(0);
    private final java.util.concurrent.ConcurrentHashMap<String, java.util.concurrent.atomic.AtomicInteger> ipCount = new java.util.concurrent.ConcurrentHashMap<>();

    public ConnectionGuard(ExecutorService executor) { this.executor = executor; }

    public CompletableFuture<Socket> guardedAccept(java.net.ServerSocket server)
    {
        return CompletableFuture.supplyAsync(() ->
        {
            try
            {
                Socket s = server.accept();
                String ip = s.getInetAddress().getHostAddress();

                if (active.get() >= MAX_CONNECTIONS)
                    throw new RuntimeException("at capacity (" + MAX_CONNECTIONS + ")");

                var count = ipCount.computeIfAbsent(ip, k -> new java.util.concurrent.atomic.AtomicInteger(0));
                if (count.get() >= MAX_PER_IP)
                    throw new RuntimeException("per-IP limit (" + MAX_PER_IP + ")");

                active.incrementAndGet();
                count.incrementAndGet();
                return s;
            }
            catch (Exception e) { throw new RuntimeException(e); }
        }, executor);
    }

    public void release(String ip)
    {
        active.decrementAndGet();
        var count = ipCount.get(ip);
        if (count != null) count.decrementAndGet();
    }
}
