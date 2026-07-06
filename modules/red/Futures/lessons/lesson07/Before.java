package red.Futures.lessons.lesson07;
// BEFORE: Polling isDone() in a busy loop
import java.util.concurrent.*;

public class Before {
    public static void main(String[] args) throws Exception {
        ExecutorService ex = Executors.newSingleThreadExecutor();
        Future<String> f = ex.submit(() -> { Thread.sleep(500); return "done"; });
        while (!f.isDone()) {
            Thread.sleep(50); // wasteful polling
        }
        System.out.println(f.get());
        ex.shutdown();
    }
}
