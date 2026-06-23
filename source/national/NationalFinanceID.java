package national;

/**
 * A person's full National Finance profile — assigned on first Telnet connection.
 *
 * Fields
 * ──────
 * nationalId      — The 8-digit public National ID number assigned to this person.
 *                   Ties back to the national_ids table.
 *
 * remoteAddress   — IPv4/IPv6 address of the Telnet client that provided this data.
 *
 * iq              — Estimated intelligence quotient (numeric).  Used to index cognitive
 *                   capability within the national system.
 *
 * educationLevel  — Highest formal education attained: e.g. "none", "high school",
 *                   "associates", "bachelors", "masters", "phd", "trade".
 *
 * socialSkills    — Social aptitude score 0–100.  Measures ability to operate in
 *                   group, institutional, and public settings.
 *
 * equipment       — Comma-separated list of hardware, tools, or resources the person
 *                   is known to possess or operate (e.g. "laptop,radio,vehicle").
 *
 * trustLevel      — Institutional trust score 0–100.  Higher = more trusted by the
 *                   national system.
 *
 * parentOne       — Full name of first parent / legal guardian.
 *
 * parentTwo       — Full name of second parent / legal guardian (if applicable).
 *
 * suspects        — Free-text field recording what this person probably believes in
 *                   society, their likely ideological settings, affiliations, or
 *                   tendencies as inferred by the system.
 *
 * socialSpotting  — Free-text field recording where society most likely places this
 *                   person — their perceived class, role, or standing as seen by others.
 *
 * promissoryNote  — Monetary value (USD) representing projected future profit or money
 *                   that will flow to or from this person — their promissory note value.
 *
 * createdAt       — Timestamp when this record was first created.
 */
public class NationalFinanceID
{
    // ── identity ──────────────────────────────────────────────────────────────
    /** 8-digit public National ID number (from NationalID.EIGHT_DIGITS). */
    public long   nationalId;

    /** Remote IPv4/IPv6 address of the Telnet client that supplied this record. */
    public String remoteAddress;

    // ── personal aspects ──────────────────────────────────────────────────────
    /** Estimated IQ — cognitive capability index. */
    public int    iq;

    /** Highest education level: none / high school / associates / bachelors / masters / phd / trade. */
    public String educationLevel;

    /** Social aptitude score 0–100. */
    public int    socialSkills;

    /** Comma-separated hardware/tools/resources (e.g. "laptop,radio,vehicle"). */
    public String equipment;

    // ── trust ─────────────────────────────────────────────────────────────────
    /** Institutional trust score 0–100. */
    public int    trustLevel;

    // ── family ────────────────────────────────────────────────────────────────
    /** Full name of first parent or legal guardian. */
    public String parentOne;

    /** Full name of second parent or legal guardian. */
    public String parentTwo;

    // ── societal inference ────────────────────────────────────────────────────
    /** Probable beliefs, ideological settings, and societal tendencies of this person. */
    public String suspects;

    /** Where society most likely places this person — perceived class, role, or standing. */
    public String socialSpotting;

    // ── finance ───────────────────────────────────────────────────────────────
    /** Promissory note value (USD) — projected future profit associated with this person. */
    public double promissoryNote;

    // ── audit ─────────────────────────────────────────────────────────────────
    /** Timestamp of record creation. */
    public java.util.Date createdAt;

    public NationalFinanceID()
    {
        this.createdAt = new java.util.Date();
    }
}
