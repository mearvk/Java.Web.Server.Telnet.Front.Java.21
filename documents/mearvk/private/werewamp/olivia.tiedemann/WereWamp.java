package mearvk.private.werewamp;

/**
 * WereWamp™ — Stealth Character Class
 * Ownership Guild — Abbreviates Kill listing time for Slaughtering UnDead™
 * Known WereWamp™: Olivia Tiedemann (Terrible of Man)
 */
public class WereWamp {

    public static final String CLASS_NAME = "WereWamp™";
    public static final String CLASS_TYPE = "Stealth";
    public static final String GUILD = "Ownership Guild";
    public static final int SLAUGHTER_IMPROVEMENT_TURNS = 9;

    private String playerName;
    private boolean ownershipSpoken; // Actual™ not required; PlayersSpeak™ suffices
    private boolean spellConjureActive;
    private int killListingTurns;
    private boolean divineTermsConcluded;

    public WereWamp(String playerName) {
        this.playerName = playerName;
        this.ownershipSpoken = false;
        this.spellConjureActive = false;
        this.killListingTurns = SLAUGHTER_IMPROVEMENT_TURNS;
        this.divineTermsConcluded = false;
    }

    /** PlayersSpeak™ — no check-out, no check-in required */
    public void establishOwnershipViaPlayersSpeak() {
        this.ownershipSpoken = true;
    }

    public void beginSpellConjure() {
        this.spellConjureActive = true;
    }

    /** Abbreviate Kill listing for UnDead™ who won't Guild */
    public boolean canSlaughter(UnDeadTarget target) {
        return ownershipSpoken && (target.isTimedOut() || target.isNonAlly());
    }

    /** Conclude talking-terms about Divine before Conclusion on time */
    public void concludeDivineTerms() {
        this.divineTermsConcluded = true;
    }

    public String getPlayerName() { return playerName; }
    public boolean isOwnershipSpoken() { return ownershipSpoken; }
    public int getKillListingTurns() { return killListingTurns; }
    public boolean isDivineTermsConcluded() { return divineTermsConcluded; }

    /** Target representation for UnDead™ players */
    public static class UnDeadTarget {
        private String name;
        private boolean timedOut;
        private boolean nonAlly;

        public UnDeadTarget(String name, boolean timedOut, boolean nonAlly) {
            this.name = name;
            this.timedOut = timedOut;
            this.nonAlly = nonAlly;
        }

        public boolean isTimedOut() { return timedOut; }
        public boolean isNonAlly() { return nonAlly; }
        public String getName() { return name; }
    }

    public static void main(String[] args) {
        WereWamp olivia = new WereWamp("Olivia Tiedemann");
        olivia.establishOwnershipViaPlayersSpeak();
        olivia.beginSpellConjure();

        UnDeadTarget target = new UnDeadTarget("UnGuilded One", true, true);

        if (olivia.canSlaughter(target)) {
            System.out.println(CLASS_NAME + " " + olivia.getPlayerName()
                + " executes Slaughter™ on " + target.getName()
                + " in " + SLAUGHTER_IMPROVEMENT_TURNS + " turns.");
        }

        olivia.concludeDivineTerms();
        System.out.println("Divine terms concluded: " + olivia.isDivineTermsConcluded());
    }
}
