package red.Futures.examples.example006;
import java.util.concurrent.*;

public class CompletableFutureCombine {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future1 = CompletableFuture.supplyAsync(() -> "Hello");
        CompletableFuture<String> future2 = CompletableFuture.supplyAsync(() -> "World");
        CompletableFuture<String> combined = future1.thenCombine(future2, (a, b) -> a + " " + b);
        System.out.println(combined.get());
    }
}
