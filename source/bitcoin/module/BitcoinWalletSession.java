package bitcoin.module;

import connections.Connection;
import national.NationalFinanceID;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * BitcoinWalletSession — handles telnet commands for browsing/selecting/trading BTC wallets.
 *
 * Commands:
 *   bitcoin                 — show available versions (24-30)
 *   bitcoin <version>       — list wallets for that version
 *   set wallet.name <name>  — select wallet for session (persists to DB)
 *   unset wallet.name       — deselect wallet
 *   trade btc <amount>      — trade BTC from selected wallet (recorded in trades table)
 *
 * Original wallet data in bitcoin_wallets_v{N} is NEVER modified.
 * Trades are recorded in bitcoin_trades_v{N} tables.
 */
public class BitcoinWalletSession
{
    private static final String AUTHOR = "Max Ruppln - Clear 21 Branch US Military";

    /** Handle a bitcoin-related command. Returns response string. */
    public static String handle(String cmd, Connection conn, NationalFinanceID nfid)
    {
        String lower = cmd.trim().toLowerCase();

        if (lower.equals("bitcoin"))
            return listVersions(conn);
        else if (lower.startsWith("bitcoin "))
            return listWallets(cmd.trim().substring(8).trim(), conn);
        else if (lower.startsWith("set wallet.name "))
            return setWallet(cmd.trim().substring(16).trim(), conn, nfid);
        else if (lower.equals("unset wallet.name"))
            return unsetWallet(conn, nfid);
        else if (lower.startsWith("trade btc "))
            return tradeBtc(cmd.trim().substring(10).trim(), conn, nfid);
        else if (lower.equals("show wallet"))
            return showWallet(conn);

        return null; // not a bitcoin command
    }

    /** Check if input is a bitcoin command. */
    public static boolean isBitcoinCommand(String cmd)
    {
        String l = cmd.trim().toLowerCase();
        return l.equals("bitcoin") || l.startsWith("bitcoin ") ||
               l.startsWith("set wallet.name ") || l.equals("unset wallet.name") ||
               l.startsWith("trade btc ") || l.equals("show wallet");
    }

    private static String listVersions(Connection conn)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("\r\n  Bitcoin Wallet Versions\r\n  ─────────────────────────\r\n");
        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            if (db == null) return "  [DB unavailable]";

