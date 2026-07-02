package red.Futures.source.pro.national;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * GracefulTransfer — Connection lifecycle using shutdown() + new pool.
 * Clean release, budget reclaimed. Peaceful transfer of power.
 */
public class GracefulTransfer
{
    private ExecutorService currentPool;

    public GracefulTransfer(int threads) { this.currentPool = Executors.newFixedThreadPool(threads); }

    public ExecutorService getPool() { return currentPool; }

    public void transfer(int newThreads)
    {
        ExecutorService old = this.currentPool;
        this.currentPool = Executors.newFixedThreadPool(newThreads);
        old.shutdown();
    }

    public void shutdown() { currentPool.shutdown(); }
}
