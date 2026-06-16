package middle.director;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

/**
 * Distribution License — determines this NWE installation's edition and trade rank.
 *
 * Editions and immutable trade ranks (trade priority flows top-down):
 *   - PERSONAL_EXECUTIVE: Owner edition (rank 8) — highest priority
 *   - NATIONAL:           Full national version (rank 6)
 *   - INTERNATIONAL:      Friendly international version (rank 4)
 *   - FREE:               Free Software version (rank 4)
 *
 * Trade flow order: PEE → NDE → International → FSE
 * Ranks are NOT alterable at runtime. Stored in MySQL for verification.
 *
 * Creator: Max Rupplin
 * Email:   mearvk@mearvk.us  |  mearvk@outlook.com
 */
public class DistributionLicense
{
    public enum Edition
    {
        PERSONAL_EXECUTIVE(8),
        NATIONAL(6),
        INTERNATIONAL(4),
        FREE(4);

        private final int rank;
        Edition(int rank) { this.rank = rank; }

        /** Immutable trade rank. Not alterable. */
        public int rank() { return rank; }
    }

    private static final String CENTRAL_REPO = "mearvk/Java.Web.Server.Telnet.Front.Java.21";
    private static final String GITHUB_API = "https://api.github.com/repos/" + CENTRAL_REPO;

    private static Edition CURRENT = Edition.FREE;

    public static Edition getEdition() { return CURRENT; }

    /** Immutable rank of the current edition. */
    public static int getRank() { return CURRENT.rank(); }

    /**
     * Verify PAT and set the distribution edition.
     * Called at install time and boot time.
     *
     * @param pat     GitHub Personal Access Token
     * @param region  "personal_executive", "national", "international", or null/empty for free
     * @return the resolved edition
     */
    public static Edition authorize(String pat, String region)
    {
        if (pat == null || pat.isBlank())
        {
            CURRENT = Edition.FREE;
            storeFlag(CURRENT);
            return CURRENT;
        }

        if (verifyToken(pat))
        {
            CURRENT = switch (region != null ? region.toLowerCase() : "")
            {
                case "personal_executive" -> Edition.PERSONAL_EXECUTIVE;
                case "national"           -> Edition.NATIONAL;
                case "international"      -> Edition.INTERNATIONAL;
                default                   -> Edition.FREE;
            };
        }
        else
        {
            CURRENT = Edition.FREE;
        }

        storeFlag(CURRENT);
        return CURRENT;
    }

    /** Load edition flag from MySQL on boot. */
    public static void loadFromDatabase()
    {
        try
        {
            java.sql.Connection conn = database.N21DataSource.get();
            if (conn == null) return;

            java.sql.Statement st = conn.createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS distribution_license (" +
                "  id INT PRIMARY KEY DEFAULT 1," +
                "  edition VARCHAR(30) NOT NULL DEFAULT 'FREE'," +
                "  rank INT NOT NULL DEFAULT 4," +
                "  verified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
                ") ENGINE=InnoDB");

            java.sql.ResultSet rs = st.executeQuery("SELECT edition FROM distribution_license WHERE id=1");
            if (rs.next())
            {
                try { CURRENT = Edition.valueOf(rs.getString("edition")); }
                catch (Exception ignored) { CURRENT = Edition.FREE; }
            }
            rs.close();
            st.close();
        }
        catch (Exception e) { /* default FREE */ }
    }

    private static void storeFlag(Edition edition)
    {
        try
        {
            java.sql.Connection conn = database.N21DataSource.get();
            if (conn == null) return;

            java.sql.Statement st = conn.createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS distribution_license (" +
                "  id INT PRIMARY KEY DEFAULT 1," +
                "  edition VARCHAR(30) NOT NULL DEFAULT 'FREE'," +
                "  rank INT NOT NULL DEFAULT 4," +
                "  verified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
                ") ENGINE=InnoDB");

            java.sql.PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO distribution_license (id, edition, rank, verified_at) VALUES (1, ?, ?, NOW()) " +
                "ON DUPLICATE KEY UPDATE edition=VALUES(edition), rank=VALUES(rank), verified_at=NOW()");
            ps.setString(1, edition.name());
            ps.setInt(2, edition.rank());
            ps.executeUpdate();
            ps.close();
            st.close();
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private static boolean verifyToken(String token)
    {
        try
        {
            HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(GITHUB_API))
                .header("Authorization", "Bearer " + token)
                .header("Accept", "application/vnd.github+json")
                .GET()
                .build();

            HttpResponse<String> resp = HttpClient.newHttpClient()
                .send(req, HttpResponse.BodyHandlers.ofString());

            return resp.statusCode() == 200;
        }
        catch (Exception e) { return false; }
    }

    public static String editionBanner()
    {
        return switch (CURRENT)
        {
            case PERSONAL_EXECUTIVE -> "[ PERSONAL EXECUTIVE EDITION — Owner (Rank 8) ]";
            case NATIONAL           -> "[ NATIONAL DISTRIBUTION EDITION — Full National (Rank 6) ]";
            case INTERNATIONAL      -> "[ INTERNATIONAL EDITION — Friendly International (Rank 4) ]";
            case FREE               -> "[ FREE SOFTWARE EDITION — Community (Rank 4) ]";
        };
    }
}
