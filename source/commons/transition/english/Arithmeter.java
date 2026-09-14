/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package commons.transition.english;

public class Arithmeter
{
    private final String[] units =
    {
        "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
        "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
    };

    private final String[] tens =
    {
        "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    };

    private final String[] thousands = { "", "Thousand", "Million", "Billion" };

    public String convert(int NUM)
    {
        if (NUM == 0) return "Zero";

        StringBuilder words = new StringBuilder();

        int i = 0;

        while (NUM > 0)
        {
            if (NUM % 1000 != 0)
            {
                words.insert(0, helper(NUM % 1000) + thousands[i] + " ");
            }

            NUM /= 1000;

            i++;
        }

        return words.toString().trim();
    }

    protected String helper(final int NUM)
    {
        if (NUM == 0) return "";

        else if (NUM < 20) return units[NUM] + " ";

        else if (NUM < 100) return tens[NUM / 10] + " " + helper(NUM % 10);

        else return units[NUM / 100] + " Hundred " + helper(NUM % 100);
    }
}
