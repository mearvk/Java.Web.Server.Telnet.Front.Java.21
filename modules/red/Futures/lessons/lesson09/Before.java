package red.Futures.lessons.lesson09;
// BEFORE: Raw types, no generics — unclear what the future holds
import java.util.concurrent.*;

public class Before {
    public static void main(String[] args) throws Exception {
        ExecutorService ex = Executors.newSingleThreadExecutor();
        Future f = ex.submit(() -> "typed result"); // raw type
        Object result = f.get(); // requires casting
        System.out.println((String) result);
        ex.shutdown();
    }
}
