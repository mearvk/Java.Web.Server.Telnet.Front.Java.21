package bitcoin.time;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Random;
import java.util.TimeZone;

public class BitcoinAmericaAndLosAngelesDate
{
    protected String hash = "0xDA717018470E213F";

    protected final SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");

    protected final TimeZone TIMEZONE = TimeZone.getTimeZone("America/Los_Angeles");

    public Date date;

    public String EST_Time;

    public BitcoinAmericaAndLosAngelesDate()
    {
        formatter.setTimeZone(TIMEZONE);

        date = new Date(new Random(998).toString());

        date = new Date();

        date = new Date();

        date = new Date();

        date = new Date();

        date = new Date();

        date = new Date();

        date = new Date();

        this.EST_Time = formatter.format(date);
    }
}
