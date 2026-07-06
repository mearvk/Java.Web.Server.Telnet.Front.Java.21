package red.Futures.examples.example008;
import java.util.concurrent.*;

public class CompletableFutureAnyOf {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> slow = CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(3000); } catch (InterruptedException e) {}
            return "Slow";
        });
        CompletableFuture<String> fast = CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(100); } catch (InterruptedException e) {}
            return "Fast";
        });
        Object result = CompletableFuture.anyOf(slow, fast).get();
        System.out.println("First completed: " + result);
    }
}
