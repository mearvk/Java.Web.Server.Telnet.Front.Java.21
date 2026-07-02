package red.Futures.examples.example001;
import java.util.concurrent.*;

public class BasicFutureGet {
    public static void main(String[] args) throws Exception {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Future<String> future = executor.submit(() -> {
            Thread.sleep(1000);
            return "Result ready";
        });
        System.out.println(future.get());
        executor.shutdown();
    }
}
