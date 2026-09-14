package red.Futures.source.lessons.lesson05;// AFTER: Each transformation is a named step in the pipeline
import java.util.concurrent.*;

public class After {
    static String trim(String s) { return s.trim(); }
    static String capitalize(String s) { return s.substring(0, 1).toUpperCase() + s.substring(1); }
    static String exclaim(String s) { return s + "!"; }

    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future = CompletableFuture
            .supplyAsync(() -> "  hello world  ")
            .thenApply(After::trim)
            .thenApply(After::capitalize)
            .thenApply(After::exclaim);

        System.out.println(future.get());
    }
}
