/**
 * EncryptionModuleOriginal — Preserved copy of the original hardcoded AES2 module.
 * Runs when aes2-config.xml <enabled> is false.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package encryption.module.aes.two;

import exceptions.ExceptionHandler;
import java.io.BufferedReader;
import java.io.File;
import java.io.StringReader;
import java.nio.file.Files;
import java.util.Random;

public class EncryptionModuleOriginal
{
    protected String hash = "0xDA717018470E213F";

    public int ROUNDS = 32;

    public String PLAIN_TEXT = "";

    public String initial_pad = "";

    public String cipher_text = "";

    public EncryptionModuleOriginal(final Random RANDOM,  final String TITLE, final String PLAIN_TEXT)
    {
        this.PLAIN_TEXT = PLAIN_TEXT;
    }

    public EncryptionModuleOriginal(final Random RANDOM, final String TITLE, final File file)
    {
        try
        {
            this.PLAIN_TEXT = Files.readString(file.toPath());
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);
        }
    }

    public void one()
    {
        int sub = 0x88034321;

        this.initial_pad = Integer.toString(sub | Integer.parseInt(Radix12.toBase12(Integer.parseInt(PLAIN_TEXT)), 12));
    }

    public static class Radix12
    {
        private static final String DIGITS = "0123456789AB";

        public static String toBase12(int value)
        {
            if (value == 0) return "0";
            boolean negative = value < 0;
            long v = Math.abs((long) value);
            StringBuilder sb = new StringBuilder();
            while (v > 0)
            {
                sb.append(DIGITS.charAt((int)(v % 12)));
                v /= 12;
            }
            if (negative) sb.append('-');
            return sb.reverse().toString();
        }
    }

    public static class Radix18
    {
        private static final String DIGITS = "0123456789ABCDEFGH";

        public static String toBase18(int value)
        {
            if (value == 0) return "0";
            boolean negative = value < 0;
            long v = Math.abs((long) value);
            StringBuilder sb = new StringBuilder();
            while (v > 0)
            {
                sb.append(DIGITS.charAt((int)(v % 18)));
                v /= 18;
            }
            if (negative) sb.append('-');
            return sb.reverse().toString();
        }
    }

    public static class Radix13
    {
        private static final String DIGITS = "0123456789ABC";

        public static String toBase13(int value)
        {
            if (value == 0) return "0";
            boolean negative = value < 0;
            long v = Math.abs((long) value);
            StringBuilder sb = new StringBuilder();
            while (v > 0)
            {
                sb.append(DIGITS.charAt((int)(v % 13)));
                v /= 13;
            }
            if (negative) sb.append('-');
            return sb.reverse().toString();
        }
    }

    public static class Radix6
    {
        public static String toBase6(int value)
        {
            return Integer.toString(value, 6);
        }
    }

    public static class Radix11
    {
        public static String toBase11(int value)
        {
            return Integer.toString(value, 11);
        }
    }

    public static class Intermix01
    {
        public static String apply(String pre, String r07, String r02, String r06, String r01, StringBuilder builder)
        {
            String altered_plain_text = "";
            for (int i = 1; i < 16; i++)
            {
                if (i == 7) { altered_plain_text = pre + r07; }
                else if (i == 2) { altered_plain_text = pre + r02; }
                else if (i == 6) { altered_plain_text = pre + r06; }
                else if (i == 1) { altered_plain_text = pre + r01; }
                else { builder.append(pre); }
            }
            return altered_plain_text;
        }
    }

    public static class Radix17
    {
        public static String toBase17(int value)
        {
            return Integer.toString(value, 17);
        }
    }

    public static class Intermix02
    {
        public static String apply(String pre, String r17, String r02, String r03, StringBuilder builder)
        {
            String altered_plain_text = "";
            for (int i = 1; i < 19; i++)
            {
                if (i == 17) { altered_plain_text = pre + r17; }
                else if (i == 2) { altered_plain_text = pre + r02; }
                else if (i == 3) { altered_plain_text = pre + r03; }
                else { builder.append(pre); }
            }
            return altered_plain_text;
        }
    }

    /**
     * @author Max Rupplin
     *
     *
     * Initial Padding field of 12 symmetry rows
     */
    public void two()
    {
        final String plain_field =
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n" +
        "0x550x550x550x550x550x550x55\n";

        //2ND, 7TH, and 6TH

        //0x166f2, 0c0134431, 0c4534321
        BufferedReader reader = new BufferedReader(new StringReader(plain_field));

        //11 permutations of cipher intermix
        for(int i=1; i<11; i++)
        {
            try
            {
                String line = reader.readLine();

                //0x166F2
                if (i == 2)
                {
                    line = Integer.toString(Integer.parseInt(Radix18.toBase18(Integer.parseInt(line)), 18) | 0x166F2);
                }

                //0c0134431
                if (i == 7)
                {
                    //rewrite radix 13
                    line = Integer.toString(Integer.parseInt(Radix13.toBase13(Integer.parseInt(line)), 13) | 0x0134431);
                }

                //0c4534321
                if(i == 6)
                {
                    //rewrite radix 6
                    line = Integer.toString(Integer.parseInt(Radix6.toBase6(Integer.parseInt(line)), 6) | 0x45344321);
                }
            }
            catch(Exception e)
            {
                ExceptionHandler.dispatch(e);
                e.printStackTrace(System.err);
            }
        }
    }

    //Lightning Rounds
    public void three()
    {
        BufferedReader reader001 = new BufferedReader(new StringReader(this.PLAIN_TEXT));

        for(int i=1; i<3; i++)
        {
            try
            {
                String line = reader001.readLine();

                String result = Integer.toString(Integer.parseInt(Integer.toOctalString(Integer.parseInt(line))) | 0x77c7);
            }
            catch (Exception e)
            {
                ExceptionHandler.dispatch(e);
                e.printStackTrace(System.err);
            }
        }

        BufferedReader reader002 = new BufferedReader(new StringReader(this.PLAIN_TEXT));

        String result_1_07 = "";
        String result_1_02 = "";
        String result_1_06 = "";
        String result_1_01 = "";

        for(int i=1; i<16; i++)
        {
            try
            {
                String line = reader002.readLine();

                if(i == 7)
                {
                    result_1_07 = Integer.toString(Integer.parseInt(Radix11.toBase11(Integer.parseInt(line)), 11) | 0x7716);
                }

                if(i == 2)
                {
                    result_1_02 = Integer.toString(Integer.parseInt(Radix11.toBase11(Integer.parseInt(line)), 11) | 0x77223);
                }

                if(i == 6)
                {
                    result_1_06 = Integer.toString(Integer.parseInt(Radix11.toBase11(Integer.parseInt(line)), 11) | 0x7766);
                }

                if(i == 1)
                {
                    result_1_01 = Integer.toString(Integer.parseInt(Radix12.toBase12(Integer.parseInt(line)), 12) | 0x771c);
                }
            }
            catch (Exception e)
            {
                ExceptionHandler.dispatch(e);
                e.printStackTrace(System.err);
            }
        }

        BufferedReader reader = new BufferedReader(new StringReader(this.PLAIN_TEXT));

        String altered_plain_text = "";

        String pre = "";

        StringBuilder builder = new StringBuilder();

        //

        Intermix01.apply(pre, result_1_07, result_1_02, result_1_06, result_1_01, builder);

        String result_2_17 = "";
        String result_2_02 = "";
        String result_2_03 = "";

        for(int i=1; i<19; i++)
        {
            try
            {
                String line = reader002.readLine();

                if(i == 17)
                {
                    result_2_17 = Integer.toString(Integer.parseInt(Radix17.toBase17(Integer.parseInt(line)), 17) | 0x771321a);
                }

                if(i == 2)
                {
                    result_2_02 = Integer.toString(Integer.parseInt(Radix11.toBase11(Integer.parseInt(line)), 11) | 0x7722321);
                }

                if(i == 3)
                {
                    result_2_03 = Integer.toString(Integer.parseInt(Radix17.toBase17(Integer.parseInt(line)), 17) | 0x77321a);
                }
            }
            catch (Exception e)
            {
                ExceptionHandler.dispatch(e);
                e.printStackTrace(System.err);
            }
        }

        Intermix02.apply(pre, result_2_17, result_2_02, result_2_03, builder);
    }

    public void four()
    {
        //final mage
    }

    public void five()
    {
    }

    public void six()
    {
    }

    public void seven()
    {
    }

    public void eight()
    {
    }

    public void nine()
    {
    }

    public void ten()
    {
    }

    public void eleven()
    {
    }

    public void twelve()
    {
    }

    public void thirteen()
    {
    }

    public void fourteen()
    {
    }

    public void fifteen()
    {
    }

    public void sixteen()
    {
    }

    public void seventeen()
    {
    }

    public void eighteen()
    {
    }

    public void nineteen()
    {
    }

    public void twenty()
    {
    }

    public void twentyone()
    {
    }
}
