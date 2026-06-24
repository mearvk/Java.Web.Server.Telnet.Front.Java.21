package city_analysis;

import city_analysis.CitySpeculationTrainer;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.*;

/**
 * @author Max Rupplin
 *
 * @date June 23 2026
 *
 * CitySpeculationEngine — AI inference module that reads .data, .xml, or .txt
 * input files, applies heuristic reasoning, and writes speculation results
 * to source/city-analysis/speculations/
 */
public class CitySpeculationEngine
{
    protected String hash = "0xCA717018470E914A";

    protected static final String OUTPUT_DIR = "source/city-analysis/speculations/";

    protected List<String> inputLines = new ArrayList<>();
    protected String inputFileName;
    protected Map<String, List<String>> extractedEntities = new HashMap<>();
    protected List<String> speculations = new ArrayList<>();
    protected CitySpeculationTrainer trainer;

    public CitySpeculationEngine(String inputPath)
    {
        this.inputFileName = Paths.get(inputPath).getFileName().toString();
        this.trainer = new CitySpeculationTrainer();
        loadInput(inputPath);
    }

    /**
     * Load input file (.data, .xml, or .txt)
     */
    protected void loadInput(String path)
    {
        try
        {
            inputLines = Files.readAllLines(Paths.get(path));
            System.out.println("-- : [CitySpeculationEngine] Loaded " + inputLines.size() + " lines from " + path);
            extractEntities();
        }
        catch (Exception e)
        {
            System.err.println("-- : [CitySpeculationEngine] Failed to load input: " + e.getMessage());
        }
    }

    /**
     * Extract named entities: numbers, dollar amounts, names, URLs, percentages
     */
    protected void extractEntities()
    {
        extractedEntities.put("dollar-amounts", new ArrayList<>());
        extractedEntities.put("percentages", new ArrayList<>());
        extractedEntities.put("names", new ArrayList<>());
        extractedEntities.put("urls", new ArrayList<>());
        extractedEntities.put("numbers", new ArrayList<>());
        extractedEntities.put("keywords", new ArrayList<>());

        Pattern dollarPattern = Pattern.compile("\\$[\\d,]+\\.?\\d*");
        Pattern percentPattern = Pattern.compile("\\d+\\.?\\d*\\s*%");
        Pattern urlPattern = Pattern.compile("https?://[^\\s<>\"]+");
        Pattern numberPattern = Pattern.compile("\\b\\d{3,}\\b");

        String[] keywordSet = {"mortgage", "deed", "lender", "bank", "property", "sale", "transfer",
                "trust", "llc", "inc", "corp", "investment", "residential", "commercial",
                "foreclosure", "refinance", "equity", "loan", "interest", "principal"};

        for (String line : inputLines)
        {
            Matcher m = dollarPattern.matcher(line);
            while (m.find()) extractedEntities.get("dollar-amounts").add(m.group());

            m = percentPattern.matcher(line);
            while (m.find()) extractedEntities.get("percentages").add(m.group());

            m = urlPattern.matcher(line);
            while (m.find()) extractedEntities.get("urls").add(m.group());

            m = numberPattern.matcher(line);
            while (m.find()) extractedEntities.get("numbers").add(m.group());

            for (String kw : keywordSet)
            {
                if (line.toLowerCase().contains(kw))
                {
                    extractedEntities.get("keywords").add(kw + " [line: " + (inputLines.indexOf(line) + 1) + "]");
                }
            }
        }

        System.out.println("-- : [CitySpeculationEngine] Extracted entities — dollars:" +
                extractedEntities.get("dollar-amounts").size() +
                " percents:" + extractedEntities.get("percentages").size() +
                " keywords:" + extractedEntities.get("keywords").size());
    }

