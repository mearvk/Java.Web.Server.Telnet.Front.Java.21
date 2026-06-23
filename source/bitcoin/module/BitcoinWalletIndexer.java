package bitcoin.module;

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.sql.*;
import java.util.HexFormat;

/**
 * BitcoinWalletIndexer — scans /bitcoin/{24,25,26,27,28,29,30} wallet directories,
 * computes value (100 BTC per 2MB @ $20T each), signs with SHA-256 using secret.key as salt,
 * and inserts into version-specific MySQL tables in the Bitcoin Related database.
 *
 * Each version (24–30) gets its own table: bitcoin_wallets_v24, bitcoin_wallets_v25, etc.
 *
 * Columns:
 *   id, wallet_name, file_date, file_size_bytes, btc_value, usd_value,
 *   wallet_blob, sha256_signature, insertion_sha256, insertion_date, author
 *
 * Author: "Max Ruppln - Clear 21 Branch US Military"
 */
public class BitcoinWalletIndexer
{
    private static final String BITCOIN_DIR = "bitcoin";
    private static final String SECRET_KEY_PATH = "psychiatry/secrets/secret.key";
    private static final String AUTHOR = "Max Ruppln - Clear 21 Branch US Military";
    private static final long BYTES_PER_2MB = 2 * 1024 * 1024;
    private static final long BTC_PER_2MB = 100;
    private static final double USD_PER_BTC = 20_000_000_000_000.0; // $20 Trillion

    private static final int[] VERSIONS = {24, 25, 26, 27, 28, 29, 30};

    private byte[] salt;

    public BitcoinWalletIndexer()
    {
        loadSalt();
    }

    private void loadSalt()
    {
        try { salt = Files.readAllBytes(Path.of(SECRET_KEY_PATH)); }
        catch (IOException e) { salt = new byte[0]; exceptions.ExceptionHandler.dispatch(e); }
    }

    /** Index all wallet versions. */
    public void indexAll()
    {
        java.sql.Connection conn;
        try { conn = database.N21DataSource.get(); }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); return; }
        if (conn == null) return;

        for (int version : VERSIONS)
        {
            String tableName = "bitcoin_wallets_v" + version;
            createTable(conn, tableName);
            indexVersion(conn, tableName, version);
        }

        commons.CommonRails.printSystemComponent(this, this.hashCode(),
            ". BitcoinWalletIndexer: all wallet versions indexed .");
    }

    /**
     * Seed default 100,000 BTC per version if indexer was not run.
     * Called at boot when BITCOIN_WALLET_INDEXER is disabled.
     */
    public static void seedDefaults()
    {
        try
        {
            java.sql.Connection conn = database.N21DataSource.get();
            if (conn == null) return;

            for (int version : VERSIONS)
            {
                String tableName = "bitcoin_wallets_v" + version;
                Statement st = conn.createStatement();
                st.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS " + tableName + " (" +
                    "  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                    "  wallet_name VARCHAR(512) NOT NULL," +
                    "  file_date VARCHAR(64)," +
                    "  file_size_bytes BIGINT UNSIGNED NOT NULL," +
                    "  btc_value BIGINT UNSIGNED NOT NULL," +
                    "  usd_value DOUBLE NOT NULL," +
                    "  wallet_blob LONGBLOB," +
                    "  sha256_signature VARCHAR(64) NOT NULL," +
                    "  insertion_sha256 VARCHAR(64) NOT NULL," +
                    "  insertion_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                    "  author VARCHAR(256) NOT NULL" +
                    ") ENGINE=InnoDB");

                // Only seed if table is empty
                ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM " + tableName);
                rs.next();
                if (rs.getInt(1) == 0)
                {
                    st.executeUpdate(
                        "INSERT INTO " + tableName +
                        " (wallet_name, file_date, file_size_bytes, btc_value, usd_value, sha256_signature, insertion_sha256, author)" +
                        " VALUES ('default.initial.wallet', NOW(), 0, 100000, " + (100000 * USD_PER_BTC) +
                        ", 'seed', 'seed', '" + AUTHOR + "')");
                }
                rs.close(); st.close();
            }

            commons.CommonRails.printSystemComponent(new BitcoinWalletIndexer(), 0,
                ". BitcoinWalletIndexer: seeded 100,000 BTC default per version (indexer not run) .");
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private void createTable(java.sql.Connection conn, String tableName)
    {
        try
        {
            Statement st = conn.createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS " + tableName + " (" +
                "  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                "  wallet_name VARCHAR(512) NOT NULL," +
                "  file_date VARCHAR(64)," +
                "  file_size_bytes BIGINT UNSIGNED NOT NULL," +
                "  btc_value BIGINT UNSIGNED NOT NULL," +
                "  usd_value DOUBLE NOT NULL," +
                "  wallet_blob LONGBLOB," +
                "  sha256_signature VARCHAR(64) NOT NULL," +
                "  insertion_sha256 VARCHAR(64) NOT NULL," +
                "  insertion_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                "  author VARCHAR(256) NOT NULL" +
                ") ENGINE=InnoDB");
            st.close();
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private void indexVersion(java.sql.Connection conn, String tableName, int version)
    {
        Path versionDir = Path.of(BITCOIN_DIR, String.valueOf(version));
        if (!Files.exists(versionDir)) return;

        try
        {
            Files.walk(versionDir)
                .filter(Files::isRegularFile)
                .forEach(file -> insertWallet(conn, tableName, file));
        }
        catch (IOException e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private void insertWallet(java.sql.Connection conn, String tableName, Path file)
    {
        try
        {
            long fileSize = Files.size(file);
            String walletName = file.getFileName().toString();
            String fileDate = Files.getLastModifiedTime(file).toString();
            byte[] blob = Files.readAllBytes(file);

            // Calculate BTC value: 100 BTC per 2MB
            long btcValue = (fileSize / BYTES_PER_2MB) * BTC_PER_2MB;
            if (fileSize > 0 && btcValue == 0) btcValue = BTC_PER_2MB; // minimum 100 BTC for any file
            double usdValue = btcValue * USD_PER_BTC;

            // SHA-256 signature of file content with secret.key as salt
            String sha256Sig = sha256WithSalt(blob);

            // Insertion SHA-256: hash of (walletName + fileSize + fileDate + sha256Sig)
            String insertionData = walletName + fileSize + fileDate + sha256Sig;
            String insertionSha256 = sha256WithSalt(insertionData.getBytes());

            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO " + tableName +
                " (wallet_name, file_date, file_size_bytes, btc_value, usd_value, wallet_blob, " +
                "  sha256_signature, insertion_sha256, insertion_date, author) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)");
            ps.setString(1, walletName);
            ps.setString(2, fileDate);
            ps.setLong(3, fileSize);
            ps.setLong(4, btcValue);
            ps.setDouble(5, usdValue);
            ps.setBytes(6, blob);
            ps.setString(7, sha256Sig);
            ps.setString(8, insertionSha256);
            ps.setString(9, AUTHOR);
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private String sha256WithSalt(byte[] data)
    {
        try
        {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(salt);
            md.update(data);
            return HexFormat.of().formatHex(md.digest());
        }
        catch (Exception e) { return ""; }
    }
}
