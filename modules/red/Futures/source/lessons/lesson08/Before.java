package red.Futures.source.lessons.lesson08;// BEFORE: Ignoring exception type, generic catch-all
import java.util.concurrent.*;

public class Before {
    public static void main(String[] args) {
        CompletableFuture<String> f = CompletableFuture.supplyAsync(() -> {
            throw new IllegalArgumentException("bad input");
        });
        try {
            System.out.println(f.get());
        } catch (Exception e) {
            System.out.println("Something failed"); // no info about what
        }
    }
}
