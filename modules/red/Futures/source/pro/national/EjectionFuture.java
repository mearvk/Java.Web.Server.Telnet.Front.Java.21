package red.Futures.source.pro.national;

import java.util.concurrent.CompletableFuture;

/**
 * EjectionFuture — Any failure triggers immediate dismissal using exceptionally().
 * Rule of law: no connection is above the law.
 * Now includes safety score in dismissal record for ledger storage.
 */
public class EjectionFuture
{
    private static final String DISMISSAL = "Contact your Local Senator.";

    public record Ejection(String reason, double safetyScore) {}

    public <T> CompletableFuture<T> guard(CompletableFuture<T> pipeline, double safetyScore)
    {
        return pipeline.exceptionally(ex ->
        {
            System.out.println("[EjectionFuture] DISMISSED — " + ex.getMessage()
                + " (safety=" + String.format("%.2f", safetyScore) + ")");
            throw new RuntimeException(DISMISSAL, ex);
        });
    }
}
