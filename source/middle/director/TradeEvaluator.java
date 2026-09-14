package middle.director;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Evaluates whether a trade is "upwards and better" based on nationalId profile
 * (trust level + education grade of reasoning).
 *
 * If upward: trade succeeds immediately.
 * Otherwise: trade is held for 48-hour auditor review on the middle server.
 */
public class TradeEvaluator
{
    private static final String HOLD_DIR = "data/middle/director/holds";
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
    private static final int TRUST_THRESHOLD = 50;
    private static final int EDUCATION_GRADE_THRESHOLD = 3; // bachelors or above

    static { try { Files.createDirectories(Path.of(HOLD_DIR)); } catch (IOException ignored) {} }

    /**
     * Evaluate a trade. Returns true if trade succeeds immediately (upwards/better).
     * Returns false if placed on 48hr auditor hold.
     */
    public static boolean evaluate(String moduleName, String tradeType, long nationalId,
                                   int trustLevel, String educationLevel, String input)
    {
        int grade = educationGrade(educationLevel);
        boolean upward = trustLevel >= TRUST_THRESHOLD && grade >= EDUCATION_GRADE_THRESHOLD;

        if (!upward)
        {
            holdForReview(moduleName, tradeType, nationalId, trustLevel, educationLevel, input);
        }

        return upward;
    }

    /** Place trade on 48-hour auditor hold. */
    private static synchronized void holdForReview(String moduleName, String tradeType,
                                                   long nationalId, int trustLevel,
                                                   String educationLevel, String input)
    {
        Path file = Path.of(HOLD_DIR, moduleName + "-holds.csv");
        boolean newFile = !Files.exists(file);

        try (BufferedWriter w = Files.newBufferedWriter(file,
                StandardOpenOption.CREATE, StandardOpenOption.APPEND))
        {
            if (newFile)
                w.write("holdUntil,submitted,moduleName,tradeType,nationalId,trustLevel,educationLevel,input\n");

            LocalDateTime now = LocalDateTime.now();
            LocalDateTime release = now.plusHours(48);

            w.write(release.format(FMT) + "," +
                    now.format(FMT) + "," +
                    moduleName + "," +
                    tradeType + "," +
                    nationalId + "," +
                    trustLevel + "," +
                    educationLevel + "," +
                    "\"" + input.replace("\"", "\"\"") + "\"\n");
        }
        catch (IOException e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    /** Map education level to numeric grade for comparison. */
    private static int educationGrade(String level)
    {
        if (level == null) return 0;
        return switch (level.toLowerCase().trim())
        {
            case "none"        -> 0;
            case "high school" -> 1;
            case "trade"       -> 2;
            case "associates"  -> 2;
            case "bachelors"   -> 3;
            case "masters"     -> 4;
            case "phd"         -> 5;
            default            -> 1;
        };
    }
}
