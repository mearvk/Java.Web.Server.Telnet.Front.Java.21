package red.Futures.lessons.lesson01;
// BEFORE: Nested callbacks, hard to read
import java.util.concurrent.*;

public class Before {
    public static void main(String[] args) throws Exception {
        ExecutorService ex = Executors.newFixedThreadPool(3);
        Future<String> f1 = ex.submit(() -> { Thread.sleep(100); return "user-1"; });
        String userId = f1.get();
        Future<String> f2 = ex.submit(() -> { Thread.sleep(100); return "Profile of " + userId; });
        String profile = f2.get();
        Future<String> f3 = ex.submit(() -> { Thread.sleep(100); return profile + " [enriched]"; });
        System.out.println(f3.get());
        ex.shutdown();
    }
}