            for (int v = 24; v <= 30; v++)
            {
                Statement st = db.createStatement();
                ResultSet rs = st.executeQuery("SELECT COUNT(*) as c, IFNULL(SUM(btc_value),0) as btc FROM bitcoin_wallets_v" + v);
                if (rs.next())
                    sb.append("  v").append(v).append("  — ").append(rs.getInt("c")).append(" wallets, ").append(rs.getLong("btc")).append(" BTC\r\n");
                rs.close(); st.close();
            }
            sb.append("\r\n  Usage: bitcoin <version>  (e.g. bitcoin 24)");
            if (conn.btcWallet != null)
                sb.append("\r\n  Active wallet: ").append(conn.btcWallet).append(" (v").append(conn.btcVersion).append(")");
        }
        catch (Exception e) { return "  [Error querying wallets]"; }
        return sb.toString();
    }

    private static String listWallets(String versionStr, Connection conn)
    {
        int version;
        try { version = Integer.parseInt(versionStr); }
        catch (NumberFormatException e) { return "  Usage: bitcoin <24|25|26|27|28|29|30>"; }
        if (version < 24 || version > 30) return "  Invalid version. Use 24–30.";

        StringBuilder sb = new StringBuilder();
        sb.append("\r\n  Wallets — v").append(version).append("\r\n  ─────────────────────────\r\n");
        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            Statement st = db.createStatement();
            ResultSet rs = st.executeQuery(
                "SELECT wallet_name, file_size_bytes, btc_value, usd_value FROM bitcoin_wallets_v" + version +
                " ORDER BY btc_value DESC LIMIT 25");
            int i = 1;
            while (rs.next())
            {
                sb.append(String.format("  %2d. %-30s %,12d bytes  %,8d BTC\r\n",
                    i++, rs.getString("wallet_name"), rs.getLong("file_size_bytes"), rs.getLong("btc_value")));
            }
            rs.close(); st.close();
            sb.append("\r\n  Use: set wallet.name <name>  to select a wallet.");

            // Remember version selection in session
            conn.btcVersion = version;
        }
        catch (Exception e) { return "  [Error listing wallets]"; }
        return sb.toString();
    }

    private static String setWallet(String name, Connection conn, NationalFinanceID nfid)
    {
        if (conn.btcVersion == 0) return "  Select a version first: bitcoin <24-30>";
        if (name.isEmpty()) return "  Usage: set wallet.name <wallet_name>";

        // Verify wallet exists
        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            PreparedStatement ps = db.prepareStatement(
                "SELECT wallet_name FROM bitcoin_wallets_v" + conn.btcVersion + " WHERE wallet_name = ?");
            ps.setString(1, name);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) { rs.close(); ps.close(); return "  Wallet '" + name + "' not found in v" + conn.btcVersion + "."; }
            rs.close(); ps.close();

            conn.btcWallet = name;

            // Persist session to DB
            saveSession(nfid.nationalId, conn.btcVersion, name);

            return "  ✔  Wallet set: " + name + " (v" + conn.btcVersion + ")";
        }
        catch (Exception e) { return "  [Error setting wallet]"; }
    }

    private static String unsetWallet(Connection conn, NationalFinanceID nfid)
    {
        conn.btcWallet = null;
        conn.btcVersion = 0;
        clearSession(nfid.nationalId);
        return "  ✔  Wallet unset.";
    }

    private static String showWallet(Connection conn)
    {
        if (conn.btcWallet == null) return "  No wallet selected. Use: bitcoin <version>, then set wallet.name <name>";
        return "  Active wallet: " + conn.btcWallet + " (v" + conn.btcVersion + ")";
    }

    private static String tradeBtc(String amountStr, Connection conn, NationalFinanceID nfid)
    {
        if (conn.btcWallet == null) return "  No wallet selected. Use: set wallet.name <name>";

        long amount;
        try { amount = Long.parseLong(amountStr); }
        catch (NumberFormatException e) { return "  Usage: trade btc <amount>"; }
        if (amount <= 0) return "  Amount must be positive.";

        try
        {
            java.sql.Connection db = database.N21DataSource.get();

            // Create trades table if not exists
            String tradesTable = "bitcoin_trades_v" + conn.btcVersion;
            Statement st = db.createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS " + tradesTable + " (" +
                "  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                "  national_id BIGINT UNSIGNED NOT NULL," +
                "  wallet_name VARCHAR(512) NOT NULL," +
                "  btc_amount BIGINT NOT NULL," +
                "  usd_value DOUBLE NOT NULL," +
                "  trade_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                "  author VARCHAR(256) NOT NULL" +
                ") ENGINE=InnoDB");
            st.close();

            double usd = amount * 20_000_000_000_000.0;

            PreparedStatement ps = db.prepareStatement(
                "INSERT INTO " + tradesTable + " (national_id, wallet_name, btc_amount, usd_value, author) VALUES (?,?,?,?,?)");
            ps.setLong(1, nfid.nationalId);
            ps.setString(2, conn.btcWallet);
            ps.setLong(3, amount);
            ps.setDouble(4, usd);
            ps.setString(5, AUTHOR);
            ps.executeUpdate();
            ps.close();

            return "  ✔  Trade recorded: " + amount + " BTC from " + conn.btcWallet + " (v" + conn.btcVersion + ") = $" + String.format("%.2e", usd) + " USD";
        }
        catch (Exception e) { return "  [Error recording trade: " + e.getMessage() + "]"; }
    }

    private static void saveSession(long nationalId, int version, String wallet)
    {
        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            if (db == null) return;

            Statement st = db.createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS bitcoin_wallet_sessions (" +
                "  national_id BIGINT UNSIGNED PRIMARY KEY," +
                "  btc_version INT NOT NULL," +
                "  wallet_name VARCHAR(512) NOT NULL," +
                "  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
                ") ENGINE=InnoDB");
            st.close();

            PreparedStatement ps = db.prepareStatement(
                "INSERT INTO bitcoin_wallet_sessions (national_id, btc_version, wallet_name) VALUES (?,?,?) " +
                "ON DUPLICATE KEY UPDATE btc_version=VALUES(btc_version), wallet_name=VALUES(wallet_name)");
            ps.setLong(1, nationalId);
            ps.setInt(2, version);
            ps.setString(3, wallet);
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception ignored) {}
    }

    private static void clearSession(long nationalId)
    {
        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            if (db == null) return;
            PreparedStatement ps = db.prepareStatement("DELETE FROM bitcoin_wallet_sessions WHERE national_id=?");
            ps.setLong(1, nationalId);
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception ignored) {}
    }
}
