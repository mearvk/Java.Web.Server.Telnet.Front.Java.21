/**
 * DjlInferenceEngine — Deep thinking model for the Java edition port.
 *
 * Uses Deep Java Library (DJL) 0.31.0 with PyTorch engine for local
 * text classification and sentiment inference. This is the "deeper thinking"
 * model behind the Java public port interface on port 20000.
 *
 * Required jars (jars/djl/):
 *   api-0.31.0.jar
 *   basicdataset-0.31.0.jar
 *   model-zoo-0.31.0.jar
 *   pytorch-engine-0.31.0.jar
 *   pytorch-model-zoo-0.31.0.jar
 *   tokenizers-0.31.0.jar
 *   pytorch-native-cpu-2.5.1-linux-x86_64.jar
 *   gson-2.11.0.jar
 *   jna-5.14.0.jar
 *   commons-compress-1.26.1.jar
 *   slf4j-api-2.0.12.jar
 *   slf4j-simple-2.0.12.jar
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package strernary;

import ai.djl.Application;
import ai.djl.MalformedModelException;
import ai.djl.inference.Predictor;
import ai.djl.modality.Classifications;
import ai.djl.repository.zoo.Criteria;
import ai.djl.repository.zoo.ModelNotFoundException;
import ai.djl.repository.zoo.ZooModel;
import ai.djl.training.util.ProgressBar;
import ai.djl.translate.TranslateException;
import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicReference;

public final class DjlInferenceEngine
{
    private static final AtomicReference<ZooModel<String, Classifications>> MODEL_REF = new AtomicReference<>();
    private static volatile boolean initialized = false;
    private static volatile boolean failed = false;

    private DjlInferenceEngine() {}

    /**
     * Performs deep inference on the input text.
     * Loads model lazily on first call. Returns classified best-guess or null on failure.
     *
     * @param input text to analyze
     * @return classified response string, or null if inference unavailable
     * @javaowner Max Rupplin
     */
    public static String infer(String input)
    {
        if (failed) return null;

        try
        {
            if (!initialized) initialize();

            ZooModel<String, Classifications> model = MODEL_REF.get();
            if (model == null) return null;

            try (Predictor<String, Classifications> predictor = model.newPredictor())
            {
                Classifications result = predictor.predict(input);

                // Build response from top classifications
                StringBuilder sb = new StringBuilder("DJL_DEEP|");
                result.topK(3).forEach(item ->
                    sb.append(item.getClassName())
                      .append("=")
                      .append(String.format("%.3f", item.getProbability()))
                      .append("|"));

                return sb.toString();
            }
        }
        catch (TranslateException e)
        {
            ExceptionHandler.dispatch(e);
            return null;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return null;
        }
    }

    /**
     * Lazily initializes the DJL model. Uses sentiment analysis from the
     * PyTorch model zoo. Downloads model weights on first run (~250MB).
     *
     * @javaowner Max Rupplin
     */
    private static synchronized void initialize()
    {
        if (initialized) return;

        try
        {
            CommonRails.printSystemComponent(DjlInferenceEngine.class, 0,
                ". Strernary™ DJL deep inference engine initializing .");

            Criteria<String, Classifications> criteria = Criteria.builder()
                .optApplication(Application.NLP.SENTIMENT_ANALYSIS)
                .setTypes(String.class, Classifications.class)
                .optProgress(new ProgressBar())
                .build();

            ZooModel<String, Classifications> model = criteria.loadModel();
            MODEL_REF.set(model);
            initialized = true;

            CommonRails.printSystemComponent(DjlInferenceEngine.class, 0,
                ". Strernary™ DJL deep inference engine ready .");
        }
        catch (ModelNotFoundException | MalformedModelException | IOException e)
        {
            failed = true;
            ExceptionHandler.dispatch(e);
            CommonRails.printSystemComponent(DjlInferenceEngine.class, 0,
                ". Strernary™ DJL model load failed — heuristic fallback active .",
                commons.color.ColorPalette.COLOR_STANDARD_RED);
        }
    }

    /**
     * Shuts down and releases model resources.
     *
     * @javaowner Max Rupplin
     */
    public static void shutdown()
    {
        ZooModel<String, Classifications> model = MODEL_REF.getAndSet(null);
        if (model != null) model.close();
        initialized = false;
    }
}
