package red.Futures.source.pro.national;

import java.util.concurrent.CompletableFuture;

/**
 * ConsentGate — All checks must pass before agreement is entered, using allOf().
 * Sane, liberal, non-hostile — all three must resolve true.
 */
public class ConsentGate
{
    public CompletableFuture<Boolean> gate(CompletableFuture<Boolean> sane,
                                           CompletableFuture<Boolean> liberal,
                                           CompletableFuture<Boolean> nonHostile)
    {
        return CompletableFuture.allOf(sane, liberal, nonHostile)
            .thenApply(v -> sane.join() && liberal.join() && nonHostile.join());
    }
}
