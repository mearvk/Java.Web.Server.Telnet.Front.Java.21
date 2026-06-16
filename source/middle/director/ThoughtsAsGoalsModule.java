package middle.director;

/** Converts thought patterns into actionable finance goals. */
public class ThoughtsAsGoalsModule implements DirectorModule
{
    @Override public String name() { return "ThoughtsAsGoals"; }

    @Override
    public String process(String input)
    {
        return "[ThoughtGoal] " + input;
    }

    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat,
                                   int trustLevel, String educationLevel)
    {
        recordTrade("thought", nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);
        return evaluateAndProcess(input, "thought", nationalId, trustLevel, educationLevel);
    }
}
