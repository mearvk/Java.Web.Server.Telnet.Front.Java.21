/**
 * HypotheticalLengthOfPrecept — Generates a hypothetical precept chain
 * from convergent field information. Measures the length/depth of a
 * precept based on available evidence and sourced data.
 *
 * @author Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.math;

import java.util.ArrayList;
import java.util.List;

public class HypotheticalLengthOfPrecept
{
    private final List<Precept> chain = new ArrayList<>();

    public void addPrecept(String statement, String source, double confidence)
    {
        chain.add(new Precept(statement, source, confidence, chain.size()));
    }

    /**
     * Compute the hypothetical length — sum of confidence-weighted precepts.
     */
    public double computeLength()
    {
        double length = 0.0;
        for (Precept p : chain)
        {
            length += p.confidence;
        }
        return length;
    }

    /**
     * Depth — number of precepts in the chain.
     */
    public int depth()
    {
        return chain.size();
    }

    public List<Precept> getChain() { return chain; }

    public static class Precept
    {
        public final String statement;
        public final String source;
        public final double confidence;
        public final int position;

        public Precept(String statement, String source, double confidence, int position)
        {
            this.statement = statement;
            this.source = source;
            this.confidence = confidence;
            this.position = position;
        }

        @Override
        public String toString()
        {
            return String.format("[%d] (%.2f) %s — %s", position, confidence, statement, source);
        }
    }
}
