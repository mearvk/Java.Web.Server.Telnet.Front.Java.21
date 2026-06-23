/**
 * StrernaryTrainingLoader — Loads TSV training data from /training directory
 * into the nwe_strernary knowledge_base and training_pairs tables.
 *
 * Called at startup to ensure the AI has baseline knowledge.
 * Format: input\toutput\tsource (tab-separated)
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package strernary;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.nio.file.*;
import java.util.stream.Stream;

public class StrernaryTrainingLoader
{
    private final StrernaryKnowledgeFetcher fetcher;

    public StrernaryTrainingLoader(StrernaryKnowledgeFetcher fetcher)
    {
        this.fetcher = fetcher;
    }

    /**
     * Loads all TSV files from training/ subdirectories into the knowledge base.
     */
    public int loadAll()
    {
        int total = 0;
        Path trainingDir = Path.of("training");
        if (!Files.exists(trainingDir)) return 0;

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary\u2122 loading training data from /training .");

        try (Stream<Path> files = Files.walk(trainingDir))
        {
            var tsvFiles = files.filter(p -> p.toString().endsWith(".tsv")).toList();
            for (Path tsv : tsvFiles)
            {
                total += loadTsv(tsv);
            }
        }
        catch (IOException e) { ExceptionHandler.dispatch(e); }

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary\u2122 training data loaded: " + total + " pairs .");

        // Save model state after loading
        if (fetcher != null && total > 0)
        {
            fetcher.saveModelState("training_baseline_v1",
                ("pairs=" + total).getBytes(), "tsv_loaded", total);
        }

        return total;
    }

    private int loadTsv(Path file)
    {
        int count = 0;
        try (BufferedReader reader = Files.newBufferedReader(file))
        {
            String line;
            while ((line = reader.readLine()) != null)
            {
                String[] parts = line.split("\t", 3);
                if (parts.length < 2) continue;

                String input = parts[0].trim();
                String output = parts[1].trim();
                String source = parts.length > 2 ? parts[2].trim() : file.getFileName().toString();

                if (input.isEmpty() || output.isEmpty()) continue;

                fetcher.store(input, output, source);
                fetcher.storeTrainingPair(input, output, source);
                count++;
            }
        }
        catch (IOException e) { ExceptionHandler.dispatch(e); }
        return count;
    }
}
