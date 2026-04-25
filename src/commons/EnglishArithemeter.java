package commons;

/**
 * @author Max Rupplin
 *
 * @date April 24 2026
 */

import java.text.DecimalFormat;
import java.util.ArrayList;

public class EnglishArithemeter
{
    private static final String[] tens = {"", " ten", " twenty", " thirty", " forty", " fifty", " sixty", " seventy", " eighty", " ninety"};

    private static final String[] units = {"", " one", " two", " three", " four", " five", " six", " seven", " eight", " nine", " ten", " eleven", " twelve", " thirteen", " fourteen", " fifteen", " sixteen", " seventeen", " eighteen", " nineteen"};

    public EnglishArithemeter()
    {

    }

    public static String coulumbsOfNumbers(int number)
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

        if (number == 0) return convert;

        return units[number] + " hundred" + convert;
    }

    public static <T> Integer size(ArrayList<T> list)
    {
        return list.size();
    }

    public static String convert(long number)
    {
        if (number == 0)
        {
            return "zero";
        }

        String snumber = Long.toString(number);

        String mask = "000000000000";

        DecimalFormat df = new DecimalFormat(mask);

        snumber = df.format(number);

        int billions = Integer.parseInt(snumber.substring(0, 3));

        int millions = Integer.parseInt(snumber.substring(3, 6));

        int hundredThousands = Integer.parseInt(snumber.substring(6, 9));

        int thousands = Integer.parseInt(snumber.substring(9, 12));

        String tradBillions;

        switch (billions)
        {
            case 0:
                tradBillions = "";

                break;

            case 1:
                tradBillions = coulumbsOfNumbers(billions)  + " billion ";

                break;

            default:
                tradBillions = coulumbsOfNumbers(billions)  + " billion ";
        }

        String result =  tradBillions;

        String tradMillions;

        switch (millions)
        {
            case 0:
                tradMillions = "";

                break;

            case 1 :
                tradMillions = coulumbsOfNumbers(millions)  + " million ";

                break;

            default :
                tradMillions = coulumbsOfNumbers(millions)  + " million ";
        }

        result =  result + tradMillions;

        String tradHundredThousands;

        switch (hundredThousands)
        {
            case 0:
                tradHundredThousands = "";

                break;

            case 1 :
                tradHundredThousands = "one thousand ";

                break;

            default :
                tradHundredThousands = coulumbsOfNumbers(hundredThousands) + " thousand ";
        }

        result =  result + tradHundredThousands;

        String tradThousand;

        tradThousand = coulumbsOfNumbers(thousands);

        result =  result + tradThousand;

        return result.replaceAll("^\\s+", "").replaceAll("\\b\\s{2,}\\b", " ");
    }
}

