package bitcoin.base;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Central validation policy for Bitcoin RPC operations exposed by the server.
 *
 * The policy intentionally permits only the RPC methods used by the application
 * and validates monetary inputs before they reach bitcoin-cli.
 */
public final class BitcoinRpcPolicy
{
    private static final Set<String> ALLOWED_RPC_METHODS = Set.of(
        "stop",
        "loadwallet",
        "unloadwallet",
        "createwallet",
        "getwalletinfo",
        "getbalance",
        "getnewaddress",
        "getblockchaininfo",
        "getblockcount",
        "sendtoaddress"
    );

    private static final Pattern WALLET_NAME = Pattern.compile("[A-Za-z0-9._ -]{1,128}");
    private static final Pattern BITCOIN_ADDRESS = Pattern.compile("(?:[123][1-9A-HJ-NP-Za-km-z]{25,90}|bc1[ac-hj-np-z02-9]{11,87}|tb1[ac-hj-np-z02-9]{11,87}|bcrt1[ac-hj-np-z02-9]{11,87})");

    private BitcoinRpcPolicy() {}

    public static boolean isAllowed(final String method)
    {
        return method != null && ALLOWED_RPC_METHODS.contains(method);
    }

    public static void requireAllowed(final String method)
    {
        if (!isAllowed(method))
            throw new IllegalArgumentException("Bitcoin RPC method is not permitted: " + method);
    }

    public static String requireWalletName(final String name)
    {
        if (name == null || !WALLET_NAME.matcher(name).matches())
            throw new IllegalArgumentException("Invalid Bitcoin wallet name");
        return name;
    }

    public static String requireAddress(final String address)
    {
        if (address == null || !BITCOIN_ADDRESS.matcher(address).matches())
            throw new IllegalArgumentException("Invalid Bitcoin address format");
        return address;
    }

    /** Parse BTC without floating-point conversion and convert exactly to satoshis. */
    public static long requireSatoshis(final String amount)
    {
        if (amount == null || amount.isBlank())
            throw new IllegalArgumentException("BTC amount is required");

        final BigDecimal value;
        try
        {
            value = new BigDecimal(amount.trim());
        }
        catch (NumberFormatException e)
        {
            throw new IllegalArgumentException("Invalid BTC amount", e);
        }

        if (value.signum() <= 0 || value.scale() > 8)
            throw new IllegalArgumentException("BTC amount must be positive and use at most 8 decimal places");

        final BigDecimal satoshis = value.movePointRight(8).setScale(0, RoundingMode.UNNECESSARY);
        if (satoshis.compareTo(BigDecimal.valueOf(Long.MAX_VALUE)) > 0)
            throw new IllegalArgumentException("BTC amount is too large");
        return satoshis.longValueExact();
    }
}
