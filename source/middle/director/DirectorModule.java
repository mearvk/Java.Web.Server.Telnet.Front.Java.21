package middle.director;

/**
 * Base interface for all Middle Director modules.
 * Each module processes finance/goal synchronization content in sequence,
 * evaluates trade direction, and persists records via DirectorPersistence.
 *
 * Trades succeed immediately if upward/better (trust + education grade).
 * Otherwise held 48hrs for auditor review.
 */
public interface DirectorModule
{
    String name();
    String process(String input);

    /** Record a trade with full identity and status fields. */
    default void recordTrade(String tradeType, long nationalId, String ip,
                             String publicKey, long signatoryId, String signatoryKey,
                             boolean employed, boolean democrat)
    {
        DirectorPersistence.saveTrade(name(), tradeType, nationalId, ip,
            publicKey, signatoryId, signatoryKey, employed, democrat);
    }

    /**
     * Evaluate and process a trade. Succeeds if upward/better, else 48hr hold.
     * Returns result string indicating success or hold status.
     */
    default String evaluateAndProcess(String input, String tradeType, long nationalId,
                                      int trustLevel, String educationLevel)
    {
        boolean approved = TradeEvaluator.evaluate(name(), tradeType, nationalId,
            trustLevel, educationLevel, input);

        if (approved)
            return process(input) + " [APPROVED — trade upward]";
        else
            return process(input) + " [HELD 48hrs — pending auditor review]";
    }
}
