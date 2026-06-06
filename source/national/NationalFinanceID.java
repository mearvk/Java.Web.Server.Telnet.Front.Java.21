package national;

/**
 * A person's full national finance profile.
 * Populated by NationalFinanceIDFeeder from the initial Telnet connection,
 * then persisted to MySQL via N21Store.storeNationalFinanceID().
 */
public class NationalFinanceID
{
    // ── identity ──────────────────────────────────────────────────────────────
    public long   nationalId;           // 8-digit public NationalID.EIGHT_DIGITS
    public String remoteAddress;        // IP of the originating Telnet client

    // ── personal aspects ──────────────────────────────────────────────────────
    public int    iq;                   // estimated IQ
    public String educationLevel;       // e.g. "high school", "bachelors", "phd"
    public int    socialSkills;         // 0-100 score
    public String equipment;           // hardware / tools associated with the person

    // ── trust ─────────────────────────────────────────────────────────────────
    public int    trustLevel;           // 0-100

    // ── family ────────────────────────────────────────────────────────────────
    public String parentOne;
    public String parentTwo;

    // ── societal inference ────────────────────────────────────────────────────
    public String suspects;             // what they probably believe (societal settings)
    public String socialSpotting;       // where society probably places them

    // ── finance ───────────────────────────────────────────────────────────────
    public double promissoryNote;       // projected profit / money owed (promissory note value)

    // ── audit ─────────────────────────────────────────────────────────────────
    public java.util.Date createdAt;

    public NationalFinanceID()
    {
        this.createdAt = new java.util.Date();
    }
}
