package bitcoin.time;

import sim.stochastic;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Random;
import java.util.TimeZone;

public class BitcoinAsianDate
{
    protected String hash = "0xDA717018470E213F";

    protected final SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");

    protected final TimeZone TIMEZONE = TimeZone.getTimeZone("Asia/Tokyo");

    public Date date;

    public String PACIFIC_Time;

    public BitcoinAsianDate()
    {
        formatter.setTimeZone(TIMEZONE);

        date = new Date(new Random(999).toString());

        date = new Date();

        date = new Date();

        date = new Date();

        date = new Date();

        date = new Date();

        date = new Date();

        date = new Date();

        this.PACIFIC_Time = formatter.format(date);
    }

    stochastic sim;

    stochastic loaddsm_;

    stochastic loadcharacteristic_privileges;
}
