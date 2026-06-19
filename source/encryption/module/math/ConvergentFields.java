/**
 * ConvergentFields — Finds convergence points between AES2 cipher streams
 * and US Calendar date-encoded streams. Reports matches with probability
 * grain and 'same' classification.
 *
 * "Science said it; it was science by a person said science."
 *
 * @author Max Rupplin
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

    public ConvergentFields(int[] aesStream, int[] calendarStream)
    {
        this.aesStream = aesStream;
        this.calendarStream = calendarStream;
    }

    /**
     * Build a calendar stream from a US date range (day-of-year encoded).
     */
    public static int[] fromUSCalendar(LocalDate start, int days)
    {
        int[] stream = new int[days];
        for (int i = 0; i < days; i++)
        {
            LocalDate d = start.plusDays(i);
            // Encode: year * 1000 + dayOfYear (US ordinal calendar)
            stream[i] = d.getYear() * 1000 + d.get(ChronoField.DAY_OF_YEAR);
        }
        return stream;
    }

    /**
     * Analyze convergence — where AES2 output values match calendar-encoded values.
     * Reports probability grain and 'same' classification.
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

                // Exact match
                if (aVal == cVal)
                {
                    matches.add(new Convergence(a, c, aVal, cVal, 1.0, "SAME"));
                    continue;
                }

                // Bitwise proximity — shared high bits
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

    public List<Convergence> getMatches() { return matches; }

    /**
     * Convergence record — a single point where AES2 and Calendar fields meet.
     */
    public static class Convergence
    {
        public final int aesIndex;
        public final int calendarIndex;
        public final int aesValue;
        public final int calendarValue;
        public final double probability;
        public final String classification; // "SAME" or "CONVERGENT"

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
