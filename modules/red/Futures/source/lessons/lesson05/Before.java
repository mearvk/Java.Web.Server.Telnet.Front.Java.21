package red.Futures.source.lessons.lesson05;// BEFORE: Inline lambda with complex logic — unreadable
import java.util.concurrent.*;

public class Before {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
            String raw = "  hello world  ";
            raw = raw.trim();
            raw = raw.substring(0, 1).toUpperCase() + raw.substring(1);
            raw = raw + "!";
            return raw;
        });
        System.out.println(future.get());
    }
}
