package middle.director;

/** Auditor content verification and goal compliance. */
public class AuditorContentModule implements DirectorModule
{
    @Override public String name() { return "AuditorContent"; }

    @Override
    public String process(String input)
    {
        return "[Auditor] " + input;
    }

    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat)
    {
        recordTrade("audit", nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);
        return "[Auditor] " + input;
    }
}
