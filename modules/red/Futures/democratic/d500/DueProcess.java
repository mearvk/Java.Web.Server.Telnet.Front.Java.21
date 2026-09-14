package red.Futures.democratic.d500;
// Democratic Principle: Due Process — orderly pipeline, each stage completes before next
import java.util.concurrent.*;

public class DueProcess {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> process = CompletableFuture
            .supplyAsync(() -> "Accusation filed")
            .thenApply(s -> s + " -> Evidence gathered")
            .thenApply(s -> s + " -> Trial held")
            .thenApply(s -> s + " -> Verdict rendered");
        System.out.println(process.get());
    }
}
