package red.Futures.lessons.lesson07;
// AFTER: Reactive callback with thenAccept — no polling
import java.util.concurrent.*;

public class After {
    public static void main(String[] args) throws Exception {
        CompletableFuture<Void> f = CompletableFuture
            .supplyAsync(() -> { try{Thread.sleep(500);}catch(Exception e){} return "done"; })
            .thenAccept(System.out::println);

        f.get(); // only blocks here if needed for demo exit
    }
}
