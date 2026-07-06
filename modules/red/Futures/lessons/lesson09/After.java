package red.Futures.lessons.lesson09;
// AFTER: Properly typed — compiler enforces correctness
import java.util.concurrent.*;

public class After {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> "typed result");
        String result = future.get(); // no cast needed
        System.out.println(result);
    }
}
