package middle.director;

/**
 * Base interface for all Middle Director modules.
 * Each module processes finance/goal synchronization content in sequence
 * and persists trade records via DirectorPersistence.
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
}
