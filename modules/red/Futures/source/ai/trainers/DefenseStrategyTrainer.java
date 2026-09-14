package red.Futures.source.ai.trainers;

import ai.djl.Model;
import ai.djl.ndarray.NDArray;
import ai.djl.ndarray.NDManager;
import ai.djl.ndarray.types.Shape;
import ai.djl.nn.SequentialBlock;
import ai.djl.nn.core.Linear;
import ai.djl.nn.Activation;
import ai.djl.training.DefaultTrainingConfig;
import ai.djl.training.EasyTrain;
import ai.djl.training.Trainer;
import ai.djl.training.dataset.ArrayDataset;
import ai.djl.training.listener.TrainingListener;
import ai.djl.training.loss.Loss;
import ai.djl.training.optimizer.Optimizer;
import ai.djl.training.tracker.Tracker;

import java.nio.file.Paths;

/**
 * DefenseStrategyTrainer — trains model on defense strategy outcomes
 * for tax closure proceedings with the US Government.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class DefenseStrategyTrainer
{
    private final int epochs;
    private final int batchSize;
    private final float learningRate;

    public DefenseStrategyTrainer(int epochs, int batchSize, float learningRate)
    {
        this.epochs = epochs;
        this.batchSize = batchSize;
        this.learningRate = learningRate;
    }

    public void train(float[][] features, float[][] labels) throws Exception
    {
        Model model = Model.newInstance("defense-strategy-model", "PyTorch");
        SequentialBlock block = new SequentialBlock();
        block.add(Linear.builder().setUnits(64).build());
        block.add(Activation::relu);
        block.add(Linear.builder().setUnits(32).build());
        block.add(Activation::relu);
        block.add(Linear.builder().setUnits(4).build());
        model.setBlock(block);

        try (NDManager manager = NDManager.newBaseManager())
        {
            NDArray featureArray = manager.create(features);
            NDArray labelArray = manager.create(labels);

            ArrayDataset dataset = new ArrayDataset.Builder()
                .setData(featureArray)
                .optLabels(labelArray)
                .setSampling(batchSize, true)
                .build();

            DefaultTrainingConfig config = new DefaultTrainingConfig(Loss.l2Loss())
                .optOptimizer(Optimizer.adam()
                    .optLearningRateTracker(Tracker.fixed(learningRate))
                    .build())
                .addTrainingListeners(TrainingListener.Defaults.logging());

            try (Trainer trainer = model.newTrainer(config))
            {
                trainer.initialize(new Shape(batchSize, 8));
                EasyTrain.fit(trainer, epochs, dataset, null);
            }

            model.save(Paths.get("models/defense-strategy"), "defense-strategy-model");
        }
        finally
        {
            model.close();
        }
    }
}