    /**
     * Run speculation — heuristic inference on extracted data
     */
    public void speculate()
    {
        // Train before speculating
        trainer.train();
        double confidence = trainer.getSpeculationConfidence();

        speculations.clear();

        speculations.add("=== SPECULATION REPORT ===");
        speculations.add("Input: " + inputFileName);
        speculations.add("Generated: " + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        speculations.add("Lines analyzed: " + inputLines.size());
        speculations.add("Trainer confidence: " + String.format("%.4f", confidence));
        speculations.add("Spatial weights: " + Arrays.toString(trainer.getSpatialWeights()));
        speculations.add("");

        // Financial pattern speculation
        List<String> dollars = extractedEntities.get("dollar-amounts");
        if (!dollars.isEmpty())
        {
            speculations.add("--- FINANCIAL OBSERVATIONS ---");
            speculations.add("Dollar amounts found: " + dollars.size());
            double total = dollars.stream()
                    .mapToDouble(s -> parseAmount(s))
                    .sum();
            double avg = total / dollars.size();
            speculations.add("Total value referenced: $" + String.format("%,.2f", total));
            speculations.add("Average value: $" + String.format("%,.2f", avg));
            speculations.add("");
            speculations.add("Speculation: Market activity level is " + (total > 10_000_000 ? "HIGH" : total > 1_000_000 ? "MODERATE" : "LOW"));
            speculations.add("Speculation: Average transaction size suggests " + (avg > 500_000 ? "commercial/institutional" : avg > 200_000 ? "residential mid-market" : "residential entry-level") + " activity");
            speculations.add("");
        }

        // Keyword density speculation
        List<String> keywords = extractedEntities.get("keywords");
        if (!keywords.isEmpty())
        {
            speculations.add("--- KEYWORD DENSITY ANALYSIS ---");
            Map<String, Integer> freq = new HashMap<>();
            for (String kw : keywords)
            {
                String word = kw.split(" \\[")[0];
                freq.merge(word, 1, Integer::sum);
            }
            freq.entrySet().stream()
                    .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                    .forEach(e -> speculations.add("  " + e.getKey() + ": " + e.getValue() + " occurrences"));
            speculations.add("");

            String topKeyword = freq.entrySet().stream()
                    .max(Map.Entry.comparingByValue())
                    .map(Map.Entry::getKey).orElse("unknown");
            speculations.add("Speculation: Primary market focus is '" + topKeyword + "'");
            speculations.add("Speculation: Data source likely relates to " + inferDomain(topKeyword));
            speculations.add("");
        }

        // Rate/percentage speculation
        List<String> percents = extractedEntities.get("percentages");
        if (!percents.isEmpty())
        {
            speculations.add("--- RATE OBSERVATIONS ---");
            speculations.add("Percentage values found: " + percents.size());
            OptionalDouble avgRate = percents.stream()
                    .mapToDouble(s -> Double.parseDouble(s.replace("%", "").trim()))
                    .average();
            if (avgRate.isPresent())
            {
                speculations.add("Average rate: " + String.format("%.2f", avgRate.getAsDouble()) + "%");
                speculations.add("Speculation: " + (avgRate.getAsDouble() > 7 ? "High-rate environment; possible subprime or risk-adjusted lending" : "Standard rate environment; conventional lending likely"));
            }
            speculations.add("");
        }

        // Volume speculation
        if (inputLines.size() > 1000)
        {
            speculations.add("--- VOLUME SPECULATION ---");
            speculations.add("Speculation: Large dataset (" + inputLines.size() + " lines) suggests institutional-grade data source");
            speculations.add("Speculation: Likely sourced from county records system or bulk export");
            speculations.add("");
        }

        // Moral/community inference
        speculations.add("--- COMMUNITY INFERENCE ---");
        speculations.add("Baseline presumption: Most participants are good-faith actors (per legalice.presumes.xml)");
        speculations.add("Speculation: Data patterns consistent with normal market behavior unless flagged otherwise");
        speculations.add("");

        System.out.println("-- : [CitySpeculationEngine] Generated " + speculations.size() + " speculation lines");
    }

    /**
     * Recursively speculate on own findings (1-3 passes per config)
     */
    public void speculateRecursively()
    {
        speculate();

        int maxPasses = 3;
        int minPasses = 1;
        double confidenceThreshold = 0.6;

        // Read recursive config from trainer's config
        try
        {
            javax.xml.parsers.DocumentBuilder builder = javax.xml.parsers.DocumentBuilderFactory.newInstance().newDocumentBuilder();
            org.w3c.dom.Document doc = builder.parse(new File("source/city-analysis/cse-allowance-config.xml"));
            org.w3c.dom.NodeList nodes = doc.getElementsByTagName("recursive-speculation");
            if (nodes.getLength() > 0)
            {
                org.w3c.dom.Element el = (org.w3c.dom.Element) nodes.item(0);
                maxPasses = Integer.parseInt(el.getElementsByTagName("max-passes").item(0).getTextContent().trim());
                minPasses = Integer.parseInt(el.getElementsByTagName("min-passes").item(0).getTextContent().trim());
                confidenceThreshold = Double.parseDouble(el.getElementsByTagName("confidence-threshold").item(0).getTextContent().trim());
            }
        }
        catch (Exception e) { /* use defaults */ }

        for (int pass = 1; pass <= maxPasses; pass++)
        {
            if (pass > minPasses && trainer.getSpeculationConfidence() < confidenceThreshold)
            {
                speculations.add("--- RECURSIVE PASS " + pass + " SKIPPED (confidence below " + confidenceThreshold + ") ---");
                break;
            }

            speculations.add("");
            speculations.add("=== RECURSIVE SPECULATION PASS " + pass + " ===");
            speculations.add("Re-analyzing " + speculations.size() + " prior speculation lines...");

            // Count assertion density
            long assertionCount = speculations.stream().filter(s -> s.startsWith("Speculation:")).count();
            speculations.add("Prior assertions: " + assertionCount);

            // Meta-speculation on own confidence
            double conf = trainer.getSpeculationConfidence();
            speculations.add("Current model confidence: " + String.format("%.4f", conf));

            if (conf > 0.8)
                speculations.add("Speculation: High confidence — findings likely reflect ground truth");
            else if (conf > 0.5)
                speculations.add("Speculation: Moderate confidence — findings directionally correct but may have gaps");
            else
                speculations.add("Speculation: Low confidence — findings are tentative and require additional data");

            // Pattern reinforcement from own keywords
            long financialMentions = speculations.stream().filter(s -> s.toLowerCase().contains("market") || s.toLowerCase().contains("lending")).count();
            if (financialMentions > 3)
                speculations.add("Speculation: Repeated financial patterns reinforce lending-sector hypothesis");

            long moralMentions = speculations.stream().filter(s -> s.toLowerCase().contains("moral") || s.toLowerCase().contains("good-faith")).count();
            if (moralMentions > 1)
                speculations.add("Speculation: Moral baseline holds — no adversarial signals detected in data");

            speculations.add("Recursive pass " + pass + " complete.");

            // Write each recursive pass to its own datetime subfolder
            writeRecursivePass(pass, new ArrayList<>(speculations));
        }

        System.out.println("-- : [CitySpeculationEngine] Recursive speculation complete. Total lines: " + speculations.size());
    }

    protected static final String RECURSIVE_OUTPUT_DIR = "source/city-analysis/speculations/recursive/";

    /**
     * Write a recursive speculation pass to its own date/time subfolder
     */
    protected void writeRecursivePass(int pass, List<String> passContent)
    {
        try
        {
            String dateFolder = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd/HH-mm-ss"));
            Path outDir = Paths.get(RECURSIVE_OUTPUT_DIR, dateFolder);
            Files.createDirectories(outDir);

            String outName = inputFileName.replaceAll("\\.(data|xml|txt)$", "") + ".recursive-pass-" + pass + ".txt";
            Path outPath = outDir.resolve(outName);
            Files.write(outPath, passContent);
            System.out.println("-- : [CitySpeculationEngine] Recursive pass " + pass + " written to " + outPath);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CitySpeculationEngine] Failed to write recursive pass " + pass + ": " + e.getMessage());
        }
    }

