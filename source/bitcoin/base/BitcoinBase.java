package bitcoin.base;


import bitcoin.messaging.MessageOrderer;
import bitcoin.time.BitcoinAmericaAndNewYorkDate;
import bitcoin.time.BitcoinAsiaAndTokyoDate;
import commons.CommonRails;
import server.nitro.NitroWebExpress;
import server.nitro.WebExpress;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * @author Max Rupplin
 * @date April 30 2026 - 2671 G. Soros Amazing
 */
public class BitcoinBase
{
    protected String hash = "0xDA717018470E213F";

    protected NitroWebExpress.Aspect aspect;

    protected final String BITCOIN_CLI = "bitcoin-cli";

    protected final String BITCOIND = "bitcoind";
    
    protected final String BITCOIN_ROOT_PASSWORD = "";
    
    protected final String BITCOIN_PORT = "";

    protected final String BITCOIND_START_ARGS = "-regtest -daemon -rpcpassword="+BITCOIN_ROOT_PASSWORD+" -rpcport="+BITCOIN_PORT;

    protected final String BITCOIN_CLI_LOAD_WALLET_ARGS = "-named loadwallet -rpcpassword="+BITCOIN_ROOT_PASSWORD+" -rpcport="+BITCOIN_PORT+" wallet_name=\"United States\"";

    protected final String BITCOIN_GET_WALLET_NAME_ARGS = "-named getwalletinfo -rpcpassword="+BITCOIN_ROOT_PASSWORD+" -rpcport="+BITCOIN_PORT+" wallet_name\"United States\"";

    protected final String BITCOIN_CLI_DELETE_WALLET_CMD = "rm -r";

    protected final String BITCOIN_CLI_UNLOAD_WALLET_ARGS = "-named unloadwallet -rpcpassword="+BITCOIN_ROOT_PASSWORD+" -rpcport="+BITCOIN_PORT+" wallet_name=\"United States\"";

    protected final String BITCOIN_CLI_RENAME_WALLET_ARGS = "";

    protected final String BITCOIN_CLI_ADD_NEW_WALLET_ARGS = "bitcoin-cli createwallet -rpcpassword="+BITCOIN_ROOT_PASSWORD+" -rpcport="+BITCOIN_PORT;

    protected final String BITCOIN_CLI_SEND_LOCAL_WALLET_TO_REMOTE_WALLET_ARGS = "";

    protected final String SPACE = " ";

    protected MessageOrderer bitcoin_message_orderer = new MessageOrderer(this);

