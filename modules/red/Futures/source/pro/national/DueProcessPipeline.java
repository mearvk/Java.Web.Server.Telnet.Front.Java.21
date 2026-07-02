package red.Futures.source.pro.national;

import java.util.concurrent.CompletableFuture;
import java.util.function.Function;

/**
 * DueProcessPipeline — Sequential verification stages using thenCompose().
 * No step is skipped. Each stage depends on the prior result.
 */
public class DueProcessPipeline
{
    public <T> CompletableFuture<T> process(CompletableFuture<T> input,
                                            Function<T, CompletableFuture<T>>... stages)
    {
        CompletableFuture<T> pipeline = input;
        for (Function<T, CompletableFuture<T>> stage : stages)
            pipeline = pipeline.thenCompose(stage);
        return pipeline;
    }
}
