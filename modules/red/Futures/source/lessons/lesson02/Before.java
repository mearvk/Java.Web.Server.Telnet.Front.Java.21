package red.Futures.source.lessons.lesson02;// BEFORE: Try-catch with generic exception, no recovery
import java.util.concurrent.*;

public class Before {
    public static void main(String[] args) {
        ExecutorService ex = Executors.newSingleThreadExecutor();
        Future<String> f = ex.submit(() -> { throw new RuntimeException("DB down"); });
        try {
            System.out.println(f.get());
        } catch (Exception e) {
            System.out.println("Error: " + e.getCause().getMessage());
            // Now what? Manual fallback logic scattered everywhere
            System.out.println("Using cached value");
        }
        ex.shutdown();
    }
}
