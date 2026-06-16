package middle.director;

/** Medium-range goal synchronization across regional nodes. */
public class MediumHopsModule implements DirectorModule
{
    @Override public String name() { return "MediumHops"; }

    @Override
    public String process(String input)
    {
        return "[MediumHop] " + input;
    }

    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat,
                                   int trustLevel, String educationLevel)
    {
        recordTrade("medium", nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);
        return evaluateAndProcess(input, "medium", nationalId, trustLevel, educationLevel);
    }
}
