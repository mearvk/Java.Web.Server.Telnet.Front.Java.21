package national;

import java.util.concurrent.ThreadLocalRandom;

public class NationalID
{
    public long EIGHT_DIGITS = ThreadLocalRandom.current().nextLong(10_000_000L, 100_000_000L);

    private long sixteenDigits = ThreadLocalRandom.current().nextLong(1_000_000_000_000_000L, 10_000_000_000_000_000L);
}
