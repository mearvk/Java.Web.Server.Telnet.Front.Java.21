package red.Futures.source.lessons.lesson10;// BEFORE: Mixing concerns — business logic, threading, and output together
import java.util.concurrent.*;

public class Before {
    public static void main(String[] args) throws Exception {
        ExecutorService ex = Executors.newFixedThreadPool(2);
        Future<Double> f = ex.submit(() -> {
            double price = 49.99;
            double tax = price * 0.08;
            double total = price + tax;
            System.out.println("Total: $" + String.format("%.2f", total));
            return total;
        });
        f.get();
        ex.shutdown();
    }
}
