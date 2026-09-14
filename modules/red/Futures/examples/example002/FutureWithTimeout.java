package red.Futures.examples.example002;
import java.util.concurrent.*;

public class FutureWithTimeout {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Future<String> future = executor.submit(() -> {
            Thread.sleep(5000);
            return "Done";
        });
        try {
            String result = future.get(2, TimeUnit.SECONDS);
            System.out.println(result);
        } catch (TimeoutException e) {
            System.out.println("Timed out waiting for result");
            future.cancel(true);
        } catch (Exception e) {
            e.printStackTrace();
        }
        executor.shutdown();
    }
}
