package red.Futures.examples.example004;
import java.util.concurrent.*;

public class CompletableFutureBasic {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(500); } catch (InterruptedException e) {}
            return "Hello from CompletableFuture";
        });
        System.out.println(future.get());
    }
}
