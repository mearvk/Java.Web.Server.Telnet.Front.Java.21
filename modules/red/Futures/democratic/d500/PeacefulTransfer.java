package red.Futures.democratic.d500;
// Democratic Principle: Peaceful Transfer of Power — orderly shutdown and handoff
import java.util.concurrent.*;

public class PeacefulTransfer {
    public static void main(String[] args) throws Exception {
        ExecutorService currentAdmin = Executors.newSingleThreadExecutor();
        CompletableFuture<String> term = CompletableFuture.supplyAsync(() -> "Term complete", currentAdmin);
        term.get();
        currentAdmin.shutdown(); // graceful shutdown
        currentAdmin.awaitTermination(5, TimeUnit.SECONDS);

        ExecutorService newAdmin = Executors.newSingleThreadExecutor();
        CompletableFuture<String> newTerm = CompletableFuture.supplyAsync(() -> "New administration active", newAdmin);
        System.out.println(newTerm.get());
        newAdmin.shutdown();
    }
}