    public BitcoinBase(NitroWebExpress.Aspect aspect)
    {
        this.aspect = aspect;

        BitcoinAsiaAndTokyoDate JAPANDate = new BitcoinAsiaAndTokyoDate();

        BitcoinAmericaAndNewYorkDate ESTDate = new BitcoinAmericaAndNewYorkDate();

        CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress::Bitcoin >> opens in North Carolina on [Date: "+ESTDate.EST_Time);

        CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress::Bitcoin >> opens in Japan on [Date: "+JAPANDate.PACIFIC_Time);
    }

    public void send_message(StringBuffer buffer)
    {

    }

    public void send_message(String message)
    {

    }

    private boolean isWindows()
    {
        return System.getProperty("os.name").toLowerCase().contains("win");
    }

    private String runCommand(final String cmd)
        throws IOException
    {
        try
        {
            ProcessBuilder pb;

            if (isWindows())
            {
                pb = new ProcessBuilder("cmd", "/c", cmd);
            }
            else
            {
                pb = new ProcessBuilder("sh", "-c", cmd);
            }

            pb.redirectErrorStream(true);

            Process process = pb.start();

            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));

            String line;

            StringBuilder output = new StringBuilder();

            while ((line = reader.readLine()) != null)
            {
                output.append(line).append('\n');

                CommonRails.printSystemComponent(this, this.hashCode(), "BitcoinBase::runCommand >> "+line);
            }

            try { process.waitFor(); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); }

            return output.toString();
        }
        catch (IOException ioe)
        {
            throw ioe;
        }
    }

    public void start_server_instance(final String url)
    {
        try
        {
            String cmd = BITCOIND+SPACE+BITCOIND_START_ARGS;

            String out = runCommand(cmd);

            CommonRails.printSystemComponent(this, this.hashCode(), "start_server_instance output: "+out);
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "start_server_instance failed: "+e.getMessage());
        }
    }

    public void load_wallet(final String url) throws IOException
    {
        try
        {
            String cmd = BITCOIN_CLI+SPACE+BITCOIN_CLI_LOAD_WALLET_ARGS;

            String out = runCommand(cmd);

            CommonRails.printSystemComponent(this, this.hashCode(), "load_wallet output: "+out);
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "load_wallet failed: "+e.getMessage());
        }
    }

    public String get_wallet_name(final String url)
    {
        try
        {
            String cmd = BITCOIN_CLI+SPACE+ BITCOIN_GET_WALLET_NAME_ARGS;

            String out = runCommand(cmd);

            if (out != null && !out.isEmpty())
            {
                CommonRails.printSystemComponent(this, this.hashCode(), "WebExpress::Bitcoin >> "+out.trim());

                return out.trim();
            }

            CommonRails.printSystemComponent(this, this.hashCode(), "get_wallet_name returned empty");

            return "-1";
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "get_wallet_name failed: "+e.getMessage());
        }

        return "-1";
    }

    public void delete_wallet(final String url) throws IOException
    {
        final String SEPARATOR = "/";

        final String SPACE = " ";

        final String VERSION = "24";

        final String DIR = "/mnt/blockstorage";

        final String SPECIFIC_DIR = DIR+SEPARATOR+VERSION;

        final String REGTEST = "/regtest/wallets";

        final String WALLET_DIR = SPECIFIC_DIR+SEPARATOR+REGTEST;

        final String WALLET_NAME = this.get_wallet_name(url);

        final String COMPLETE_URL = WALLET_DIR+SEPARATOR+WALLET_NAME;

        try
        {
            String cmd = BITCOIN_CLI_DELETE_WALLET_CMD+SPACE+WALLET_DIR;

            String out = runCommand(cmd);

            CommonRails.printSystemComponent(this, this.hashCode(), "delete_wallet output: "+out);
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "delete_wallet failed: "+e.getMessage());
        }
    }

    public void unload_wallet(final String url) throws IOException
    {
        try
        {
            String cmd = BITCOIN_CLI+SPACE+BITCOIN_CLI_UNLOAD_WALLET_ARGS;

            String out = runCommand(cmd);

            CommonRails.printSystemComponent(this, this.hashCode(), "unload_wallet output: "+out);
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "unload_wallet failed: "+e.getMessage());
        }
    }

    public void rename_wallet(final String url)
    {
        try
        {
            String cmd = BITCOIN_CLI+SPACE+BITCOIN_CLI_RENAME_WALLET_ARGS;

            String out = runCommand(cmd);

            CommonRails.printSystemComponent(this, this.hashCode(), "rename_wallet output: "+out);
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "rename_wallet failed: "+e.getMessage());
        }
    }

    public void add_new_wallet(final String url)
    {
        try
        {
            String cmd = BITCOIN_CLI+SPACE+BITCOIN_CLI_ADD_NEW_WALLET_ARGS;

            String out = runCommand(cmd);

            CommonRails.printSystemComponent(this, this.hashCode(), "add_new_wallet output: "+out);
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "add_new_wallet failed: "+e.getMessage());
        }
    }

    public void send_local_wallet_to_remote_wallet(final String url)
    {
        try
        {
            String cmd = BITCOIN_CLI+SPACE+ BITCOIN_CLI_SEND_LOCAL_WALLET_TO_REMOTE_WALLET_ARGS;

            String out = runCommand(cmd);

            CommonRails.printSystemComponent(this, this.hashCode(), "send_local_wallet_to_remote_wallet output: "+out);
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "send_local_wallet_to_remote_wallet failed: "+e.getMessage());
        }
    }
}
