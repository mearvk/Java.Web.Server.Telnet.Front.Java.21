package red.Futures.source.examples.example012;
import java.util.concurrent.*;

public class CompletableFutureAsync {
    public static void main(String[] args) throws Exception {
        ExecutorService customPool = Executors.newFixedThreadPool(2);
        CompletableFuture<String> future = CompletableFuture
            .supplyAsync(() -> "Step 1", customPool)
            .thenApplyAsync(s -> s + " -> Step 2", customPool)
            .thenApplyAsync(s -> s + " -> Step 3", customPool);
        System.out.println(future.get());
        customPool.shutdown();
    }
}
