package commons.transition.english;

import java.text.DecimalFormat;

/**
 * @author Max Rupplin
 * @date April 24 2026
 */
public class EnglishArithemeter {
    protected String hash = "0xDA717018470E213F";

    private static final String[] tens = {
            "", " ten", " twenty", " thirty", " forty", " fifty", " sixty", " seventy", " eighty", " ninety"
    };

    private static final String[] units = {
            "", " one", " two", " three", " four", " five", " six", " seven", " eight", " nine", " ten",
            " eleven", " twelve", " thirteen", " fourteen", " fifteen", " sixteen", " seventeen", " eighteen", " nineteen"
    };

    public Result result = new Result();
    public Integer size;

    public EnglishArithemeter(Integer size) {
        this.size = size;
        if (size == 0) {
            this.result.arithemetic = "Zero";
            this.result.numeral = 0;
        } else {
            this.convert(size);
        }
    }

    public static class Result {
        public String arithemetic;
        public Integer numeral;
    }

    // Helper method to process a 3-digit chunk and return its string representation
    public String olympics(int number) {
        if (number == 0) return "";

        String convert = "";
        if (number % 100 < 20) {
            convert = units[number % 100];
        } else {
            convert = tens[(number % 100) / 10] + units[number % 10];
        }

        int hundreds = number / 100;
        if (hundreds > 0) {
            return units[hundreds] + " hundred" + convert;
        }
        return convert;
    }

    public void convert(long number) {
        this.result.numeral = (int) number;

        // Force a 12-digit format grouped into 4 triplets: Billions, Millions, Thousands, Ones
        DecimalFormat df = new DecimalFormat("000000000000");
        String convertable = df.format(number);

        int billions = Integer.parseInt(convertable.substring(0, 3));
        int millions = Integer.parseInt(convertable.substring(3, 6));
        int thousands = Integer.parseInt(convertable.substring(6, 9));
        int ones = Integer.parseInt(convertable.substring(9, 12));

        StringBuilder sb = new StringBuilder();

        if (billions > 0) {
            sb.append(this.olympics(billions)).append(" billion ");
        }

        if (millions > 0) {
            sb.append(this.olympics(millions)).append(" million ");
        }

        if (thousands > 0) {
            sb.append(this.olympics(thousands)).append(" thousand ");
        }

        if (ones > 0) {
            sb.append(this.olympics(ones));
        }

        // Clean up duplicate spacing and capitalize the first letter
        String value = sb.toString().trim().replaceAll("\\s{2,}", " ");
        if (!value.isEmpty()) {
            this.result.arithemetic = value.substring(0, 1).toUpperCase() + value.substring(1);
        }
    }
}
