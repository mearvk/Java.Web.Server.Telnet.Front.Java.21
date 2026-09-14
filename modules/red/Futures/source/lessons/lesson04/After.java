package red.Futures.source.lessons.lesson04;// AFTER: allOf + stream for clean fan-out/fan-in
import java.util.concurrent.*;
import java.util.*;
import java.util.stream.*;

public class After {
    public static void main(String[] args) {
        List<CompletableFuture<String>> futures = IntStream.range(0, 5)
            .mapToObj(i -> CompletableFuture.supplyAsync(() -> "Result " + i))
            .collect(Collectors.toList());

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        List<String> results = futures.stream().map(CompletableFuture::join).collect(Collectors.toList());
        System.out.println(results);
    }
}
