package bitcoin.module;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.SQLException;
import java.time.Instant;
import java.util.HexFormat;
import java.util.stream.Stream;

/**
 * BitcoinWalletIndexer indexes wallet-file metadata only.
 *
 * It deliberately does not infer BTC balances from filenames or file sizes,
 * does not store wallet blobs in MySQL, and does not seed fictional balances.
 * Authoritative balances must be obtained from authenticated Bitcoin Core RPC.
 */
public class BitcoinWalletIndexer
{
    private static final String BITCOIN_DIR = System.getenv().getOrDefault("BITCOIN_DATA_ROOT", "bitcoin");
    private static final String TABLE_NAME = "bitcoin_wallet_artifacts";
    private static final int[] VERSIONS = {24, 25, 26, 27, 28, 29, 30};

    public BitcoinWalletIndexer()
    {
    }

    /** Index wallet artifacts for all supported Bitcoin Core versions. */
    public void indexAll()
    {
        try (Connection conn = database.N21DataSource.get())
        {
            if (conn == null) return;
            createTable(conn);

            for (int version : VERSIONS)
                indexVersion(conn, version);

            commons.CommonRails.printSystemComponent(this, this.hashCode(),
                ". BitcoinWalletIndexer: wallet artifact metadata indexed .");
        }
        catch (Exception e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }
    }

    /**
     * Boot-time fallback. It creates the metadata schema only; it never invents
     * wallet balances or inserts synthetic wallet records.
     */
    public static void seedDefaults()
    {
        try (Connection conn = database.N21DataSource.get())
        {
            if (conn == null) return;
            new BitcoinWalletIndexer().createTable(conn);
            commons.CommonRails.printSystemComponent(new BitcoinWalletIndexer(), 0,
                ". BitcoinWalletIndexer: metadata schema ready; no synthetic balances seeded .");
        }
        catch (Exception e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }
    }

    private void createTable(Connection conn) throws SQLException
    {
        String sql = "CREATE TABLE IF NOT EXISTS " + TABLE_NAME + " (" +
            "id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
            "bitcoin_version SMALLINT UNSIGNED NOT NULL," +
            "relative_path VARCHAR(1024) NOT NULL," +
            "canonical_path VARCHAR(2048) NOT NULL," +
            "wallet_name VARCHAR(512) NOT NULL," +
            "file_size_bytes BIGINT UNSIGNED NOT NULL," +
            "modified_at DATETIME(6) NOT NULL," +
            "sha256 VARCHAR(64) NOT NULL," +
            "indexed_at DATETIME(6) NOT NULL," +
            "UNIQUE KEY uq_wallet_artifact (bitcoin_version, relative_path(512), sha256)," +
            "KEY ix_wallet_artifact_hash (sha256)," +
            "KEY ix_wallet_artifact_version (bitcoin_version)" +
            ") ENGINE=InnoDB";

        try (Statement st = conn.createStatement())
        {
            st.executeUpdate(sql);
        }
    }

    private void indexVersion(Connection conn, int version)
    {
        Path versionDir = Path.of(BITCOIN_DIR, String.valueOf(version));
        if (!Files.isDirectory(versionDir)) return;

        try (Stream<Path> paths = Files.find(versionDir, Integer.MAX_VALUE,
            (path, attrs) -> attrs.isRegularFile() && isWalletArtifact(path)))
        {
            paths.forEach(file -> insertArtifact(conn, version, versionDir, file));
        }
        catch (IOException e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }
    }

    private boolean isWalletArtifact(Path file)
    {
        String name = file.getFileName().toString().toLowerCase(java.util.Locale.ROOT);
        return name.equals("wallet.dat") || name.startsWith("wallet-") && name.endsWith(".dat");
    }

    private void insertArtifact(Connection conn, int version, Path versionDir, Path file)
    {
        try
        {
            Path canonical = file.toRealPath();
            long fileSize = Files.size(canonical);
            String relativePath = versionDir.toAbsolutePath().normalize().relativize(canonical).toString();
            String walletName = canonical.getFileName().toString();
            String sha256 = sha256(canonical);
            Instant modified = Files.getLastModifiedTime(canonical).toInstant();
            Instant indexed = Instant.now();

            String sql = "INSERT INTO " + TABLE_NAME +
                " (bitcoin_version, relative_path, canonical_path, wallet_name, file_size_bytes, " +
                "modified_at, sha256, indexed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?) " +
                "ON DUPLICATE KEY UPDATE canonical_path=VALUES(canonical_path), " +
                "file_size_bytes=VALUES(file_size_bytes), modified_at=VALUES(modified_at), " +
                "indexed_at=VALUES(indexed_at)";

            try (PreparedStatement ps = conn.prepareStatement(sql))
            {
                ps.setInt(1, version);
                ps.setString(2, relativePath);
                ps.setString(3, canonical.toString());
                ps.setString(4, walletName);
                ps.setLong(5, fileSize);
                ps.setTimestamp(6, java.sql.Timestamp.from(modified));
                ps.setString(7, sha256);
                ps.setTimestamp(8, java.sql.Timestamp.from(indexed));
                ps.executeUpdate();
            }
        }
        catch (Exception e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }
    }

    private String sha256(Path file) throws Exception
    {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (java.io.InputStream in = Files.newInputStream(file))
        {
            byte[] buffer = new byte[1024 * 1024];
            int read;
            while ((read = in.read(buffer)) >= 0)
            {
                if (read > 0) digest.update(buffer, 0, read);
            }
        }
        return HexFormat.of().formatHex(digest.digest());
    }
}
