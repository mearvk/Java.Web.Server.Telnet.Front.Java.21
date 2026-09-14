package red.Futures.source.ai.training;

import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.util.stream.Collectors;
import java.util.List;

/**
 * WeightPersistence — saves and loads model weights to/from MySQL (model_weights table).
 * Stores binary weight data with model name, timestamp, and ordering metadata.
 *
 * @author MEARVK LLC — Max Rupplin
 */
public class WeightPersistence
{
    private static final String DB_URL = "jdbc:mysql://localhost:3306/democratic_d500";

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS model_weights (" +
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
        "  model_name VARCHAR(128) NOT NULL," +
        "  module VARCHAR(64) NOT NULL," +
        "  weight_data LONGBLOB NOT NULL," +
        "  ordering_metadata TEXT," +
        "  trained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
        "  file_count INT," +
        "  epochs INT," +
        "  INDEX idx_model_module (model_name, module)" +
        ")";

    private static final String CREATE_SESSIONS_TABLE =
        "CREATE TABLE IF NOT EXISTS training_sessions (" +
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
        "  module VARCHAR(64) NOT NULL," +
        "  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
        "  completed_at TIMESTAMP NULL," +
        "  models_trained INT," +
        "  status VARCHAR(32) DEFAULT 'running'" +
        ")";

    private static final String INSERT_WEIGHT =
        "INSERT INTO model_weights (model_name, module, weight_data, ordering_metadata, file_count, epochs) VALUES (?, ?, ?, ?, ?, ?)";

    private static final String SELECT_LATEST =
        "SELECT weight_data FROM model_weights WHERE model_name = ? AND module = ? ORDER BY trained_at DESC LIMIT 1";

    public WeightPersistence()
    {
        initTables();
    }

    private void initTables()
    {
        try (Connection conn = getConnection(); Statement stmt = conn.createStatement())
        {
            stmt.execute(CREATE_TABLE);
            stmt.execute(CREATE_SESSIONS_TABLE);
        }
        catch (SQLException e)
        {
            System.out.println("[WeightPersistence] Table init deferred: " + e.getMessage());
        }
    }

    /**
     * Saves all weight files from a model directory into MySQL.
     */
    public void saveWeights(String modelName, String module, Path weightsDir, String orderingMetadata, int fileCount, int epochs)
    {
        try
        {
            byte[] weightData = packDirectory(weightsDir);

            try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(INSERT_WEIGHT))
            {
                ps.setString(1, modelName);
                ps.setString(2, module);
                ps.setBytes(3, weightData);
                ps.setString(4, orderingMetadata);
                ps.setInt(5, fileCount);
                ps.setInt(6, epochs);
                ps.executeUpdate();
            }

            System.out.println("[WeightPersistence] Saved " + modelName + " (" + module + ") to MySQL — " + weightData.length + " bytes");
        }
        catch (Exception e)
        {
            System.out.println("[WeightPersistence] Save deferred: " + e.getMessage());
        }
    }

    /**
     * Loads latest weights for a model from MySQL back to disk.
     */
    public boolean loadWeights(String modelName, String module, Path targetDir) throws Exception
    {
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(SELECT_LATEST))
        {
            ps.setString(1, modelName);
            ps.setString(2, module);

            try (ResultSet rs = ps.executeQuery())
            {
                if (rs.next())
                {
                    byte[] data = rs.getBytes("weight_data");
                    unpackDirectory(data, targetDir);
                    System.out.println("[WeightPersistence] Loaded " + modelName + " from MySQL → " + targetDir);
                    return true;
                }
            }
        }
        return false;
    }

    public long recordSessionStart(String module)
    {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO training_sessions (module) VALUES (?)", Statement.RETURN_GENERATED_KEYS))
        {
            ps.setString(1, module);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) { if (rs.next()) return rs.getLong(1); }
        }
        catch (SQLException e) { System.out.println("[WeightPersistence] Session start deferred: " + e.getMessage()); }
        return -1;
    }

    public void recordSessionEnd(long sessionId, int modelsTrained, String status)
    {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "UPDATE training_sessions SET completed_at=NOW(), models_trained=?, status=? WHERE id=?"))
        {
            ps.setInt(1, modelsTrained);
            ps.setString(2, status);
            ps.setLong(3, sessionId);
            ps.executeUpdate();
        }
        catch (SQLException e) { System.out.println("[WeightPersistence] Session end deferred: " + e.getMessage()); }
    }

    private byte[] packDirectory(Path dir) throws IOException
    {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        DataOutputStream dos = new DataOutputStream(baos);

        List<Path> files = Files.walk(dir).filter(Files::isRegularFile).collect(Collectors.toList());
        dos.writeInt(files.size());

        for (Path file : files)
        {
            String relativeName = dir.relativize(file).toString();
            byte[] content = Files.readAllBytes(file);
            dos.writeUTF(relativeName);
            dos.writeInt(content.length);
            dos.write(content);
        }

        dos.flush();
        return baos.toByteArray();
    }

    private void unpackDirectory(byte[] data, Path targetDir) throws IOException
    {
        Files.createDirectories(targetDir);
        DataInputStream dis = new DataInputStream(new ByteArrayInputStream(data));

        int fileCount = dis.readInt();
        for (int i = 0; i < fileCount; i++)
        {
            String name = dis.readUTF();
            int len = dis.readInt();
            byte[] content = new byte[len];
            dis.readFully(content);

            Path target = targetDir.resolve(name);
            Files.createDirectories(target.getParent());
            Files.write(target, content);
        }
    }

    private Connection getConnection() throws SQLException
    {
        String password = System.getenv("DEMOCRATIC_DB_PASSWORD");
        return DriverManager.getConnection(DB_URL, "mearvk_admin", password != null ? password : "");
    }
}
