package bitcoin.module;

import bitcoin.base.BitcoinBase;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.Instant;

/**
 * Records authenticated Bitcoin Core balance observations.
 *
 * The value is an observation from getbalance, not an inferred wallet-file
 * balance. Monetary storage is fixed-point satoshis.
 */
public final class BitcoinBalanceObserver
{
    private static final String TABLE = "bitcoin_balance_observations";

    public void observe()
    {
        try (Connection conn = database.N21DataSource.get())
        {
            if (conn == null) return;
            createTable(conn);

            BitcoinBase rpc = new BitcoinBase(null);
            String balanceText = rpc.get_balance();
            long satoshis = parseSatoshis(balanceText);

            String sql = "INSERT INTO " + TABLE +
                " (wallet_name, balance_satoshis, source_method, observed_at) VALUES (?,?,?,?)";
            try (PreparedStatement ps = conn.prepareStatement(sql))
            {
                ps.setString(1, "United States");
                ps.setLong(2, satoshis);
                ps.setString(3, "getbalance");
                ps.setTimestamp(4, java.sql.Timestamp.from(Instant.now()));
                ps.executeUpdate();
            }
        }
        catch (Exception e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }
    }

    private void createTable(final Connection conn) throws Exception
    {
        try (Statement st = conn.createStatement())
        {
            st.executeUpdate("CREATE TABLE IF NOT EXISTS " + TABLE + " (" +
                "id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                "wallet_name VARCHAR(128) NOT NULL," +
                "balance_satoshis BIGINT UNSIGNED NOT NULL," +
                "source_method VARCHAR(64) NOT NULL," +
                "observed_at DATETIME(6) NOT NULL," +
                "KEY ix_balance_wallet_time (wallet_name, observed_at)" +
                ") ENGINE=InnoDB");
        }
    }

    static long parseSatoshis(final String text)
    {
        if (text == null || text.isBlank()) throw new IllegalArgumentException("Bitcoin Core returned an empty balance");
        BigDecimal btc = new BigDecimal(text.trim());
        if (btc.signum() < 0 || btc.scale() > 8) throw new IllegalArgumentException("Invalid Bitcoin Core balance");
        BigDecimal satoshis = btc.movePointRight(8).setScale(0, RoundingMode.UNNECESSARY);
        if (satoshis.compareTo(BigDecimal.valueOf(Long.MAX_VALUE)) > 0)
            throw new IllegalArgumentException("Bitcoin Core balance is too large");
        return satoshis.longValueExact();
    }
}
