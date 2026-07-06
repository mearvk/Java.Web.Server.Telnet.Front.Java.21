package red.Futures.source.ai.training;

import ai.djl.Model;
import ai.djl.ndarray.NDArray;
import ai.djl.ndarray.NDManager;
import ai.djl.ndarray.types.Shape;
import ai.djl.nn.Activation;
import ai.djl.nn.SequentialBlock;
import ai.djl.nn.core.Linear;
import ai.djl.training.DefaultTrainingConfig;
import ai.djl.training.EasyTrain;
import ai.djl.training.Trainer;
import ai.djl.training.dataset.ArrayDataset;
import ai.djl.training.listener.TrainingListener;
import ai.djl.training.loss.Loss;
import ai.djl.training.optimizer.Optimizer;
import ai.djl.training.tracker.Tracker;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;
import java.util.stream.Collectors;

/**
 * ConfigurationTrainer — trains the AI modules on all JSON files
 * found in /configuration/training/ and saves resulting weight files
 * to /training/weights/.
 *
 * Encodes JSON training data into feature vectors via text hashing
 * and statistical properties, then trains a neural network that
 * learns patterns across the entire training corpus.
 *
 * Produces three weight files:
 * - knowledge-model (general knowledge from mearvk/large.scale files)
 * - ethics-model (from black.belt ethical audit files)
 * - preference-model (from vocabulary.satisfaction preference files)
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class ConfigurationTrainer
{
    private static final Path TRAINING_INPUT_DIR = Paths.get("configuration/training");
    private static final Path WEIGHTS_OUTPUT_DIR = Paths.get("training/weights");

    private static final int FEATURE_DIM = 16;
    private static final int HIDDEN_1 = 64;
    private static final int HIDDEN_2 = 32;
    private static final int OUTPUT_DIM = 8;
    private static final int EPOCHS = 50;
    private static final int BATCH_SIZE = 4;
    private static final float LEARNING_RATE = 0.001f;

    private final boolean persistToMySQL;
    private final String trainModule; // null = all, "blackbelt" = ethics only, "democratic" = knowledge+preference

    public ConfigurationTrainer()
    {
        this.persistToMySQL = shouldPersistToMySQL();
        this.trainModule = System.getProperty("train.module"); // null, "blackbelt", or "democratic"
    }

    public static void main(String[] args) throws Exception
    {
        ConfigurationTrainer trainer = new ConfigurationTrainer();
        trainer.trainAll();
    }

    private boolean shouldPersistToMySQL()
    {
        try
        {
            Path configFile = Paths.get("configuration/ai-module-config.xml");
            if (Files.exists(configFile))
            {
                String xml = Files.readString(configFile);
                return xml.contains("<save-weights-to-mysql>true</save-weights-to-mysql>");
            }
        }
        catch (IOException e) { /* default false */ }
        return false;
    }

    /**
     * Scans /configuration/training/ for all JSON files, categorizes them,
     * trains separate models, and saves weights to /training/weights/.
     * Respects train.module system property and save-weights-to-mysql config.
     */
    public void trainAll() throws Exception
    {
        Files.createDirectories(WEIGHTS_OUTPUT_DIR);

        WeightPersistence wp = persistToMySQL ? new WeightPersistence() : null;
        long sessionId = wp != null ? wp.recordSessionStart(trainModule != null ? trainModule : "all") : -1;
        int modelsTrained = 0;

        List<Path> allJsonFiles = Files.walk(TRAINING_INPUT_DIR)
            .filter(p -> Files.isRegularFile(p) && p.toString().endsWith(".json"))
            .filter(p -> !p.toString().contains("/weights/"))
            .collect(Collectors.toList());

        System.out.println("[ConfigurationTrainer] Found " + allJsonFiles.size() + " JSON training files.");

        // Categorize files by prefix
        List<Path> knowledgeFiles = new ArrayList<>();
        List<Path> ethicsFiles = new ArrayList<>();
        List<Path> preferenceFiles = new ArrayList<>();

        for (Path file : allJsonFiles)
        {
            String name = file.getFileName().toString().toLowerCase();
            if (name.startsWith("black.belt"))
                ethicsFiles.add(file);
            else if (name.startsWith("vocabulary") || name.contains("satisfaction"))
                preferenceFiles.add(file);
            else
                knowledgeFiles.add(file);
        }

        System.out.println("[ConfigurationTrainer] Knowledge files: " + knowledgeFiles.size());
        System.out.println("[ConfigurationTrainer] Ethics files: " + ethicsFiles.size());
        System.out.println("[ConfigurationTrainer] Preference files: " + preferenceFiles.size());

        // Train each category (filtered by module if specified)
        boolean trainDemocratic = trainModule == null || "democratic".equals(trainModule);
        boolean trainBlackbelt = trainModule == null || "blackbelt".equals(trainModule);

        if (trainDemocratic && !knowledgeFiles.isEmpty())
        {
            trainModel("knowledge-model", knowledgeFiles);
            if (wp != null) wp.saveWeights("knowledge-model", "democratic", WEIGHTS_OUTPUT_DIR.resolve("knowledge-model"),
                knowledgeFiles.stream().map(p -> p.getFileName().toString()).collect(Collectors.joining(",")), knowledgeFiles.size(), EPOCHS);
            modelsTrained++;
        }

        if (trainBlackbelt && !ethicsFiles.isEmpty())
        {
            trainModel("ethics-model", ethicsFiles);
            if (wp != null) wp.saveWeights("ethics-model", "blackbelt", WEIGHTS_OUTPUT_DIR.resolve("ethics-model"),
                ethicsFiles.stream().map(p -> p.getFileName().toString()).collect(Collectors.joining(",")), ethicsFiles.size(), EPOCHS);
            modelsTrained++;
        }

        if (trainDemocratic && !preferenceFiles.isEmpty())
        {
            trainModel("preference-model", preferenceFiles);
            if (wp != null) wp.saveWeights("preference-model", "democratic", WEIGHTS_OUTPUT_DIR.resolve("preference-model"),
                preferenceFiles.stream().map(p -> p.getFileName().toString()).collect(Collectors.joining(",")), preferenceFiles.size(), EPOCHS);
            modelsTrained++;
        }

        if (wp != null) wp.recordSessionEnd(sessionId, modelsTrained, "complete");

        System.out.println("[ConfigurationTrainer] All training complete. Weights saved to: " + WEIGHTS_OUTPUT_DIR);
        if (persistToMySQL) System.out.println("[ConfigurationTrainer] Weights persisted to MySQL (model_weights table).");
    }

    /**
     * Trains a single model on a set of JSON files and saves weights.
     */
    private void trainModel(String modelName, List<Path> files) throws Exception
    {
        System.out.println("[ConfigurationTrainer] Training " + modelName + " on " + files.size() + " files...");

        // Encode all files into feature vectors
        float[][] features = new float[files.size()][FEATURE_DIM];
        float[][] labels = new float[files.size()][OUTPUT_DIM];

        for (int i = 0; i < files.size(); i++)
        {
            String content = Files.readString(files.get(i), StandardCharsets.UTF_8);
            features[i] = encodeFeatures(content, files.get(i).getFileName().toString());
            labels[i] = encodeLabels(content, files.get(i).getFileName().toString());
        }

        // Build model
        Model model = Model.newInstance(modelName, "PyTorch");
        SequentialBlock block = new SequentialBlock();
        block.add(Linear.builder().setUnits(HIDDEN_1).build());
        block.add(Activation::relu);
        block.add(Linear.builder().setUnits(HIDDEN_2).build());
        block.add(Activation::relu);
        block.add(Linear.builder().setUnits(OUTPUT_DIM).build());
        model.setBlock(block);

        try (NDManager manager = NDManager.newBaseManager())
        {
            NDArray featureArray = manager.create(features);
            NDArray labelArray = manager.create(labels);

            int effectiveBatch = Math.min(BATCH_SIZE, files.size());

            ArrayDataset dataset = new ArrayDataset.Builder()
                .setData(featureArray)
                .optLabels(labelArray)
                .setSampling(effectiveBatch, true)
                .build();

            DefaultTrainingConfig config = new DefaultTrainingConfig(Loss.l2Loss())
                .optOptimizer(Optimizer.adam()
                    .optLearningRateTracker(Tracker.fixed(LEARNING_RATE))
                    .build())
                .addTrainingListeners(TrainingListener.Defaults.logging());

            try (Trainer trainer = model.newTrainer(config))
            {
                trainer.initialize(new Shape(effectiveBatch, FEATURE_DIM));
                EasyTrain.fit(trainer, EPOCHS, dataset, null);
            }

            Path outputPath = WEIGHTS_OUTPUT_DIR.resolve(modelName);
            Files.createDirectories(outputPath);
            model.save(outputPath, modelName);
            System.out.println("[ConfigurationTrainer] Saved: " + outputPath + "/" + modelName);
        }
        finally
        {
            model.close();
        }
    }

    /**
     * Encodes JSON content into a fixed-size feature vector.
     * Uses text statistics and hash-based features.
     */
    private float[] encodeFeatures(String content, String filename)
    {
        float[] features = new float[FEATURE_DIM];

        // Feature 0: content length (normalized)
        features[0] = Math.min(content.length() / 10000.0f, 1.0f);

        // Feature 1: number of JSON keys (approximate by counting quotes)
        long quoteCount = content.chars().filter(c -> c == '"').count();
        features[1] = Math.min(quoteCount / 200.0f, 1.0f);

        // Feature 2: nesting depth (brace count)
        long braceCount = content.chars().filter(c -> c == '{' || c == '[').count();
        features[2] = Math.min(braceCount / 50.0f, 1.0f);

        // Feature 3: average word length
        String[] words = content.split("\\s+");
        double avgLen = Arrays.stream(words).mapToInt(String::length).average().orElse(0);
        features[3] = (float) Math.min(avgLen / 20.0, 1.0);

        // Feature 4: vocabulary richness (unique words / total words)
        Set<String> unique = new HashSet<>(Arrays.asList(words));
        features[4] = words.length > 0 ? Math.min((float) unique.size() / words.length, 1.0f) : 0;

        // Feature 5: numeric content ratio
        long digits = content.chars().filter(Character::isDigit).count();
        features[5] = Math.min((float) digits / content.length(), 1.0f);

        // Feature 6: uppercase ratio (indicates formal/structured content)
        long upper = content.chars().filter(Character::isUpperCase).count();
        features[6] = Math.min((float) upper / content.length(), 1.0f);

        // Features 7-15: SHA-256 hash buckets of content for stable encoding
        try
        {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(content.getBytes(StandardCharsets.UTF_8));
            for (int i = 0; i < 9 && i < hash.length; i++)
                features[7 + i] = (hash[i] & 0xFF) / 255.0f;
        }
        catch (Exception e) { /* leave as zeros */ }

        return features;
    }

    /**
     * Encodes target labels based on content type and quality indicators.
     */
    private float[] encodeLabels(String content, String filename)
    {
        float[] labels = new float[OUTPUT_DIM];
        String lower = content.toLowerCase();

        // Label 0: ethical alignment (high if ethics-related content)
        labels[0] = lower.contains("conduct") || lower.contains("ethical") ? 0.9f : 0.3f;

        // Label 1: knowledge density (based on output/instruction presence)
        labels[1] = lower.contains("output") || lower.contains("instruction") ? 0.8f : 0.4f;

        // Label 2: preference clarity (high if chosen/rejected structure)
        labels[2] = lower.contains("chosen") && lower.contains("rejected") ? 0.9f : 0.2f;

        // Label 3: risk assessment capability
        labels[3] = lower.contains("risk") || lower.contains("score") ? 0.85f : 0.25f;

        // Label 4: legal/authority knowledge
        labels[4] = lower.contains("law") || lower.contains("jurisdiction") || lower.contains("tax") ? 0.8f : 0.2f;

        // Label 5: defensive posture (from BlackBelt/military content)
        labels[5] = lower.contains("defense") || lower.contains("hostile") || lower.contains("conduct_score") ? 0.85f : 0.15f;

        // Label 6: democratic values
        labels[6] = lower.contains("democratic") || lower.contains("consent") || lower.contains("equal") ? 0.9f : 0.3f;

        // Label 7: communication quality
        labels[7] = lower.contains("explain") || lower.contains("clearly") || lower.contains("accurate") ? 0.85f : 0.35f;

        return labels;
    }
}
