package red.Futures.lessons.lesson03;
// AFTER: Parallel execution with thenCombine — both run concurrently
import java.util.concurrent.*;

public class After {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> price = CompletableFuture
            .supplyAsync(() -> { try{Thread.sleep(1000);}catch(Exception e){} return "Price: $100"; });
        CompletableFuture<String> stock = CompletableFuture
            .supplyAsync(() -> { try{Thread.sleep(1000);}catch(Exception e){} return "Stock: 42"; });

        String result = price.thenCombine(stock, (p, s) -> p + ", " + s).get();
        System.out.println(result); // ~1 second total
    }
}
