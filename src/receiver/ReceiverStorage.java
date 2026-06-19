package receiver;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.*;
import java.time.Instant;

/**
 * ReceiverStorage — MySQL or Binary Wallet storage for received data.
 * MEARVK LLC — Max Rupplin
 */
public class ReceiverStorage {

    private final ReceiverConfig config;
    private Connection dbConn;

    public ReceiverStorage(ReceiverConfig config) throws Exception {
        this.config = config;
        if ("mysql".equals(config.getStorageBackend())) {
            initMySQL();
        } else {
            initWallet();
        }
    }

    private void initMySQL() throws Exception {
        String url = "jdbc:mysql://" + config.getMysqlHost() + ":" + config.getMysqlPort() + "/" + config.getMysqlDatabase();
        dbConn = DriverManager.getConnection(url, config.getMysqlUsername(), config.getMysqlPassword());
        // Auto-create table
        try (Statement stmt = dbConn.createStatement()) {
            stmt.executeUpdate(
                "CREATE TABLE IF NOT EXISTS " + config.getMysqlTable() + " (" +
                "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                "  source_ip VARCHAR(45) NOT NULL," +
                "  payload LONGTEXT NOT NULL," +
                "  sha256 CHAR(64) NOT NULL," +
                "  received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                ")"
            );
        }
        System.out.println("-- : [ReceiverStorage] . MySQL backend ready .");
    }

    private void initWallet() throws IOException {
        File wallet = new File(config.getWalletPath());
        wallet.getParentFile().mkdirs();
        if (!wallet.exists()) wallet.createNewFile();
        System.out.println("-- : [ReceiverStorage] . Binary wallet backend ready at " + config.getWalletPath() + " .");
    }

    public synchronized void store(String sourceIp, String payload) throws Exception {
        String sha = sha256(payload);
        if ("mysql".equals(config.getStorageBackend())) {
            storeMySQL(sourceIp, payload, sha);
        } else {
            storeWallet(sourceIp, payload, sha);
        }
    }

    private void storeMySQL(String sourceIp, String payload, String sha) throws SQLException {
        String sql = "INSERT INTO " + config.getMysqlTable() + " (source_ip, payload, sha256) VALUES (?, ?, ?)";
        try (PreparedStatement ps = dbConn.prepareStatement(sql)) {
            ps.setString(1, sourceIp);
            ps.setString(2, payload);
            ps.setString(3, sha);
            ps.executeUpdate();
        }
    }

    private void storeWallet(String sourceIp, String payload, String sha) throws IOException {
        File wallet = new File(config.getWalletPath());
        // Check max size
        if (wallet.length() > (long) config.getWalletMaxSizeMb() * 1024 * 1024) {
            System.err.println("[ReceiverStorage] Binary wallet max size reached.");
            return;
        }
        try (FileOutputStream fos = new FileOutputStream(wallet, true);
             DataOutputStream dos = new DataOutputStream(fos)) {
            byte[] data = payload.getBytes(StandardCharsets.UTF_8);
            dos.writeLong(Instant.now().toEpochMilli());
            dos.writeUTF(sourceIp);
            dos.writeUTF(sha);
            dos.writeInt(data.length);
            dos.write(data);
        }
    }

    private String sha256(String input) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest(input.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder();
        for (byte b : hash) sb.append(String.format("%02x", b));
        return sb.toString();
    }
}
