package red.Futures.democratic.d500;
// Democratic Principle: Accountability — handle() ensures every failure is reported
import java.util.concurrent.*;

public class Accountability {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> action = CompletableFuture
            .<String>supplyAsync(() -> { throw new RuntimeException("Abuse of power"); })
            .handle((result, ex) -> {
                if (ex != null) return "ACCOUNTABILITY: " + ex.getCause().getMessage() + " — investigated";
                return result;
            });
        System.out.println(action.get());
    }
}
