package red.Futures.lessons.lesson02;
// AFTER: Declarative error recovery with exceptionally()
import java.util.concurrent.*;

public class After {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> result = CompletableFuture
            .<String>supplyAsync(() -> { throw new RuntimeException("DB down"); })
            .exceptionally(ex -> "cached-value");

        System.out.println(result.get());
    }
}
