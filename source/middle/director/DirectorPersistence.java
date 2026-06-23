package middle.director;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.StringJoiner;

/**
 * Persistent storage for director module trade records.
 * Saves to relative CSV files under data/middle/director/.
 *
 * Record fields:
 *   timestamp, tradeType, nationalId, ipAddress, publicKey, signatoryId,
 *   signatoryKey, employmentStatus (binary 0/1), democratStatus (binary 0/1)
 */
public class DirectorPersistence
{
    private static final String BASE_DIR = "data/middle/director";
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    static { init(); }

    private static void init()
    {
        try { Files.createDirectories(Path.of(BASE_DIR)); }
        catch (IOException e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    /**
     * Persist a trade record to the module's CSV file.
     */
    public static synchronized void saveTrade(
        String moduleName,
        String tradeType,
        long nationalId,
        String ipAddress,
        String publicKey,
        long signatoryId,
        String signatoryKey,
        boolean employed,
        boolean democrat
    )
    {
        Path file = Path.of(BASE_DIR, moduleName + "-trades.csv");
        boolean newFile = !Files.exists(file);

        try (BufferedWriter w = Files.newBufferedWriter(file,
                StandardOpenOption.CREATE, StandardOpenOption.APPEND))
        {
            if (newFile)
                w.write("timestamp,tradeType,nationalId,ipAddress,publicKey,signatoryId,signatoryKey,employmentStatus,democratStatus,edition,rank\n");

            StringJoiner row = new StringJoiner(",");
            row.add(LocalDateTime.now().format(FMT));
            row.add(escape(tradeType));
            row.add(String.valueOf(nationalId));
            row.add(escape(ipAddress));
            row.add(escape(publicKey));
            row.add(String.valueOf(signatoryId));
            row.add(escape(signatoryKey));
            row.add(employed ? "1" : "0");
            row.add(democrat ? "1" : "0");
            row.add(DistributionLicense.getEdition().name());
            row.add(String.valueOf(DistributionLicense.getRank()));
            w.write(row + "\n");
        }
        catch (IOException e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private static String escape(String val)
    {
        if (val == null) return "";
        if (val.contains(",") || val.contains("\""))
            return "\"" + val.replace("\"", "\"\"") + "\"";
        return val;
    }
}
