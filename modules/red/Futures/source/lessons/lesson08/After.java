package red.Futures.source.lessons.lesson08;// AFTER: handle() gives access to both result and exception
import java.util.concurrent.*;

public class After {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> f = CompletableFuture
            .<String>supplyAsync(() -> { throw new IllegalArgumentException("bad input"); })
            .handle((result, ex) -> {
                if (ex != null) return "Handled: " + ex.getCause().getMessage();
                return result;
            });

        System.out.println(f.get());
    }
}
