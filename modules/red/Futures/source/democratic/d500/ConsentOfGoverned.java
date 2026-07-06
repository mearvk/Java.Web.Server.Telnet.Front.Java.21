package red.Futures.source.democratic.d500;
// Democratic Principle: Consent of the Governed — anyOf = the people decide direction
import java.util.concurrent.*;

public class ConsentOfGoverned {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> candidateA = CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(200); } catch (Exception e) {}
            return "Candidate A elected";
        });
        CompletableFuture<String> candidateB = CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(500); } catch (Exception e) {}
            return "Candidate B elected";
        });
        // The people's choice emerges first
        Object result = CompletableFuture.anyOf(candidateA, candidateB).get();
        System.out.println("The people chose: " + result);
    }
}
