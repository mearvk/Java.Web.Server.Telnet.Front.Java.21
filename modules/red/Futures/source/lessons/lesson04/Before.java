package red.Futures.source.lessons.lesson04;// BEFORE: Manual loop collecting results, no structure
import java.util.concurrent.*;
import java.util.*;

public class Before {
    public static void main(String[] args) throws Exception {
        ExecutorService ex = Executors.newFixedThreadPool(5);
        List<Future<String>> futures = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            int id = i;
            futures.add(ex.submit(() -> "Result " + id));
        }
        List<String> results = new ArrayList<>();
        for (Future<String> f : futures) {
            results.add(f.get()); // blocking one at a time
        }
        System.out.println(results);
        ex.shutdown();
    }
}
