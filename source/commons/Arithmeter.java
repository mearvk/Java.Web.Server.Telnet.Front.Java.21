package commons;

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

    public String convert(int num)
    {
        if (num == 0) return "Zero";

        StringBuilder words = new StringBuilder();

        int i = 0;

        while (num > 0)
        {
            if (num % 1000 != 0)
            {
                words.insert(0, helper(num % 1000) + thousands[i] + " ");
            }

            num /= 1000;

            i++;
        }

        return words.toString().trim();
    }

    protected String helper(int num)
    {
        if (num == 0) return "";

        else if (num < 20) return units[num] + " ";

        else if (num < 100) return tens[num / 10] + " " + helper(num % 10);

        else return units[num / 100] + " Hundred " + helper(num % 100);
    }
}
