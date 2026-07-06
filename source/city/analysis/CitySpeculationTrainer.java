package city.analysis;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

/**
 * @author Max Rupplin
 *
 * @date June 23 2026
 *
 * CitySpeculationTrainer — Moral-bound IQ spectrum learner-rate spatial model.
 * Trains on base objections (shyness, cause-aversion, social-distance) with
 * exponential falloff before the speculation engine runs.
 * Driven by cse-allowance-config.xml.
 */
public class CitySpeculationTrainer
{
    protected String hash = "0xCA717018470E914B";

    protected static final String CONFIG_PATH = "source/city/analysis/configuration/cse-allowance-config.xml";

    // Reasoning allowances
    protected long maxReasoningTimeMs;
    protected int maxInputs;
    protected int inputValue;
    protected boolean ageOfTreasonEnabled;
    protected double treasonThreshold;
    protected int maxHeapMb;
    protected int maxWorkingSetEntries;

    // Class importance
    protected double democratClassWeight;
    protected double citizenClassWeight;

    // IQ centralization
    protected int dominantIq;
    protected List<double[]> iqTiers = new ArrayList<>(); // [iqMin, falloff]

    // Trainer params
    protected int epochs;
    protected double learningRate;
    protected double moralBoundWeight;
    protected int dimensions;
    protected String[] dimensionLabels;
    protected String falloffModel;
    protected double spectrumMin;
    protected double spectrumMax;
    protected boolean adaptive;

    // Base objections: [weight, decay, currentValue]
    protected Map<String, double[]> baseObjections = new LinkedHashMap<>();

    // Trained spatial weights
    protected double[] spatialWeights;

    protected boolean trained = false;

    public CitySpeculationTrainer()
    {
        loadConfig();
    }