    /**
     * Write speculation results to output directory
     */
    public void writeResults()
    {
        try
        {
            Files.createDirectories(Paths.get(OUTPUT_DIR));
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
            String outName = inputFileName.replaceAll("\\.(data|xml|txt)$", "") + ".speculation." + timestamp + ".txt";
            Path outPath = Paths.get(OUTPUT_DIR, outName);

            Files.write(outPath, speculations);
            System.out.println("-- : [CitySpeculationEngine] Results written to " + outPath);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CitySpeculationEngine] Failed to write results: " + e.getMessage());
        }
    }

    protected double parseAmount(String s)
    {
        try { return Double.parseDouble(s.replace("$", "").replace(",", "")); }
        catch (Exception e) { return 0.0; }
    }

    protected String inferDomain(String keyword)
    {
        return switch (keyword)
        {
            case "mortgage", "loan", "refinance" -> "lending/mortgage sector";
            case "deed", "transfer", "sale" -> "real estate transactions";
            case "bank", "lender" -> "financial institutions";
            case "foreclosure" -> "distressed property market";
            case "investment", "equity" -> "investment activity";
            default -> "general real estate market";
        };
    }

    public static void main(String[] args)
    {
        if (args.length == 0)
        {
            System.out.println("Usage: java CitySpeculationEngine <input.data|.xml|.txt>");
            return;
        }

        CitySpeculationEngine engine = new CitySpeculationEngine(args[0]);
        engine.speculateRecursively();
        engine.writeResults();
    }
}
