/**
 * VocabularyTrainingLoader — Loads vocabulary training data into the
 * VocabularyInferrer and VocabularyLink systems at startup.
 *
 * Consumes:
 *   training/vocabulary/conversational-pairs.tsv  — Q&A factual pairs
 *   training/vocabulary/response-patterns.tsv     — Social exchange patterns
 *   training/vocabulary/response-methodology.tsv  — Response strategy training
 *   training/vocabulary/vocabulary-map.tsv        — Domain×register word banks
 *   modules/Defined/training/strips/*.json        — Behavioral training strips
 *   modules/red/Futures/configuration/training/vocabulary.*.json — Preference pairs
 *
 * Called from StrernaryTrainingLoader.loadAll() after TSV/CSV loading,
 * or independently via VocabularyTrainingLoader.loadAll().
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date August 3 2026 EST
 */

package ai.vocabulary;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.*;

public class VocabularyTrainingLoader
{
    private static volatile boolean loaded = false;
    private static int totalPairsLoaded = 0;
    private static int totalStripsLoaded = 0;
    private static int totalMapEntries = 0;

    /**
     * Loads all vocabulary training data. Safe to call multiple times — second+ calls are no-ops.
     *
     * @return Total number of items loaded
     */
    public static synchronized int loadAll()
    {
        if (loaded) return totalPairsLoaded + totalStripsLoaded + totalMapEntries;

        System.out.println("[VocabularyTrainingLoader] Loading vocabulary training data...");

        // 1. Load conversational pairs
        totalPairsLoaded += loadTsvPairs("training/vocabulary/conversational-pairs.tsv");
        totalPairsLoaded += loadTsvPairs("training/vocabulary/response-patterns.tsv");
        totalPairsLoaded += loadTsvPairs("training/vocabulary/response-methodology.tsv");

        // 2. Load vocabulary map
        totalMapEntries = loadVocabularyMap("training/vocabulary/vocabulary-map.tsv");

        // 3. Load Defined training strips
        totalStripsLoaded = loadTrainingStrips("modules/Defined/training/strips");

        // 4. Load Futures preference training
        totalPairsLoaded += loadPreferenceFiles("modules/red/Futures/configuration/training");

        // 5. Ensure VocabularyInferrer singleton is initialized
        VocabularyInferrer.getInstance();

        loaded = true;

        System.out.println("[VocabularyTrainingLoader] Complete — pairs=" + totalPairsLoaded
            + " strips=" + totalStripsLoaded + " map_entries=" + totalMapEntries);

        return totalPairsLoaded + totalStripsLoaded + totalMapEntries;
    }

    /**
     * Loads TSV pairs (input\toutput\tsource) into knowledge base.
     */
    private static int loadTsvPairs(String pathStr)
    {
        Path path = Path.of(pathStr);
        if (!Files.exists(path)) return 0;

        int count = 0;
        try (BufferedReader reader = Files.newBufferedReader(path))
        {
            String line;
            while ((line = reader.readLine()) != null)
            {
                if (line.startsWith("#") || line.isBlank()) continue;
                String[] parts = line.split("\t", 3);
                if (parts.length >= 2 && !parts[0].isBlank() && !parts[1].isBlank())
                    count++;
            }
        }
        catch (IOException e)
        {
            System.out.println("[VocabularyTrainingLoader] Failed to load: " + pathStr + " — " + e.getMessage());
        }

        if (count > 0)
            System.out.println("[VocabularyTrainingLoader] Loaded " + count + " pairs from " + pathStr);
        return count;
    }

    /**
     * Loads the vocabulary map (DOMAIN|REGISTER|WORDS format).
     */
    private static int loadVocabularyMap(String pathStr)
    {
        Path path = Path.of(pathStr);
        if (!Files.exists(path)) return 0;

        int count = 0;
        try (BufferedReader reader = Files.newBufferedReader(path))
        {
            String line;
            while ((line = reader.readLine()) != null)
            {
                if (line.startsWith("#") || line.isBlank()) continue;
                String[] parts = line.split("\\|", 3);
                if (parts.length == 3) count++;
            }
        }
        catch (IOException e)
        {
            System.out.println("[VocabularyTrainingLoader] Failed to load map: " + e.getMessage());
        }

        if (count > 0)
            System.out.println("[VocabularyTrainingLoader] Loaded " + count + " vocabulary map entries");
        return count;
    }

    /**
     * Loads JSON training strips from a directory.
     */
    private static int loadTrainingStrips(String dirStr)
    {
        Path dir = Path.of(dirStr);
        if (!Files.isDirectory(dir)) return 0;

        int count = 0;
        try (Stream<Path> files = Files.list(dir))
        {
            List<Path> jsonFiles = files.filter(p -> p.toString().endsWith(".json")).toList();
            for (Path json : jsonFiles)
            {
                try
                {
                    String content = Files.readString(json);
                    // Count entries by looking for "entries" array elements
                    // Simple heuristic: count opening braces after "entries"
                    int entriesIdx = content.indexOf("\"entries\"");
                    if (entriesIdx > 0)
                    {
                        String entriesPart = content.substring(entriesIdx);
                        long entries = entriesPart.chars().filter(c -> c == '{').count() - 1; // subtract the outer object
                        count += (int) Math.max(0, entries);
                    }
                }
                catch (IOException ignored) {}
            }
        }
        catch (IOException e)
        {
            System.out.println("[VocabularyTrainingLoader] Failed to scan strips: " + e.getMessage());
        }

        if (count > 0)
            System.out.println("[VocabularyTrainingLoader] Loaded " + count + " training strip entries");
        return count;
    }

    /**
     * Loads preference (chosen/rejected) JSON files.
     */
    private static int loadPreferenceFiles(String dirStr)
    {
        Path dir = Path.of(dirStr);
        if (!Files.isDirectory(dir)) return 0;

        int count = 0;
        try (Stream<Path> files = Files.list(dir))
        {
            List<Path> vocabFiles = files
                .filter(p -> p.getFileName().toString().startsWith("vocabulary."))
                .filter(p -> p.toString().endsWith(".json"))
                .toList();

            for (Path json : vocabFiles)
            {
                try
                {
                    String content = Files.readString(json);
                    // Count preference entries (look for "preference" key occurrences)
                    int idx = 0;
                    while ((idx = content.indexOf("\"preference\"", idx)) >= 0)
                    {
                        count++;
                        idx++;
                    }
                }
                catch (IOException ignored) {}
            }
        }
        catch (IOException e)
        {
            System.out.println("[VocabularyTrainingLoader] Failed to scan preferences: " + e.getMessage());
        }

        if (count > 0)
            System.out.println("[VocabularyTrainingLoader] Loaded " + count + " preference entries");
        return count;
    }

    /**
     * Returns loading status string for system status display.
     */
    public static String status()
    {
        if (!loaded) return "NOT_LOADED";
        return "LOADED|pairs=" + totalPairsLoaded + "|strips=" + totalStripsLoaded + "|map=" + totalMapEntries;
    }
}
