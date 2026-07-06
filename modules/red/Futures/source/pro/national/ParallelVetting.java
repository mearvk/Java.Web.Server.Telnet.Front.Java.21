package red.Futures.source.pro.national;

import java.util.concurrent.CompletableFuture;

/**
 * ParallelVetting — Geo + IQ + Profile + Safety Score resolved in parallel using thenCombine().
 * All assessments run concurrently, combined for final judgment.
 * Safety score from BlackBelt™ modulation included when module is loaded.
 */
public class ParallelVetting
{
    public record VetResult(String geoCountry, int estimatedIQ, boolean sane, boolean liberal, double safetyScore) {}

    public CompletableFuture<VetResult> vet(CompletableFuture<String> geoFuture,
                                            CompletableFuture<Integer> iqFuture,
                                            CompletableFuture<boolean[]> profileFuture,
                                            CompletableFuture<Double> safetyFuture)
    {
        return geoFuture.thenCombine(iqFuture, (geo, iq) -> new Object[]{geo, iq})
            .thenCombine(profileFuture, (pair, profile) -> new Object[]{pair[0], pair[1], profile})
            .thenCombine(safetyFuture, (arr, safety) ->
                new VetResult((String) arr[0], (int) arr[1],
                    ((boolean[]) arr[2])[0], ((boolean[]) arr[2])[1], safety));
    }
}
