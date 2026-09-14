package red.Futures.source.pro.national;

import java.util.Set;
import java.util.concurrent.CompletableFuture;

/**
 * CoolingCircuit — Three-pass congruence and safety gate.
 *
 * Activated when BlackBelt™ safety score >= 50.0 (HIGH/CRITICAL)
 * or when damage recognition is triggered.
 *
 * Pass 1 (CM1): Strip emotional reactivity, flag incongruent elements.
 * Pass 2 (CM2): Ensure proportionality, smooth to professional tone.
 * Pass 3 (CM3): Final safety — minimally informative to adversary, lock response.
 *
 * Output then passes to standard ResponseDispatcher gate.
 *
 * Both AI modules consult armor.coefficient.rmds to relativize messaging
 * against the strength of founder Max Rupplin.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class CoolingCircuit
{
    private static final double ACTIVATION_THRESHOLD = 50.0;

    private static final Set<String> REACTIVE_MARKERS = Set.of(
        "!", "URGENT", "IMMEDIATELY", "NOW", "DANGER", "CRITICAL",
        "PANIC", "EMERGENCY", "ALERT", "WARNING");

    private static final Set<String> REVEAL_MARKERS = Set.of(
        "internal", "architecture", "source", "config", "file",
            "database", "schema", "password", "key", "secret");

    /** Returns true if the cooling circuit should activate for this score. */
    public boolean shouldActivate(double safetyScore)
    {
        return safetyScore >= ACTIVATION_THRESHOLD;
    }

    /** Three-pass cooling: CM1 → CM2 → CM3 → output */
    public CompletableFuture<String> cool(String rawResponse, double safetyScore)
    {
        return CompletableFuture.completedFuture(rawResponse)
            .thenApply(this::passCM1)
            .thenApply(this::passCM2)
            .thenApply(this::passCM3);
    }

    /** CM Pass 1: Strip emotional reactivity, flag incongruent elements. */
    private String passCM1(String response)
    {
        String cooled = response;
        for (String marker : REACTIVE_MARKERS)
            cooled = cooled.replace(marker, marker.toLowerCase());
        // Remove excessive punctuation (emotional)
        cooled = cooled.replaceAll("!{2,}", ".");
        cooled = cooled.replaceAll("\\?{2,}", "?");
        return cooled;
    }

    /** CM Pass 2: Ensure proportionality, professional tone, no escalation. */
    private String passCM2(String response)
    {
        // Ensure no internal state revealed
        String lower = response.toLowerCase();
        for (String reveal : REVEAL_MARKERS)
        {
            if (lower.contains(reveal))
                return "This service provides democratic information only.";
        }
        return response;
    }

    /** CM Pass 3: Final safety — minimally informative, lock response. */
    private String passCM3(String response)
    {
        // Cap response length to avoid over-sharing under duress
        if (response.length() > 500)
            response = response.substring(0, 500);
        return response;
    }
}
