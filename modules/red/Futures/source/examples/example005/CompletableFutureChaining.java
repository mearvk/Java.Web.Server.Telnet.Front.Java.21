package red.Futures.source.examples.example005;

import java.util.concurrent.*;

public class CompletableFutureChaining {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future = CompletableFuture
            .supplyAsync(() -> "Hello")
            .thenApply(s -> s + " World")
            .thenApply(String::toUpperCase);
        System.out.println(future.get());
    }
}
