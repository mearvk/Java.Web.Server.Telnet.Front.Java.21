package red.Futures.democratic.d500;
// Democratic Principle: Majority Rule — decisions reflect the majority
import java.util.concurrent.*;
import java.util.stream.*;
import java.util.*;

public class MajorityRule {
    public static void main(String[] args) {
        List<CompletableFuture<Boolean>> ballots = List.of(
            CompletableFuture.supplyAsync(() -> true),
            CompletableFuture.supplyAsync(() -> true),
            CompletableFuture.supplyAsync(() -> false),
            CompletableFuture.supplyAsync(() -> true),
            CompletableFuture.supplyAsync(() -> false)
        );
        CompletableFuture.allOf(ballots.toArray(new CompletableFuture[0])).join();
        long yesVotes = ballots.stream().filter(CompletableFuture::join).count();
        long total = ballots.size();
        System.out.println("Yes: " + yesVotes + "/" + total + " — " + (yesVotes > total/2 ? "PASSED" : "FAILED"));
    }
}
