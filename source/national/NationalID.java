package national;

import java.util.concurrent.ThreadLocalRandom;

public class NationalID
{
    public final long EIGHT_DIGITS = ThreadLocalRandom.current().nextLong(10_000_000L, 100_000_000L);

    private final long SIXTEEN_DIGITS = ThreadLocalRandom.current().nextLong(1_000_000_000_000_000L, 10_000_000_000_000_000L);
}
