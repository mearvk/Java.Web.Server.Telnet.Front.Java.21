package red.Futures.democratic.d500;
// Democratic Principle: Free Speech — all voices processed without suppression
import java.util.concurrent.*;
import java.util.stream.*;
import java.util.*;

public class FreeSpeech {
    public static void main(String[] args) {
        List<String> opinions = List.of("I agree", "I disagree", "I abstain", "I protest", "I support");
        List<CompletableFuture<String>> voices = opinions.stream()
            .map(opinion -> CompletableFuture.supplyAsync(() -> "Heard: " + opinion))
            .collect(Collectors.toList());

        CompletableFuture.allOf(voices.toArray(new CompletableFuture[0])).join();
        voices.forEach(v -> System.out.println(v.join())); // none filtered
    }
}
