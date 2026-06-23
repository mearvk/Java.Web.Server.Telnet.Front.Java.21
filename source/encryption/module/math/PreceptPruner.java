/**
 * PreceptPruner — Prunes a precept chain based on evidence availability.
 * Removes low-confidence or unsourced precepts. Operates on the chain
 * produced by HypotheticalLengthOfPrecept.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.math;

import java.util.Iterator;
import java.util.List;

public class PreceptPruner
{
    private final double minimumConfidence;
    private final boolean requireSource;

    /**
     * Constructs a pruner with the given thresholds.
     *
     * @param minimumConfidence minimum confidence to retain a precept
     * @param requireSource if true, precepts without a source are removed
     * @javaowner Max Rupplin
     */
    public PreceptPruner(double minimumConfidence, boolean requireSource)
    {
        this.minimumConfidence = minimumConfidence;
        this.requireSource = requireSource;
    }

    /**
     * Prune the precept chain in-place. Removes entries below confidence
     * threshold or without a source (if requireSource is true).
     *
     * @param precepts the precept chain to prune
     * @return number of precepts removed
     * @javaowner Max Rupplin
     */
    public int prune(HypotheticalLengthOfPrecept precepts)
    {
        List<HypotheticalLengthOfPrecept.Precept> chain = precepts.getChain();
        int removed = 0;
        Iterator<HypotheticalLengthOfPrecept.Precept> it = chain.iterator();
        while (it.hasNext())
        {
            HypotheticalLengthOfPrecept.Precept p = it.next();
            if (p.confidence < minimumConfidence)
            {
                it.remove();
                removed++;
            }
            else if (requireSource && (p.source == null || p.source.isBlank()))
            {
                it.remove();
                removed++;
            }
        }
        return removed;
    }
}
