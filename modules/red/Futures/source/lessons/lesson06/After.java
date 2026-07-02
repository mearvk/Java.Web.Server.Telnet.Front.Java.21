package red.Futures.source.lessons.lesson06;// AFTER: Scoped executor with try-finally for guaranteed cleanup
import java.util.concurrent.*;

public class After {
    public static void main(String[] args) throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            CompletableFuture<String> f = CompletableFuture.supplyAsync(() -> "result", executor);
            System.out.println(f.get());
        } finally {
            executor.shutdown();
        }
    }
}
