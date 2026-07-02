package red.Futures.source.lessons.lesson10;// AFTER: Each stage has one responsibility
import java.util.concurrent.*;

public class After {
    static double fetchPrice() { return 49.99; }
    static double addTax(double price) { return price * 1.08; }
    static String format(double total) { return "Total: $" + String.format("%.2f", total); }

    public static void main(String[] args) throws Exception {
        CompletableFuture<Void> pipeline = CompletableFuture
            .supplyAsync(After::fetchPrice)
            .thenApply(After::addTax)
            .thenApply(After::format)
            .thenAccept(System.out::println);

        pipeline.get();
    }
}
