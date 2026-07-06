package red.Futures.examples.example007;
import java.util.concurrent.*;
import java.util.stream.*;
import java.util.*;

public class CompletableFutureAllOf {
    public static void main(String[] args) throws Exception {
        List<CompletableFuture<String>> futures = IntStream.range(1, 6)
            .mapToObj(i -> CompletableFuture.supplyAsync(() -> "Task " + i + " done"))
            .collect(Collectors.toList());

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        futures.forEach(f -> System.out.println(f.join()));
    }
}
