package red.Futures.source.examples.example011;
import java.util.concurrent.*;
import java.util.*;

public class FutureWithExecutorPool {
    public static void main(String[] args) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(4);
        List<Future<Integer>> futures = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            final int task = i;
            futures.add(pool.submit(() -> task * task));
        }
        for (Future<Integer> f : futures) {
            System.out.println(f.get());
        }
        pool.shutdown();
    }
}
