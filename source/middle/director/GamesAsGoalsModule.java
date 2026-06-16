package middle.director;

/** Gamified goal tracking and achievement synchronization. */
public class GamesAsGoalsModule implements DirectorModule
{
    @Override public String name() { return "GamesAsGoals"; }

    @Override
    public String process(String input)
    {
        return "[GameGoal] " + input;
    }

    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat)
    {
        recordTrade("game", nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);
        return "[GameGoal] " + input;
    }
}
