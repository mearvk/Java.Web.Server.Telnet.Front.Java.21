package middle.director;

/**
 * StrategicGoalsModule — initial games goals module for the Middle Director.
 *
 * Strategic goals (linear posits):
 *   1. IQ — raw intelligence measurement and initiative scoring
 *   2. Initiatives — state and national initiative tracking
 *   3. Total IQ Wealth — aggregate intelligence capital across participants
 *   4. State Initiatives for Savings — fiscal/moral savings programs
 *   5. Main Money — presidential real-stats counting, post-evaluation
 *   6. Feeling Good Natures — feelings, well-being, morale index
 *
 * IQ and Integrity are weighted highest (pre-specific base training applies).
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 */
public class StrategicGoalsModule implements DirectorModule
{
    private int iqBaseline = 100;
    private double totalIqWealth = 0.0;
    private double stateSavingsIndex = 0.0;
    private double mainMoneyIndex = 0.0;
    private double feelingGoodIndex = 0.0;

    @Override public String name() { return "StrategicGoals"; }

    @Override
    public String process(String input)
    {
        String cmd = input.trim().toLowerCase();

        if (cmd.startsWith("iq"))
            return processIQ(input);
        if (cmd.startsWith("initiative"))
            return processInitiative(input);
        if (cmd.startsWith("wealth"))
            return processIqWealth(input);
        if (cmd.startsWith("savings"))
            return processSavings(input);
        if (cmd.startsWith("money") || cmd.startsWith("president"))
            return processMainMoney(input);
        if (cmd.startsWith("feeling") || cmd.startsWith("morale"))
            return processFeelings(input);

        return "[StrategicGoals] " + input;
    }

    private String processIQ(String input)
    {
        return "[StrategicGoals:IQ] baseline=" + iqBaseline + " | " + input;
    }

    private String processInitiative(String input)
    {
        return "[StrategicGoals:Initiative] state+national active | " + input;
    }

    private String processIqWealth(String input)
    {
        return "[StrategicGoals:TotalIQWealth] aggregate=" + totalIqWealth + " | " + input;
    }

    private String processSavings(String input)
    {
        return "[StrategicGoals:StateSavings] index=" + stateSavingsIndex + " | " + input;
    }

    private String processMainMoney(String input)
    {
        return "[StrategicGoals:MainMoney] presidents-real-stats index=" + mainMoneyIndex + " | " + input;
    }

    private String processFeelings(String input)
    {
        return "[StrategicGoals:FeelingGood] morale=" + feelingGoodIndex + " | " + input;
    }

    public void updateIqWealth(double delta) { totalIqWealth += delta; }
    public void updateSavings(double delta) { stateSavingsIndex += delta; }
    public void updateMainMoney(double delta) { mainMoneyIndex += delta; }
    public void updateFeelings(double delta) { feelingGoodIndex += delta; }
    public double getTotalIqWealth() { return totalIqWealth; }
    public double getFeelingsIndex() { return feelingGoodIndex; }
}
