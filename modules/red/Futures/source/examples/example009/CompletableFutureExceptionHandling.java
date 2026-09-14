package red.Futures.source.examples.example009;

import java.util.concurrent.*;

public class CompletableFutureExceptionHandling {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future = CompletableFuture
            .supplyAsync(() -> {
                if (true) throw new RuntimeException("Something went wrong");
                return "OK";
            })
            .exceptionally(ex -> "Recovered: " + ex.getMessage());
        System.out.println(future.get());
    }
}
