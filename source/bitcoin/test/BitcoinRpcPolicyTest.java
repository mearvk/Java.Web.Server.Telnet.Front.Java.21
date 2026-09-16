package bitcoin.test;

import bitcoin.base.BitcoinRpcPolicy;

/** Deterministic, dependency-free regression checks for Bitcoin input policy. */
public final class BitcoinRpcPolicyTest
{
    public static void main(final String[] args)
    {
        assertEquals(100000000L, BitcoinRpcPolicy.requireSatoshis("1"));
        assertEquals(1L, BitcoinRpcPolicy.requireSatoshis("0.00000001"));
        assertEquals(123456789L, BitcoinRpcPolicy.requireSatoshis("1.23456789"));
        assertRejected("0");
        assertRejected("-1");
        assertRejected("0.000000001");
        assertRejected("not-a-number");
        assertRejected("92233720368");
        if (!BitcoinRpcPolicy.isAllowed("getbalance")) throw new AssertionError("getbalance must be allowed");
        if (BitcoinRpcPolicy.isAllowed("importprivkey")) throw new AssertionError("importprivkey must remain outside the server RPC surface");
        BitcoinRpcPolicy.requireAddress("bcrt1qexampleaddressmuststillfail");
    }

    private static void assertRejected(final String value)
    {
        try
        {
            BitcoinRpcPolicy.requireSatoshis(value);
            throw new AssertionError("Expected rejection: " + value);
        }
        catch (IllegalArgumentException expected) { }
    }

    private static void assertEquals(final long expected, final long actual)
    {
        if (expected != actual) throw new AssertionError("Expected " + expected + " but got " + actual);
    }
}
