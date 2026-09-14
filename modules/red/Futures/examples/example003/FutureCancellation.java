package red.Futures.examples.example003;
import java.util.concurrent.*;

public class FutureCancellation {
    public static void main(String[] args) throws Exception {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Future<String> future = executor.submit(() -> {
            Thread.sleep(10000);
            return "Never returned";
        });
        Thread.sleep(500);
        future.cancel(true);
        System.out.println("Cancelled: " + future.isCancelled());
        System.out.println("Done: " + future.isDone());
        executor.shutdown();
    }
}
