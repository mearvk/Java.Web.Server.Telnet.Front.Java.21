package red.Futures.source.pro.national;

import java.util.concurrent.CompletableFuture;

/**
 * LearningAccumulator — Every connection outcome teaches the AI using handle().
 * Success or dismiss, the AI learns from geo + IQ + outcome.
 * Now includes safety score and linear/exponential counsel.
 */
public class LearningAccumulator
{
    public record Lesson(String ip, String geo, int iq, double safetyScore,
                         double linearCounsel, double expCounsel, String outcome) {}

    private final java.util.List<Lesson> lessons = new java.util.concurrent.CopyOnWriteArrayList<>();

    public <T> CompletableFuture<Lesson> accumulate(CompletableFuture<T> pipeline,
                                                     String ip, String geo, int iq, double safetyScore)
    {
        return pipeline.handle((result, ex) ->
        {
            String outcome = (ex == null) ? "SERVED" : "DISMISSED:" + ex.getMessage();
            double linear = safetyScore / 100.0;
            double exp = Math.exp(safetyScore / 20.0) / Math.exp(5.0);
            Lesson lesson = new Lesson(ip, geo, iq, safetyScore, linear, exp, outcome);
            lessons.add(lesson);
            return lesson;
        });
    }

    public java.util.List<Lesson> getLessons() { return lessons; }
}
