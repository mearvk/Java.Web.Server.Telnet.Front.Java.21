package red.Futures.source.lessons.lesson03;// BEFORE: Sequential execution of independent tasks
import java.util.concurrent.*;

public class Before {
    public static void main(String[] args) throws Exception {
        ExecutorService ex = Executors.newSingleThreadExecutor();
        Future<String> f1 = ex.submit(() -> { Thread.sleep(1000); return "Price: $100"; });
        String price = f1.get(); // blocks
        Future<String> f2 = ex.submit(() -> { Thread.sleep(1000); return "Stock: 42"; });
        String stock = f2.get(); // blocks again
        System.out.println(price + ", " + stock); // 2+ seconds total
        ex.shutdown();
    }
}
