package bitcoin.base;

import bitcoin.messaging.MessageOrderer;
import bitcoin.time.BitcoinAmericaAndNewYorkDate;
import bitcoin.time.BitcoinAsiaAndTokyoDate;
import commons.CommonRails;
import exceptions.ExceptionHandler;
import server.nitro.NitroWebExpress;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.stream.Collectors;

/**
 * BitcoinBase — wraps a local bitcoind instance.
 *
 * RPC config mirrors /bitcoin/bash/btc24-query.sh:
 *   port     2222
 *   user     root
 *   password 5n5SgKPNPvO0WGr5XcKETuJYydwkXPkdtjNFjJ8bc7s=
 *   network  regtest
 *   wallet   "United States"
 *
 * All mutating operations (start, stop, load/unload wallet, send) persist a
 * trade/action record to the MySQL N21 instance via db.N21Store.storeBitcoinTrade().
 *
 * @author Max Rupplin
 * @date June 08 2026
 */
public class BitcoinBase
{
    protected String hash = "0xDA717018470E213F";

    protected NitroWebExpress.Aspect ASPECT;

    // ── RPC constants (from btc24-query.sh) ──────────────────────────────────
    protected static final String BITCOIN_CLI      = "bitcoin-cli";
    protected static final String BITCOIND         = "bitcoind";
    protected static final String RPC_PORT         = "2222";
    protected static final String RPC_USER         = "root";
    protected static final String RPC_PASSWORD     = "5n5SgKPNPvO0WGr5XcKETuJYydwkXPkdtjNFjJ8bc7s=";
    protected static final String NETWORK          = "-regtest";
    protected static final String WALLET_NAME      = "United States";

    // ── Shared RPC flag array (prepended to every bitcoin-cli call) ───────────
    private static final String[] RPC_FLAGS = {
        NETWORK,
        "-rpcport="    + RPC_PORT,
        "-rpcuser="    + RPC_USER,
        "-rpcpassword="+ RPC_PASSWORD
    };

    protected MessageOrderer bitcoin_message_orderer = new MessageOrderer(this);

    public BitcoinBase(final NitroWebExpress.Aspect ASPECT)
    {
        this.ASPECT = ASPECT;

        BitcoinAsiaAndTokyoDate    JAPANDate = new BitcoinAsiaAndTokyoDate();
        BitcoinAmericaAndNewYorkDate ESTDate  = new BitcoinAmericaAndNewYorkDate();

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". WebExpress Bitcoin >> opens in North Carolina on Date " + ESTDate.EST_Time + " . ");
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". WebExpress Bitcoin >> opens in Japan on Date " + JAPANDate.PACIFIC_Time + " . ");

        db.N21Store.createBitcoinTradesTable();
    }

    // ── Daemon lifecycle ──────────────────────────────────────────────────────

    /** Start local bitcoind in regtest+daemon mode. */
    public String start_bitcoind()
    {
        String result = exec(new String[]{ BITCOIND, NETWORK, "-daemon",
            "-rpcport="    + RPC_PORT,
            "-rpcuser="    + RPC_USER,
            "-rpcpassword="+ RPC_PASSWORD });
        db.N21Store.storeBitcoinTrade("start_bitcoind", "", "", result);
        return result;
    }

    /** Stop local bitcoind via RPC stop. */
    public String stop_bitcoind()
    {
        String result = cli("stop");
        db.N21Store.storeBitcoinTrade("stop_bitcoind", "", "", result);
        return result;
    }

    // ── Wallet management ─────────────────────────────────────────────────────

    public String load_wallet()
    {
        String result = cli("loadwallet", WALLET_NAME);
        db.N21Store.storeBitcoinTrade("load_wallet", WALLET_NAME, "", result);
        return result;
    }

    public String unload_wallet()
    {
        String result = cli("unloadwallet", WALLET_NAME);
        db.N21Store.storeBitcoinTrade("unload_wallet", WALLET_NAME, "", result);
        return result;
    }

    public String create_wallet(final String name)
    {
        String result = cli("createwallet", name);
        db.N21Store.storeBitcoinTrade("create_wallet", name, "", result);
        return result;
    }

    /** Returns raw JSON from getwalletinfo for the default wallet. */
    public String get_wallet_info()
    {
        return walletCli("getwalletinfo");
    }

    /** Returns raw balance string for the default wallet. */
    public String get_balance()
    {
        return walletCli("getbalance");
    }

    /** Returns a new address for the default wallet. */
    public String get_new_address()
    {
        return walletCli("getnewaddress");
    }

    // ── Node status ───────────────────────────────────────────────────────────

    public String get_blockchain_info()
    {
        return cli("getblockchaininfo");
    }

    public String get_block_count()
    {
        return cli("getblockcount");
    }

    // ── Trade / send ──────────────────────────────────────────────────────────

    /**
     * Send BTC from the default wallet to a destination address.
     * Records the trade to MySQL regardless of outcome.
     *
     * @param toAddress  destination Bitcoin address
     * @param amount     amount in BTC (e.g. "0.001")
     * @return txid on success, error string on failure
     */
    public String send(final String toAddress, final String amount)
    {
        String result = walletCli("sendtoaddress", toAddress, amount);
        db.N21Store.storeBitcoinTrade("send", WALLET_NAME, toAddress + " " + amount + " BTC", result);
        return result;
    }

    // ── Message pass-through ──────────────────────────────────────────────────

    public void send_message(final StringBuffer BUFFER) {}
    public void send_message(final String MESSAGE)      {}

    // ── Process helpers ───────────────────────────────────────────────────────

    /**
     * Run bitcoin-cli with the shared RPC flags, no wallet suffix.
     * Additional args are appended after the RPC flags.
     */
    protected String cli(final String... args)
    {
        String[] cmd = buildCmd(false, args);
        return exec(cmd);
    }

    /**
     * Run bitcoin-cli with -rpcwallet=WALLET_NAME prepended to args.
     */
    protected String walletCli(final String... args)
    {
        String[] cmd = buildCmd(true, args);
        return exec(cmd);
    }

    private String[] buildCmd(final boolean withWallet, final String... args)
    {
        int base = 1 + RPC_FLAGS.length + (withWallet ? 1 : 0);
        String[] cmd = new String[base + args.length];
        cmd[0] = BITCOIN_CLI;
        System.arraycopy(RPC_FLAGS, 0, cmd, 1, RPC_FLAGS.length);
        int off = 1 + RPC_FLAGS.length;
        if (withWallet) { cmd[off] = "-rpcwallet=" + WALLET_NAME; off++; }
        System.arraycopy(args, 0, cmd, off, args.length);
        return cmd;
    }

    /** Execute a command, capture stdout+stderr, return combined output. */
    private String exec(final String[] cmd)
    {
        try
        {
            Process p = Runtime.getRuntime().exec(cmd);
            String out = new BufferedReader(new InputStreamReader(p.getInputStream()))
                .lines().collect(Collectors.joining("\n"));
            String err = new BufferedReader(new InputStreamReader(p.getErrorStream()))
                .lines().collect(Collectors.joining("\n"));
            p.waitFor();
            String result = out.isBlank() ? err : out;
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". BitcoinBase >> " + cmd[0] + " " + (cmd.length > 1 ? cmd[cmd.length - 1] : "") + " >> " + result + " .");
            return result;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return "ERROR: " + e.getMessage();
        }
    }
}
