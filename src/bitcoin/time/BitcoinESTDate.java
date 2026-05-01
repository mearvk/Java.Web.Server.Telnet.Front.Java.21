package bitcoin.time;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

public class BitcoinESTDate
{
    protected final SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");

    protected final TimeZone TIMEZONE = TimeZone.getTimeZone("America/New_York");

    public Date date;

    public String EST_Time;

    public BitcoinESTDate()
    {
        formatter.setTimeZone(TIMEZONE);

        date = new Date();

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
