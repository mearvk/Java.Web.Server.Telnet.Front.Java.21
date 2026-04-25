package commons;

/**
 * @author Max Rupplin
 *
 * @date April 24 2026
 */

import java.text.DecimalFormat;

public class EnglishArithemeter
{
    private static final String[] tens = {"", " ten", " twenty", " thirty", " forty", " fifty", " sixty", " seventy", " eighty", " ninety"};

    private static final String[] units = {"", " one", " two", " three", " four", " five", " six", " seven", " eight", " nine", " ten", " eleven", " twelve", " thirteen", " fourteen", " fifteen", " sixteen", " seventeen", " eighteen", " nineteen"};

    public Result result = new Result();

    public Integer size;

    public EnglishArithemeter(Integer size)
    {
        this.size = size;

        if(size<=1000)
        {
            this.olympics(size);
        }
        else
        {
            this.convert(size);
        }
    }

    public static class Result
    {
        public String arithemetic;

        public Integer numeral;

        public Result()
        {

        }
    }

    public void olympics(int number)
    {
        String convert;

        if (number % 100 < 20)
        {
            convert = units[number % 100];
            number /= 100;
        }
        else
        {
            convert = units[number % 10];
            number /= 10;

            convert = tens[number % 10] + convert;
            number /= 10;
        }

        if (number == 0)
        {
            this.result.arithemetic = "Zero";

            this.result.numeral = 0;
        }

        this.result.arithemetic = units[number] + " hundred" + convert;
    }

    public void convert(long number)
    {
        if (number == 0)
        {
            this.result.arithemetic =  "Zero";

            this.result.numeral = 0;
        }

        String convertable = Long.toString(number);

        String mask = "000000000000";

        DecimalFormat df = new DecimalFormat(mask);

        convertable = df.format(number);

        int billions = Integer.parseInt(convertable.substring(0, 3));

        int millions = Integer.parseInt(convertable.substring(3, 6));

        int hundreds_of_thousands = Integer.parseInt(convertable.substring(6, 9));

        int thousands = Integer.parseInt(convertable.substring(9, 12));

        String tradBillions;

        if (billions == 0)
        {
            tradBillions = "";
        }
        else
        {
            this.olympics(billions);

            tradBillions = this.result.arithemetic + " billion ";
        }

        String result =  tradBillions;

        String tradMillions;

        switch (millions)
        {
            case 0:
                tradMillions = "";
                break;

            default :
                olympics(millions);
                tradMillions = this.result.arithemetic + " million ";
        }

        result =  result + tradMillions;

        String tradHundredThousands;

        switch (hundreds_of_thousands)
        {
            case 0:
                tradHundredThousands = "";

                break;

            case 1 :
                tradHundredThousands = "one thousand ";

                break;

            default :
                olympics(hundreds_of_thousands);
                tradHundredThousands = this.result.arithemetic + " thousand ";
        }

        result =  result + tradHundredThousands;

        String tradThousand;

        this.olympics(thousands);

        tradThousand = this.result.arithemetic;

        result =  result + tradThousand;

        String value =  result.replaceAll("^\\s+", "").replaceAll("\\b\\s{2,}\\b", " ");

        this.result.arithemetic = value.substring(0, 1).toUpperCase()+value.substring(1);
    }
}