    protected void loadConfig()
    {
        try
        {
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new File(CONFIG_PATH));
            doc.getDocumentElement().normalize();

            // Reasoning
            maxReasoningTimeMs = Long.parseLong(getTag(doc, "max-reasoning-time-ms"));
            maxInputs = Integer.parseInt(getTag(doc, "max-inputs"));
            inputValue = Integer.parseInt(getTag(doc, "input-value"));
            ageOfTreasonEnabled = "true".equals(((Element) doc.getElementsByTagName("age-of-treason").item(0)).getAttribute("enabled"));
            treasonThreshold = Double.parseDouble(getTag(doc, "threshold"));

            // Memory
            maxHeapMb = Integer.parseInt(getTag(doc, "max-heap-mb"));
            maxWorkingSetEntries = Integer.parseInt(getTag(doc, "max-working-set-entries"));

            // Class importance
            Element demEl = (Element) doc.getElementsByTagName("democrat-class").item(0);
            democratClassWeight = Double.parseDouble(demEl.getAttribute("weight"));
            Element citEl = (Element) doc.getElementsByTagName("citizen-class").item(0);
            citizenClassWeight = Double.parseDouble(citEl.getAttribute("weight"));

            // IQ centralization
            dominantIq = Integer.parseInt(getTag(doc, "dominant-iq"));
            NodeList tierNodes = doc.getElementsByTagName("tier");
            for (int i = 0; i < tierNodes.getLength(); i++)
            {
                Element t = (Element) tierNodes.item(i);
                double iqMin = Double.parseDouble(t.getAttribute("iq-min"));
                double falloff = Double.parseDouble(t.getAttribute("falloff"));
                iqTiers.add(new double[]{iqMin, falloff});
            }

            // Trainer
            epochs = Integer.parseInt(getTag(doc, "epochs"));
            learningRate = Double.parseDouble(getTag(doc, "learning-rate"));
            moralBoundWeight = Double.parseDouble(getTag(doc, "moral-bound-weight"));
            dimensions = Integer.parseInt(getTag(doc, "dimensions"));
            String labels = getTag(doc, "dimension-labels");
            dimensionLabels = (labels != null && !labels.isEmpty()) ? labels.split(",") : new String[dimensions];
            falloffModel = getTag(doc, "falloff-model");
            spectrumMin = Double.parseDouble(getTag(doc, "spectrum-min"));
            spectrumMax = Double.parseDouble(getTag(doc, "spectrum-max"));
            adaptive = "true".equals(getTag(doc, "adaptive"));

            // Base objections
            NodeList objNodes = doc.getElementsByTagName("objection");
            for (int i = 0; i < objNodes.getLength(); i++)
            {
                Element o = (Element) objNodes.item(i);
                String id = o.getAttribute("id");
                double weight = Double.parseDouble(o.getAttribute("weight"));
                double decay = Double.parseDouble(o.getAttribute("decay"));
                baseObjections.put(id, new double[]{weight, decay, weight}); // [initial, decay, current]
            }

            spatialWeights = new double[dimensions];
            Arrays.fill(spatialWeights, 0.5);

            System.out.println("-- : [CitySpeculationTrainer] Config loaded. Epochs:" + epochs + " LR:" + learningRate + " Dimensions:" + dimensions);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CitySpeculationTrainer] Config load failed: " + e.getMessage());
        }
    }

    /**
     * Train the spatial model — moral-bound IQ spectrum with base-objection falloff
     */
    public void train()
    {
        long startTime = System.currentTimeMillis();
        System.out.println("-- : [CitySpeculationTrainer] Training started. Max time: " + maxReasoningTimeMs + "ms");

        double currentLR = learningRate;

        for (int epoch = 0; epoch < epochs; epoch++)
        {
            if (System.currentTimeMillis() - startTime > maxReasoningTimeMs)
            {
                System.out.println("-- : [CitySpeculationTrainer] Time limit reached at epoch " + epoch);
                break;
            }

            // Apply base objection decay (exponential falloff)
            for (Map.Entry<String, double[]> entry : baseObjections.entrySet())
            {
                double[] vals = entry.getValue();
                double initialWeight = vals[0];
                double decay = vals[1];

                if ("exponential".equals(falloffModel))
                {
                    vals[2] = initialWeight * Math.exp(-decay * epoch);
                }
                else
                {
                    vals[2] = initialWeight * (1.0 - (decay * epoch / epochs));
                }
            }

            // Compute aggregate objection pressure
            double objectionPressure = baseObjections.values().stream()
                    .mapToDouble(v -> v[2])
                    .sum();

            // Determine IQ tier falloff for this epoch's reasoning depth
            double tierFalloff = getTierFalloff(dominantIq);

            // Update spatial weights with moral-bound constraint
            for (int d = 0; d < dimensions; d++)
            {
                double gradient = (1.0 - objectionPressure) * (1.0 - tierFalloff) * citizenClassWeight;
                double moralConstraint = moralBoundWeight * (0.5 - spatialWeights[d]);
                spatialWeights[d] += currentLR * (gradient + moralConstraint);
                spatialWeights[d] = Math.max(0.0, Math.min(1.0, spatialWeights[d]));
            }

            // Adaptive learning rate
            if (adaptive)
            {
                currentLR = spectrumMin + (spectrumMax - spectrumMin) * (1.0 - (double) epoch / epochs);
            }
        }

        trained = true;
        long elapsed = System.currentTimeMillis() - startTime;
        StringBuilder weightStr = new StringBuilder("[");
        for (int d = 0; d < dimensions; d++)
        {
            if (d > 0) weightStr.append(", ");
            String label = (dimensionLabels != null && d < dimensionLabels.length && dimensionLabels[d] != null) ? dimensionLabels[d] : "d" + d;
            weightStr.append(label).append("=").append(String.format("%.3f", spatialWeights[d]));
        }
        weightStr.append("]");
        System.out.println("-- : [CitySpeculationTrainer] Training complete in " + elapsed + "ms. Weights: " + weightStr);
    }

    /**
     * Get the falloff factor for a given IQ from the tier table
     */
    protected double getTierFalloff(int iq)
    {
        for (double[] tier : iqTiers)
        {
            if (iq >= tier[0]) return tier[1];
        }
        return 0.85;
    }

    /**
     * Query the trained model — returns a confidence [0,1] for speculation reliability
     */
    public double getSpeculationConfidence()
    {
        if (!trained) return 0.0;
        double avg = Arrays.stream(spatialWeights).average().orElse(0.0);
        double objectionResidual = baseObjections.values().stream().mapToDouble(v -> v[2]).sum();
        return avg * (1.0 - objectionResidual * 0.5);
    }

    public boolean isTrained()
    {
        return trained;
    }

    public double[] getSpatialWeights()
    {
        return spatialWeights;
    }

    public long getMaxReasoningTimeMs()
    {
        return maxReasoningTimeMs;
    }

    public int getMaxInputs()
    {
        return maxInputs;
    }

    public int getInputValue()
    {
        return inputValue;
    }

    protected String getTag(Document doc, String tag)
    {
        NodeList nodes = doc.getElementsByTagName(tag);
        return nodes.getLength() > 0 ? nodes.item(0).getTextContent().trim() : "";
    }

    public static void main(String[] args)
    {
        CitySpeculationTrainer trainer = new CitySpeculationTrainer();
        trainer.train();
        System.out.println("-- : [CitySpeculationTrainer] Speculation confidence: " + String.format("%.4f", trainer.getSpeculationConfidence()));
    }
}
