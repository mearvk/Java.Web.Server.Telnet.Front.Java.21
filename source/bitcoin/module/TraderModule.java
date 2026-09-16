package bitcoin.module;

import bitcoin.messaging.MessageOrderer;
import bitcoin.time.BitcoinAmericaAndNewYorkDate;
import bitcoin.time.BitcoinAsiaAndTokyoDate;
import commons.CommonRails;
import exceptions.ExceptionHandler;
import server.nitro.NitroWebExpress;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

/**
 * Bitcoin Core process/RPC adapter for the local regtest environment.
 *
 * RPC credentials are intentionally not embedded in this class. Bitcoin Core
 * cookie authentication is used by bitcoin-cli for local RPC access.
 *
 * @author Max Rupplin
 * @date 2026-09-16
 */
public class TraderModule
{
    protected final String hash = "0xDA717018470E213F";
    protected final NitroWebExpress.Aspect ASPECT;
    protected final String BITCOIN_CLI = "bitcoin-cli";
    protected final String BITCOIND = "bitcoind";
    protected final String BITCOIN_PORT = System.getenv().getOrDefault("BITCOIN_RPC_PORT", "2222");
    protected final String BITCOIN_NETWORK = "regtest";
    protected final String BITCOIN_WALLET = System.getenv().getOrDefault("BITCOIN_WALLET", "United States");
    protected final String TITLE;
    protected final MessageOrderer bitcoin_message_orderer = new MessageOrderer(this);

    public TraderModule(final NitroWebExpress.Aspect ASPECT, final String TITLE)
    {
        this.ASPECT = ASPECT;
        this.TITLE = TITLE;

        BitcoinAsiaAndTokyoDate JAPANDate = new BitcoinAsiaAndTokyoDate();
        BitcoinAmericaAndNewYorkDate ESTDate = new BitcoinAmericaAndNewYorkDate();

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". WebExpress Bitcoin >> opens in North Carolina on Date " + ESTDate.EST_Time + " . ");
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". WebExpress Bitcoin >> opens in Japan on Date " + JAPANDate.PACIFIC_Time + " . ");
    }

    public void send_message(final StringBuffer BUFFER) { }
    public void send_message(final String MESSAGE) { }

    /** Start a local Bitcoin Core regtest daemon without embedding credentials. */
    public void start_server_instance(final String URL)
    {
        execute(BITCOIND, "-" + BITCOIN_NETWORK, "-daemon", "-rpcport=" + BITCOIN_PORT);
    }

    /** Load the configured wallet through Bitcoin Core RPC. */
    public void load_wallet(final String URL) throws IOException
    {
        executeAndReport(BITCOIN_CLI, "-" + BITCOIN_NETWORK, "-rpcport=" + BITCOIN_PORT,
            "-named", "loadwallet", "wallet_name=" + BITCOIN_WALLET);
    }

    /** Return the configured wallet's Bitcoin Core JSON state. */
    public String get_wallet_name(final String URL)
    {
        return executeAndCapture(BITCOIN_CLI, "-" + BITCOIN_NETWORK, "-rpcport=" + BITCOIN_PORT,
            "-rpcwallet=" + BITCOIN_WALLET, "getwalletinfo");
    }

    /**
     * Destructive filesystem deletion is deliberately not implemented.
     * Wallet lifecycle operations belong to Bitcoin Core and require explicit backup/authorization.
     */
    public void delete_wallet(final String URL) throws IOException
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            "Bitcoin wallet deletion refused: filesystem deletion is disabled. Use an explicit Bitcoin Core lifecycle procedure after verified backup.");
    }

    /** Unload the configured wallet through Bitcoin Core RPC. */
    public void unload_wallet(final String URL) throws IOException
    {
        executeAndReport(BITCOIN_CLI, "-" + BITCOIN_NETWORK, "-rpcport=" + BITCOIN_PORT,
            "-named", "unloadwallet", "wallet_name=" + BITCOIN_WALLET);
    }

    /**
     * Bitcoin Core does not provide the previous filesystem-style rename operation
     * used by this adapter. Refuse rather than executing an empty command.
     */
    public void rename_wallet(final String URL)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            "Bitcoin wallet rename refused: unsupported operation in this adapter.");
    }

    /** Create the configured wallet through Bitcoin Core RPC. */
    public void add_new_wallet(final String URL)
    {
        executeAndReport(BITCOIN_CLI, "-" + BITCOIN_NETWORK, "-rpcport=" + BITCOIN_PORT,
            "-named", "createwallet", "wallet_name=" + BITCOIN_WALLET);
    }

    /**
     * Remote wallet transfer is intentionally not implemented. A transfer must be
     * an explicit transaction with validated destination, amount, authorization,
     * and confirmation tracking rather than an opaque command string.
     */
    public void send_local_wallet_to_remote_wallet(final String URL)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            "Bitcoin remote-wallet transfer refused: explicit transaction workflow required.");
    }

    private void executeAndReport(final String... command) throws IOException
    {
        String output = executeAndCapture(command);
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Bitcoin RPC result >> " + output + " .");
    }

    private String executeAndCapture(final String... command)
    {
        try
        {
            ProcessBuilder builder = new ProcessBuilder(command);
            builder.redirectErrorStream(true);
            Process process = builder.start();

            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream())))
            {
                String line;
                while ((line = reader.readLine()) != null)
                {
                    if (output.length() > 0) output.append('\n');
                    output.append(line);
                }
            }

            int exitCode = process.waitFor();
            if (exitCode != 0)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". Bitcoin RPC failed >> exit=" + exitCode + " .");
            }
            return output.toString();
        }
        catch (InterruptedException e)
        {
            Thread.currentThread().interrupt();
            ExceptionHandler.dispatch(e);
            return "-1";
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return "-1";
        }
    }

    private void execute(final String... command)
    {
        try
        {
            ProcessBuilder builder = new ProcessBuilder(command);
            builder.redirectErrorStream(true);
            Process process = builder.start();
            int exitCode = process.waitFor();
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Bitcoin Core start >> exit=" + exitCode + " .");
        }
        catch (InterruptedException e)
        {
            Thread.currentThread().interrupt();
            ExceptionHandler.dispatch(e);
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
    }
}
