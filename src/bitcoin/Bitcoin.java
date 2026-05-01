package bitcoin;

import commons.CommonRails;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

/**
 * @author Max Rupplin
 * @date April 30 2026 - 2671 G. Soros Amazing
 */
public class Bitcoin
{
    protected final String BITCOIN_CLI = "bitcoin-cli";

    protected final String BITCOIND = "bitcoind";
    
    protected final String BITCOIN_ROOT_PASSWORD = "";
    
    protected final String BITCOIN_PORT = "";

    protected final String BITCOIND_START_ARGS = "-regtest -daemon";

    protected final String BITCOIN_CLI_LOAD_WALLET_ARGS = "-named loadwallet -rpcpassword=\""+BITCOIN_ROOT_PASSWORD+"\" -rpcport=\""+BITCOIN_PORT+"\" wallet_name=\"United States\"";

    protected final String BITCOIN_GET_WALLET_NAME_ARGS = "-named getwalletinfo -rpcpassword=\""+BITCOIN_ROOT_PASSWORD+"\" -rpcport=\""+BITCOIN_PORT+"\" wallet_name\"United States\"";

    protected final String BITCOIN_CLI_DELETE_WALLET_CMD = "rm -r";

    protected final String BITCOIN_CLI_UNLOAD_WALLET_ARGS = "-named unloadwallet wallet_name=\"United States\"";

    protected final String BITCOIN_CLI_RENAME_WALLET_ARGS = "";

    protected final String BITCOIN_CLI_ADD_NEW_WALLET_ARGS = "";

    protected final String BITCOIN_CLI_SEND_LOCAL_WALLET_TO_REMOTE_WALLET_ARGS = "";

    protected final String SPACE = " ";

    public Bitcoin()
    {
        SimpleDateFormat date_formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");

        date_formatter.setTimeZone(TimeZone.getTimeZone("America/New_York"));

        CommonRails.printSystemComponent(this.hashCode(),"WebExpress::Bitcoin >> opens on Date [["+date_formatter.format(new Date())+"]]");
    }

    public void start_server_instance(final String url)
    {
        try
        {
            Process process = Runtime.getRuntime().exec(BITCOIND+SPACE+BITCOIND_START_ARGS);

            CommonRails.printSystemComponent(this.hashCode(), "0x8766Ea");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "0x8A66Ea");
        }
    }

    public void load_wallet(final String url) throws IOException
    {
        try
        {
            Process process = Runtime.getRuntime().exec(BITCOIN_CLI+SPACE+BITCOIN_CLI_LOAD_WALLET_ARGS);

            CommonRails.printSystemComponent(this.hashCode(), "0x8766Ea");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "0x8A66Ea");
        }
    }

    public String get_wallet_name(final String url)
    {
        try
        {
            Process process = Runtime.getRuntime().exec(BITCOIND+SPACE+ BITCOIN_GET_WALLET_NAME_ARGS);

            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));

            String message;

            StringBuilder return_value = new StringBuilder();

            if((message=reader.readLine())!=null)
            {
                return_value.append(message);

                CommonRails.printSystemComponent(this.hashCode(), "WebExpress::Bitcoin >> "+message);

                while((message=reader.readLine())!=null)
                {
                    return_value.append(message);

                    CommonRails.printSystemComponent(this.hashCode(), "WebExpress::Bitcoin >> "+message);
                }

                return return_value.toString();
            }

            CommonRails.printSystemComponent(this.hashCode(), "0x8766Ea");

            return "-1";
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "0x8A66Ea");
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
            Process process = Runtime.getRuntime().exec(BITCOIN_CLI_DELETE_WALLET_CMD+SPACE+WALLET_DIR);

            CommonRails.printSystemComponent(this.hashCode(), "0x8766Ea");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "0x8A66Ea");
        }
    }

    public void unload_wallet(final String url) throws IOException
    {
        try
        {
            Process process = Runtime.getRuntime().exec(BITCOIN_CLI+SPACE+BITCOIN_CLI_UNLOAD_WALLET_ARGS);

            CommonRails.printSystemComponent(this.hashCode(), "0x8766Ea");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "0x8A66Ea");
        }
    }

    public void rename_wallet(final String url)
    {
        try
        {
            Process process = Runtime.getRuntime().exec(BITCOIN_CLI+SPACE+BITCOIN_CLI_RENAME_WALLET_ARGS);

            CommonRails.printSystemComponent(this.hashCode(), "0x8766Ea");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "0x8A66Ea");
        }
    }

    public void add_new_wallet(final String url)
    {
        try
        {
            Process process = Runtime.getRuntime().exec(BITCOIN_CLI+SPACE+BITCOIN_CLI_ADD_NEW_WALLET_ARGS);

            CommonRails.printSystemComponent(this.hashCode(), "0x8766Ea");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "0x8A66Ea");
        }
    }

    public void send_local_wallet_to_remote_wallet(final String url)
    {
        try
        {
            Process process = Runtime.getRuntime().exec(BITCOIN_CLI+SPACE+ BITCOIN_CLI_SEND_LOCAL_WALLET_TO_REMOTE_WALLET_ARGS);

            CommonRails.printSystemComponent(this.hashCode(), "0x8766Ea");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "0x8A66Ea");
        }
    }
}
