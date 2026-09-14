package red.Futures.source.ai.trainers;

import ai.djl.Model;
import ai.djl.ndarray.NDArray;
import ai.djl.ndarray.NDManager;
import ai.djl.ndarray.types.Shape;
import ai.djl.nn.Block;
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
 * TaxClosureTrainer — trains the TaxDefenseSpeculator model
 * on historical INT closure data.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class TaxClosureTrainer
{
    private final int epochs;
    private final int batchSize;

    public TaxClosureTrainer(int epochs, int batchSize)
    {
        this.epochs = epochs;
        this.batchSize = batchSize;
    }

    public void train(float[][] features, float[][] labels) throws Exception
    {
        Model model = Model.newInstance("int-tax-defense-speculator", "PyTorch");
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
                    .optLearningRateTracker(Tracker.fixed(0.001f))
                    .build())
                .addTrainingListeners(TrainingListener.Defaults.logging());

            try (Trainer trainer = model.newTrainer(config))
            {
                trainer.initialize(new Shape(batchSize, 8));
                EasyTrain.fit(trainer, epochs, dataset, null);
            }

            model.save(Paths.get("models/tax-defense"), "int-tax-defense-speculator");
        }
        finally
        {
            model.close();
        }
    }
}
