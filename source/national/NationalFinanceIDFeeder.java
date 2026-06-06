package national;

import connections.Connection;
import db.N21Store;

import java.io.BufferedWriter;

/**
 * On first Telnet connect, interactively prompts the new user for their National
 * Finance profile, then persists the completed record to MySQL.
 *
 * If the client types an existing 8-digit National ID at the opening prompt,
 * the record is loaded from the database instead of re-collecting all fields.
 *
 * Usage (called from ConnectionPoller.handleSession on first connect):
 *
 *   NationalFinanceIDFeeder.greet(connection);
 */
public class NationalFinanceIDFeeder
{
    // ─────────────────────────────────────────────────────────────────────────
    // Public entry point
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Greet a newly connected Telnet client.
     * Prompts for an existing National ID or collects all profile fields for a new user.
     * Persists to MySQL on completion.
     */
    public static NationalFinanceID greet(Connection conn)
    {
        try
        {
            write(conn, "");
            write(conn, "╔══════════════════════════════════════════════════════════╗");
            write(conn, "║          N21 NATIONAL FINANCE IDENTIFICATION SYSTEM      ║");
            write(conn, "╚══════════════════════════════════════════════════════════╝");
            write(conn, "");
            write(conn, "  Welcome.  This system records your National Finance ID.");
            write(conn, "  Your profile includes: IQ, education, social skills,");
            write(conn, "  equipment, trust level, parents, societal beliefs,");
            write(conn, "  social standing, and promissory note (projected value).");
            write(conn, "");
            write(conn, "  If you have an existing 8-digit National ID, enter it now.");
            write(conn, "  Otherwise press ENTER to register as a new user.");
            write(conn, "");

            String firstLine = prompt(conn, "  National ID (or ENTER for new): ");

            // ── returning user: look up by national ID ────────────────────────
            if (firstLine != null && firstLine.matches("\\d{8}"))
            {
                long id = Long.parseLong(firstLine);
                NationalFinanceID existing = N21Store.loadNationalFinanceID(id);
                if (existing != null)
                {
                    write(conn, "");
                    write(conn, "  National ID " + id + " recognised.  Welcome back.");
                    write(conn, "");
                    financePrompt(conn, existing);
                    return existing;
                }
                write(conn, "  ID not found — continuing as new user.");
            }

            // ── new user: collect all fields ──────────────────────────────────
            NationalFinanceID nfid = new NationalFinanceID();
            nfid.remoteAddress = conn.remote_address != null ? conn.remote_address : "";

            // Assign a new National ID
            national.NationalID natId = new national.NationalID();
            nfid.nationalId = natId.EIGHT_DIGITS;

            write(conn, "");
            write(conn, "  Your assigned National ID: " + nfid.nationalId);
            write(conn, "  Please answer the following questions.");
            write(conn, "  (Press ENTER to skip any field.)");
            write(conn, "");

            // IQ
            write(conn, "  IQ — Your estimated intelligence quotient (e.g. 100).");
            nfid.iq = parseInt(prompt(conn, "  IQ: "), 0);

            // Education
            write(conn, "");
            write(conn, "  Education — Highest level attained.");
            write(conn, "  Options: none / high school / associates / bachelors / masters / phd / trade");
            nfid.educationLevel = defaultStr(prompt(conn, "  Education: "), "none");

            // Social skills
            write(conn, "");
            write(conn, "  Social Skills — Score 0-100 measuring ability to operate in");
            write(conn, "  group, institutional, and public settings.");
            nfid.socialSkills = parseInt(prompt(conn, "  Social Skills (0-100): "), 0);

            // Equipment
            write(conn, "");
            write(conn, "  Equipment — Comma-separated hardware/tools/resources you possess");
            write(conn, "  (e.g. laptop,radio,vehicle).");
            nfid.equipment = defaultStr(prompt(conn, "  Equipment: "), "");

            // Trust level
            write(conn, "");
            write(conn, "  Trust Level — Your institutional trust score 0-100.");
            write(conn, "  Higher means more trusted by the national system.");
            nfid.trustLevel = parseInt(prompt(conn, "  Trust Level (0-100): "), 0);

            // Parents
            write(conn, "");
            write(conn, "  Parent One — Full name of your first parent or legal guardian.");
            nfid.parentOne = defaultStr(prompt(conn, "  Parent One: "), "");

            write(conn, "");
            write(conn, "  Parent Two — Full name of your second parent or legal guardian.");
            nfid.parentTwo = defaultStr(prompt(conn, "  Parent Two: "), "");

            // Suspects (societal beliefs)
            write(conn, "");
            write(conn, "  Societal Beliefs — What do you probably believe in society?");
            write(conn, "  Describe your ideological settings, affiliations, or tendencies.");
            nfid.suspects = defaultStr(prompt(conn, "  Beliefs: "), "");

            // Social spotting
            write(conn, "");
            write(conn, "  Social Spotting — Where does society most likely place you?");
            write(conn, "  Describe your perceived class, role, or standing.");
            nfid.socialSpotting = defaultStr(prompt(conn, "  Social Standing: "), "");

            // Promissory note
            write(conn, "");
            write(conn, "  Promissory Note — Your projected future profit value (USD).");
            write(conn, "  Enter the monetary amount you expect to generate or receive.");
            nfid.promissoryNote = parseDouble(prompt(conn, "  Promissory Note (USD): "), 0.0);

            // Persist
            N21Store.storeNationalFinanceID(nfid);

            write(conn, "");
            write(conn, "  ✔  National Finance ID " + nfid.nationalId + " registered and stored.");
            write(conn, "");

            financePrompt(conn, nfid);
            return nfid;
        }
        catch (Exception e)
        {
            exceptions.ExceptionHandler.dispatch(e);
            return null;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // National ID Finance prompt — runs after login for both new and returning users
    // ─────────────────────────────────────────────────────────────────────────

    private static void financePrompt(Connection conn, NationalFinanceID nfid)
    {
        write(conn, "National ID Finance");
        write(conn, "");

        int line = 1;
        for (;;)
        {
            String input = prompt(conn, line + " > ");
            if (input == null || input.equalsIgnoreCase("quit") || input.equalsIgnoreCase("exit")) break;

            write(conn, line + " < " + trade(input, nfid));
            line++;
        }
    }

    /**
     * Produce a trading-context reply for the given input.
     * Recognises basic directives; anything else echoes a market acknowledgement.
     */
    private static String trade(String input, NationalFinanceID nfid)
    {
        String cmd = input.trim().toLowerCase();
        if (cmd.isEmpty())                          return "Ready.";
        if (cmd.equals("help"))                     return HELP;
        if (cmd.startsWith("buy"))                  return "BUY order noted for National ID " + nfid.nationalId + ".  Awaiting market confirmation.";
        if (cmd.startsWith("sell"))                 return "SELL order noted for National ID " + nfid.nationalId + ".  Awaiting market confirmation.";
        if (cmd.startsWith("balance"))              return "Promissory balance: $" + String.format("%.2f", nfid.promissoryNote) + " USD.";
        if (cmd.startsWith("id"))                   return "National ID: " + nfid.nationalId + "  Trust: " + nfid.trustLevel + "  Education: " + nfid.educationLevel + ".";
        if (cmd.startsWith("status"))               return "National ID " + nfid.nationalId + " active.  Trust " + nfid.trustLevel + "/100.  Promissory $" + String.format("%.2f", nfid.promissoryNote) + ".";
        return "Received: [" + input + "]  — National ID " + nfid.nationalId + " logged.";
    }

    private static final String HELP =
        "\r\n" +
        "  Commands\r\n" +
        "  ────────────────────────────────────────────────────\r\n" +
        "  buy  <amount>   Place a BUY order on the market\r\n" +
        "  sell <amount>   Place a SELL order on the market\r\n" +
        "  balance         Show your promissory note balance (USD)\r\n" +
        "  id              Show your National ID and profile summary\r\n" +
        "  status          Show full account status and trust level\r\n" +
        "  help            Show this command list\r\n" +
        "  quit / exit     End this session\r\n" +
        "  ────────────────────────────────────────────────────";

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static void write(Connection conn, String line)
    {
        try
        {
            BufferedWriter w = conn.writer;
            if (w == null) return;
            w.write(line + "\r\n");
            w.flush();
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private static String prompt(Connection conn, String question)
    {
        try
        {
            write(conn, question);
            if (conn.reader == null) return "";
            String line = conn.reader.readLine();
            return line != null ? line.trim() : "";
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); return ""; }
    }

    private static int    parseInt(String s, int def)     { try { return Integer.parseInt(s.replaceAll("[^\\d]","")); } catch (Exception e) { return def; } }
    private static double parseDouble(String s, double d) { try { return Double.parseDouble(s); }                       catch (Exception e) { return d;   } }
    private static String defaultStr(String s, String d)  { return (s == null || s.isEmpty()) ? d : s; }
}
