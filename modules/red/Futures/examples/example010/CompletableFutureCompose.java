package red.Futures.examples.example010;
import java.util.concurrent.*;

public class CompletableFutureCompose {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future = CompletableFuture
            .supplyAsync(() -> "user-123")
            .thenCompose(userId -> CompletableFuture.supplyAsync(() -> "Profile of " + userId));
        System.out.println(future.get());
    }
}
