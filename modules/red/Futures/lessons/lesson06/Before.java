package red.Futures.lessons.lesson06;
// BEFORE: Shared mutable executor passed everywhere, never shut down
import java.util.concurrent.*;

public class Before {
    static ExecutorService executor = Executors.newCachedThreadPool(); // global mutable state

    public static void main(String[] args) throws Exception {
        Future<String> f = executor.submit(() -> "result");
        System.out.println(f.get());
        // executor never shut down — resource leak
    }
}
