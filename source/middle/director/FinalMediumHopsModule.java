package middle.director;

/** Final medium-range hops before national module delivery. */
public class FinalMediumHopsModule implements DirectorModule
{
    @Override public String name() { return "FinalMediumHops"; }

    @Override
    public String process(String input)
    {
        return "[FinalMediumHop] " + input;
    }

    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat,
                                   int trustLevel, String educationLevel)
    {
        recordTrade("finalmedium", nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);
        return evaluateAndProcess(input, "finalmedium", nationalId, trustLevel, educationLevel);
    }
}
