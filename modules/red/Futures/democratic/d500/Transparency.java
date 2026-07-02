package red.Futures.democratic.d500;
// Democratic Principle: Transparency — all votes visible, no hidden state
import java.util.concurrent.*;
import java.util.*;

public class Transparency {
    public static void main(String[] args) throws Exception {
        List<CompletableFuture<String>> votes = List.of(
            CompletableFuture.supplyAsync(() -> "Citizen A: Yes"),
            CompletableFuture.supplyAsync(() -> "Citizen B: No"),
            CompletableFuture.supplyAsync(() -> "Citizen C: Yes")
        );
        CompletableFuture.allOf(votes.toArray(new CompletableFuture[0])).join();
        votes.forEach(v -> System.out.println(v.join())); // every vote is visible
    }
}
