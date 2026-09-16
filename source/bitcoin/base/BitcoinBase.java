package bitcoin.base;

import bitcoin.messaging.MessageOrderer;
import bitcoin.time.BitcoinAmericaAndNewYorkDate;
import bitcoin.time.BitcoinAsiaAndTokyoDate;
import commons.CommonRails;
import exceptions.ExceptionHandler;
import server.nitro.NitroWebExpress;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * BitcoinBase — controlled wrapper around a local bitcoind instance.
 *
 * RPC authentication is delegated to Bitcoin Core cookie authentication.
 * The server never accepts arbitrary bitcoin-cli method names and never places
 * RPC credentials in source code or command arguments.
 */
public class BitcoinBase
{
    protected String hash = "0xDA717018470E213F";
    protected NitroWebExpress.Aspect ASPECT;

    protected static final String BITCOIN_CLI = "bitcoin-cli";
    protected static final String BITCOIND = "bitcoind";
    protected static final String RPC_PORT = configuredRpcPort();
    protected static final String NETWORK = "-regtest";
    protected static final String WALLET_NAME = "United States";
    private static final Duration RPC_TIMEOUT = Duration.ofSeconds(30);

    protected MessageOrderer bitcoin_message_orderer = new MessageOrderer(this);

    public BitcoinBase(final NitroWebExpress.Aspect ASPECT)
    {
        this.ASPECT = ASPECT;
        BitcoinAsiaAndTokyoDate JAPANDate = new BitcoinAsiaAndTokyoDate();
        BitcoinAmericaAndNewYorkDate ESTDate = new BitcoinAmericaAndNewYorkDate();

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". WebExpress Bitcoin >> opens in North Carolina on Date " + ESTDate.EST_Time + " . ");
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". WebExpress Bitcoin >> opens in Japan on Date " + JAPANDate.PACIFIC_Time + " . ");

        database.N21Store.createBitcoinTradesTable();
    }

    public String start_bitcoind()
    {
        String result = exec(List.of(BITCOIND, NETWORK, "-daemon", "-rpcport=" + RPC_PORT), false);
        database.N21Store.storeBitcoinTrade("start_bitcoind", "", "", result);
        return result;
    }

    public String stop_bitcoind()
    {
        String result = cli("stop");
        database.N21Store.storeBitcoinTrade("stop_bitcoind", "", "", result);
        return result;
    }

    public String load_wallet()
    {
        BitcoinRpcPolicy.requireWalletName(WALLET_NAME);
        String result = cli("loadwallet", WALLET_NAME);
        database.N21Store.storeBitcoinTrade("load_wallet", WALLET_NAME, "", result);
        return result;
    }

    public String unload_wallet()
    {
        BitcoinRpcPolicy.requireWalletName(WALLET_NAME);
        String result = cli("unloadwallet", WALLET_NAME);
        database.N21Store.storeBitcoinTrade("unload_wallet", WALLET_NAME, "", result);
        return result;
    }

    public String create_wallet(final String name)
    {
        BitcoinRpcPolicy.requireWalletName(name);
        String result = cli("createwallet", name);
        database.N21Store.storeBitcoinTrade("create_wallet", name, "", result);
        return result;
    }

    public String get_wallet_info() { return walletCli("getwalletinfo"); }
    public String get_balance() { return walletCli("getbalance"); }
    public String get_new_address() { return walletCli("getnewaddress"); }
    public String get_blockchain_info() { return cli("getblockchaininfo"); }
    public String get_block_count() { return cli("getblockcount"); }

    /**
     * Broadcast a transaction only after strict address and amount validation.
     * Bitcoin Core remains the authority for transaction acceptance.
     */
    public String send(final String toAddress, final String amount)
    {
        BitcoinRpcPolicy.requireAddress(toAddress);
        long satoshis = BitcoinRpcPolicy.requireSatoshis(amount);
        String normalizedAmount = BigDecimal.valueOf(satoshis, 8).toPlainString();
        String result = walletCli("sendtoaddress", toAddress, normalizedAmount);
        database.N21Store.storeBitcoinTrade("send", WALLET_NAME,
            "address=" + toAddress + " satoshis=" + satoshis, result);
        return result;
    }

    public void send_message(final StringBuffer BUFFER) {}
    public void send_message(final String MESSAGE) {}

    protected String cli(final String... args)
    {
        if (args.length == 0) throw new IllegalArgumentException("Bitcoin RPC method is required");
        BitcoinRpcPolicy.requireAllowed(args[0]);
        return exec(buildCmd(false, args), true);
    }

    protected String walletCli(final String... args)
    {
        if (args.length == 0) throw new IllegalArgumentException("Bitcoin RPC method is required");
        BitcoinRpcPolicy.requireAllowed(args[0]);
        return exec(buildCmd(true, args), true);
    }

    private List<String> buildCmd(final boolean withWallet, final String... args)
    {
        List<String> cmd = new ArrayList<>();
        cmd.add(BITCOIN_CLI);
        cmd.add(NETWORK);
        cmd.add("-rpcport=" + RPC_PORT);
        if (withWallet) cmd.add("-rpcwallet=" + WALLET_NAME);
        for (String arg : args) cmd.add(arg);
        return cmd;
    }

    private String exec(final List<String> cmd, final boolean rpc)
    {
        try
        {
            ProcessBuilder builder = new ProcessBuilder(cmd);
            builder.redirectErrorStream(true);
            Process process = builder.start();

            String result;
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream())))
            {
                result = reader.lines().collect(Collectors.joining("\n"));
            }

            if (!process.waitFor(RPC_TIMEOUT.toMillis(), java.util.concurrent.TimeUnit.MILLISECONDS))
            {
                process.destroyForcibly();
                return "ERROR: Bitcoin process timed out";
            }

            int exit = process.exitValue();
            String method = cmd.size() > 3 ? cmd.get(cmd.size() - (rpc ? Math.min(1, cmd.size() - 1) : 1)) : "process";
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". BitcoinBase >> controlled RPC invocation exit=" + exit + " method=" + (cmd.size() > 3 ? cmd.get(3) : method) + " .");
            return result == null ? "" : result;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return "ERROR: Bitcoin RPC operation failed";
        }
    }

    private static String configuredRpcPort()
    {
        String value = System.getenv().getOrDefault("BITCOIN_RPC_PORT", "2222");
        try
        {
            int port = Integer.parseInt(value);
            if (port < 1 || port > 65535) throw new NumberFormatException();
            return Integer.toString(port);
        }
        catch (NumberFormatException e)
        {
            return "2222";
        }
    }
}
