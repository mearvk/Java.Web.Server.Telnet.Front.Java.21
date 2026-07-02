package red.Futures.democratic.d500;
// Democratic Principle: Checks and Balances — no single branch proceeds unchecked
import java.util.concurrent.*;

public class ChecksAndBalances {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> legislative = CompletableFuture.supplyAsync(() -> "Bill proposed");
        CompletableFuture<String> executive = legislative.thenApply(bill -> bill + " -> Signed");
        CompletableFuture<String> judicial = executive.thenApply(law -> {
            if (law.contains("Signed")) return law + " -> Constitutional ✓";
            return law + " -> VETOED";
        });
        System.out.println(judicial.get());
    }
}
