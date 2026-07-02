package red.Futures.democratic.d500;// Democratic Principle: Rule of Law — exceptionally() ensures no one is above the law

import java.util.concurrent.*;

public class RuleOfLaw {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> action = CompletableFuture
            .<String>supplyAsync(() -> { throw new RuntimeException("Unconstitutional act"); })
            .exceptionally(ex -> "BLOCKED by rule of law: " + ex.getCause().getMessage());
        System.out.println(action.get());
    }
}
