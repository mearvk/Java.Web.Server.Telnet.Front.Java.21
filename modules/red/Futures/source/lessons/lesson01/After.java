package red.Futures.source.lessons.lesson01;// AFTER: Clean chain with thenCompose — no blocking between steps
import java.util.concurrent.*;

public class After {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> result = CompletableFuture
            .supplyAsync(() -> "user-1")
            .thenCompose(userId -> CompletableFuture.supplyAsync(() -> "Profile of " + userId))
            .thenApply(profile -> profile + " [enriched]");

        System.out.println(result.get());
    }
}
