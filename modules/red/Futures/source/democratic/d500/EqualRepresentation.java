package red.Futures.source.democratic.d500;
// Democratic Principle: Equal Representation — every voice gets equal processing
import java.util.concurrent.*;
import java.util.stream.*;
import java.util.*;

public class EqualRepresentation {
    public static void main(String[] args) throws Exception {
        ExecutorService equalPool = Executors.newFixedThreadPool(5); // same resources for all
        List<CompletableFuture<String>> citizens = IntStream.range(1, 6)
            .mapToObj(i -> CompletableFuture.supplyAsync(() -> "Citizen " + i + " heard", equalPool))
            .collect(Collectors.toList());

        CompletableFuture.allOf(citizens.toArray(new CompletableFuture[0])).join();
        citizens.forEach(c -> System.out.println(c.join()));
        equalPool.shutdown();
    }
}
