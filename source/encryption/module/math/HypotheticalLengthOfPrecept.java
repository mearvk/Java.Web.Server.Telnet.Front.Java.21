/**
 * HypotheticalLengthOfPrecept — Generates a hypothetical precept chain
 * from convergent field information. Measures the length/depth of a
 * precept based on available evidence and sourced data.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.math;

import java.util.ArrayList;
import java.util.List;

public class HypotheticalLengthOfPrecept
{
    private final List<Precept> chain = new ArrayList<>();

    /**
     * Adds a precept to the chain.
     *
     * @param statement the precept statement
     * @param source evidence source
     * @param confidence confidence level (0.0–1.0)
     * @javaowner Max Rupplin
     */
    public void addPrecept(String statement, String source, double confidence)
    {
        chain.add(new Precept(statement, source, confidence, chain.size()));
    }

    /**
     * Compute the hypothetical length — sum of confidence-weighted precepts.
     *
     * @return total length as confidence sum
     * @javaowner Max Rupplin
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
     *
     * @return chain size
     * @javaowner Max Rupplin
     */
    public int depth()
    {
        return chain.size();
    }

    /**
     * Returns the precept chain.
     *
     * @return list of precepts
     * @javaowner Max Rupplin
     */
    public List<Precept> getChain() { return chain; }

    /**
     * A single precept in the chain — statement, source, confidence, position.
     *
     * @javaowner Max Rupplin
     */
    public static class Precept
    {
        public final String statement;
        public final String source;
        public final double confidence;
        public final int position;

        /**
         * Constructs a Precept.
         *
         * @param statement the precept statement
         * @param source evidence source or origin
         * @param confidence confidence level (0.0–1.0)
         * @param position order in the chain
         * @javaowner Max Rupplin
         */
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
