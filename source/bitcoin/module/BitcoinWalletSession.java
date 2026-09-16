package bitcoin.module;

import connections.Connection;
import national.NationalFinanceID;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

/**
 * BitcoinWalletSession — handles telnet commands for browsing/selecting BTC wallets.
 *
 * Commands:
 *   bitcoin                 — show available versions (24-30)
 *   bitcoin <version>       — list wallet metadata for that version
 *   set wallet.name <name>  — select wallet for session
 *   unset wallet.name       — deselect wallet
 *   trade btc <amount>      — record a trade event; DOES NOT submit a blockchain transaction
 *   show wallet             — show the selected wallet
 *
 * Financial balances are never inferred from wallet filenames or file sizes.
 * Bitcoin Core RPC is the authoritative source for an actual wallet balance.
 */
public class BitcoinWalletSession
{
    private static final int MIN_VERSION = 24;
    private static final int MAX_VERSION = 30;
    private static final long SATOSHIS_PER_BTC = 100_000_000L;
    private static final int MAX_TRADE_SCALE = 8;

    /** Handle a bitcoin-related command. Returns response string. */
    public static String handle(String cmd, Connection conn, NationalFinanceID nfid)
    {
        if (cmd == null) return null;
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

        return null;
    }

    public static boolean isBitcoinCommand(String cmd)
    {
        if (cmd == null) return false;
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

            for (int v = MIN_VERSION; v <= MAX_VERSION; v++)
            {
                String table = walletTable(v);
                try (Statement st = db.createStatement();
                     ResultSet rs = st.executeQuery("SELECT COUNT(*) AS c FROM " + table))
                {
                    if (rs.next())
                        sb.append("  v").append(v).append("  — ").append(rs.getInt("c")).append(" wallet records\r\n");
                }
            }
            sb.append("\r\n  Usage: bitcoin <version>  (e.g. bitcoin 24)");
            if (conn.btcWallet != null)
                sb.append("\r\n  Active wallet: ").append(conn.btcWallet).append(" (v").append(conn.btcVersion).append(")");
        }
        catch (Exception e) { return "  [Error querying wallet metadata]"; }
        return sb.toString();
    }

    private static String listWallets(String versionStr, Connection conn)
    {
        final int version;
        try { version = Integer.parseInt(versionStr); }
        catch (NumberFormatException e) { return "  Usage: bitcoin <24|25|26|27|28|29|30>"; }
        if (!validVersion(version)) return "  Invalid version. Use 24–30.";

        StringBuilder sb = new StringBuilder();
        sb.append("\r\n  Wallet Metadata — v").append(version).append("\r\n  ─────────────────────────\r\n");
        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            if (db == null) return "  [DB unavailable]";
            String table = walletTable(version);
            String query = "SELECT wallet_name, file_size_bytes FROM " + table + " ORDER BY wallet_name LIMIT 25";
            try (Statement st = db.createStatement(); ResultSet rs = st.executeQuery(query))
            {
                int i = 1;
                while (rs.next())
                {
                    sb.append(String.format("  %2d. %-30s %,12d bytes\r\n",
                        i++, rs.getString("wallet_name"), rs.getLong("file_size_bytes")));
                }
            }
            sb.append("\r\n  NOTE: file size is metadata, not a BTC balance.");
            sb.append("\r\n  Use authenticated Bitcoin Core RPC for authoritative balances.");
            sb.append("\r\n  Use: set wallet.name <name>  to select a wallet.");
            conn.btcVersion = version;
        }
        catch (Exception e) { return "  [Error listing wallet metadata]"; }
        return sb.toString();
    }

    private static String setWallet(String name, Connection conn, NationalFinanceID nfid)
    {
        if (conn.btcVersion == 0) return "  Select a version first: bitcoin <24-30>";
        if (name.isEmpty() || name.length() > 512) return "  Usage: set wallet.name <wallet_name>";

        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            if (db == null) return "  [DB unavailable]";
            String table = walletTable(conn.btcVersion);
            try (PreparedStatement ps = db.prepareStatement("SELECT wallet_name FROM " + table + " WHERE wallet_name = ?"))
            {
                ps.setString(1, name);
                try (ResultSet rs = ps.executeQuery())
                {
                    if (!rs.next()) return "  Wallet '" + name + "' not found in v" + conn.btcVersion + ".";
                }
            }

            conn.btcWallet = name;
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

    /**
     * Records a trade event only. This method never broadcasts or submits a transaction.
     * Amounts are stored as exact satoshis and optional fiat valuation is operator supplied.
     */
    private static String tradeBtc(String amountStr, Connection conn, NationalFinanceID nfid)
    {
        if (conn.btcWallet == null) return "  No wallet selected. Use: set wallet.name <name>";
        if (amountStr.isEmpty()) return "  Usage: trade btc <amount>";

        final long satoshis;
        try
        {
            BigDecimal btc = new BigDecimal(amountStr).setScale(MAX_TRADE_SCALE, RoundingMode.UNNECESSARY);
            if (btc.signum() <= 0) return "  Amount must be positive.";
            BigDecimal satoshiDecimal = btc.movePointRight(MAX_TRADE_SCALE);
            if (satoshiDecimal.compareTo(BigDecimal.valueOf(Long.MAX_VALUE)) > 0)
                return "  Amount is too large.";
            satoshis = satoshiDecimal.longValueExact();
            if (satoshis <= 0) return "  Amount must be positive.";
        }
        catch (ArithmeticException | NumberFormatException e)
        {
            return "  Amount must be a positive BTC decimal with at most 8 decimal places.";
        }

        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            if (db == null) return "  [DB unavailable]";

            String table = tradeTable(conn.btcVersion);
            try (Statement st = db.createStatement())
            {
                st.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS " + table + " (" +
                    "  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                    "  national_id BIGINT UNSIGNED NOT NULL," +
                    "  wallet_name VARCHAR(512) NOT NULL," +
                    "  amount_satoshis BIGINT UNSIGNED NOT NULL," +
                    "  btc_price_usd DECIMAL(38,8) NULL," +
                    "  usd_value DECIMAL(38,8) NULL," +
                    "  trade_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                    "  event_state VARCHAR(32) NOT NULL DEFAULT 'RECORDED'," +
                    "  author VARCHAR(256) NOT NULL" +
                    ") ENGINE=InnoDB");
            }

            BigDecimal price = readOptionalPrice();
            BigDecimal usd = price == null ? null : BigDecimal.valueOf(satoshis)
                .divide(BigDecimal.valueOf(SATOSHIS_PER_BTC), 8, RoundingMode.HALF_UP)
                .multiply(price).setScale(8, RoundingMode.HALF_UP);

            String sql = "INSERT INTO " + table +
                " (national_id, wallet_name, amount_satoshis, btc_price_usd, usd_value, event_state, author) VALUES (?,?,?,?,?,?,?)";
            try (PreparedStatement ps = db.prepareStatement(sql))
            {
                ps.setLong(1, nfid.nationalId);
                ps.setString(2, conn.btcWallet);
                ps.setLong(3, satoshis);
                if (price == null) ps.setNull(4, java.sql.Types.DECIMAL); else ps.setBigDecimal(4, price);
                if (usd == null) ps.setNull(5, java.sql.Types.DECIMAL); else ps.setBigDecimal(5, usd);
                ps.setString(6, "RECORDED");
                ps.setString(7, "JWSTF BitcoinWalletSession");
                ps.executeUpdate();
            }

            String btc = BigDecimal.valueOf(satoshis).movePointLeft(MAX_TRADE_SCALE).stripTrailingZeros().toPlainString();
            return price == null
                ? "  ✔  Trade event recorded: " + btc + " BTC (" + satoshis + " satoshis). No blockchain transaction was submitted."
                : "  ✔  Trade event recorded: " + btc + " BTC (" + satoshis + " satoshis), valuation $" + usd.toPlainString() + ". No blockchain transaction was submitted.";
        }
        catch (Exception e) { return "  [Error recording trade event]"; }
    }

    private static BigDecimal readOptionalPrice()
    {
        String value = System.getenv("BTC_PRICE_USD");
        if (value == null || value.trim().isEmpty()) return null;
        try
        {
            BigDecimal price = new BigDecimal(value.trim()).setScale(8, RoundingMode.HALF_UP);
            return price.signum() >= 0 ? price : null;
        }
        catch (NumberFormatException e) { return null; }
    }

    private static boolean validVersion(int version)
    {
        return version >= MIN_VERSION && version <= MAX_VERSION;
    }

    private static String walletTable(int version)
    {
        if (!validVersion(version)) throw new IllegalArgumentException("Unsupported Bitcoin version");
        return "bitcoin_wallets_v" + version;
    }

    private static String tradeTable(int version)
    {
        if (!validVersion(version)) throw new IllegalArgumentException("Unsupported Bitcoin version");
        return "bitcoin_trade_events_v" + version;
    }

    private static void saveSession(long nationalId, int version, String wallet)
    {
        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            if (db == null) return;
            try (Statement st = db.createStatement())
            {
                st.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS bitcoin_wallet_sessions (" +
                    "  national_id BIGINT UNSIGNED PRIMARY KEY," +
                    "  btc_version INT NOT NULL," +
                    "  wallet_name VARCHAR(512) NOT NULL," +
                    "  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
                    ") ENGINE=InnoDB");
            }
            try (PreparedStatement ps = db.prepareStatement(
                "INSERT INTO bitcoin_wallet_sessions (national_id, btc_version, wallet_name) VALUES (?,?,?) " +
                "ON DUPLICATE KEY UPDATE btc_version=VALUES(btc_version), wallet_name=VALUES(wallet_name)"))
            {
                ps.setLong(1, nationalId);
                ps.setInt(2, version);
                ps.setString(3, wallet);
                ps.executeUpdate();
            }
        }
        catch (Exception ignored) {}
    }

    private static void clearSession(long nationalId)
    {
        try
        {
            java.sql.Connection db = database.N21DataSource.get();
            if (db == null) return;
            try (PreparedStatement ps = db.prepareStatement("DELETE FROM bitcoin_wallet_sessions WHERE national_id=?"))
            {
                ps.setLong(1, nationalId);
                ps.executeUpdate();
            }
        }
        catch (Exception ignored) {}
    }
}
