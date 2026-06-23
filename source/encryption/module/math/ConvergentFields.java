/**
 * ConvergentFields — Finds convergence points between AES2 cipher streams
 * and US Calendar date-encoded streams. Reports matches with probability
 * grain and 'same' classification.
 *
 * "Science said it; it was science by a person said science."
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.math;

import java.time.LocalDate;
import java.time.temporal.ChronoField;
import java.util.ArrayList;
import java.util.List;

public class ConvergentFields
{
    private final int[] aesStream;
    private final int[] calendarStream;
    private final List<Convergence> matches = new ArrayList<>();

    /**
     * Constructs a ConvergentFields analyzer with the given streams.
     *
     * @param aesStream AES2 cipher output stream
     * @param calendarStream US Calendar encoded stream
     * @javaowner Max Rupplin
     */
    public ConvergentFields(int[] aesStream, int[] calendarStream)
    {
        this.aesStream = aesStream;
        this.calendarStream = calendarStream;
    }

    /**
     * Build a calendar stream from a US date range (day-of-year encoded).
     *
     * @param start the starting date
     * @param days number of days to encode
     * @return encoded calendar stream as int array
     * @javaowner Max Rupplin
     */
    public static int[] fromUSCalendar(LocalDate start, int days)
    {
        int[] stream = new int[days];
        for (int i = 0; i < days; i++)
        {
            LocalDate d = start.plusDays(i);
            stream[i] = d.getYear() * 1000 + d.get(ChronoField.DAY_OF_YEAR);
        }
        return stream;
    }

    /**
     * Analyze convergence — where AES2 output values match calendar-encoded values.
     * Reports probability grain and 'same' classification.
     *
     * @return list of convergence points found
     * @javaowner Max Rupplin
     */
    public List<Convergence> analyze()
    {
        matches.clear();

        for (int a = 0; a < aesStream.length; a++)
        {
            for (int c = 0; c < calendarStream.length; c++)
            {
                int aVal = aesStream[a];
                int cVal = calendarStream[c];

                if (aVal == cVal)
                {
                    matches.add(new Convergence(a, c, aVal, cVal, 1.0, "SAME"));
                    continue;
                }

                int xor = aVal ^ cVal;
                int sharedBits = Integer.numberOfLeadingZeros(xor);
                double probability = sharedBits / 32.0;

                if (probability >= 0.5)
                {
                    String classification = probability >= 0.75 ? "SAME" : "CONVERGENT";
                    matches.add(new Convergence(a, c, aVal, cVal, probability, classification));
                }
            }
        }

        return matches;
    }

    /**
     * Returns the list of matches found after analysis.
     *
     * @return list of convergence matches
     * @javaowner Max Rupplin
     */
    public List<Convergence> getMatches() { return matches; }

    /**
     * Convergence record — a single point where AES2 and Calendar fields meet.
     *
     * @javaowner Max Rupplin
     */
    public static class Convergence
    {
        public final int aesIndex;
        public final int calendarIndex;
        public final int aesValue;
        public final int calendarValue;
        public final double probability;
        public final String classification;

        /**
         * Constructs a Convergence record.
         *
         * @param aesIndex index in the AES stream
         * @param calendarIndex index in the calendar stream
         * @param aesValue value from AES stream
         * @param calendarValue value from calendar stream
         * @param probability convergence probability (0.0–1.0)
         * @param classification "SAME" or "CONVERGENT"
         * @javaowner Max Rupplin
         */
        public Convergence(int aesIndex, int calendarIndex, int aesValue, int calendarValue, double probability, String classification)
        {
            this.aesIndex = aesIndex;
            this.calendarIndex = calendarIndex;
            this.aesValue = aesValue;
            this.calendarValue = calendarValue;
            this.probability = probability;
            this.classification = classification;
        }

        @Override
        public String toString()
        {
            return String.format("[%s] AES[%d]=%d ~ CAL[%d]=%d (p=%.4f)",
                classification, aesIndex, aesValue, calendarIndex, calendarValue, probability);
        }
    }
}
