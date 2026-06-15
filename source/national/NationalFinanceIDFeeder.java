package national;

import connections.Connection;
import database.N21Store;

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
    public static NationalFinanceID greet(final Connection CONN)
    {
        try
        {
            write(CONN, "");
            write(CONN, "╔══════════════════════════════════════════════════════════╗");
            write(CONN, "║          N21 NATIONAL FINANCE IDENTIFICATION SYSTEM      ║");
            write(CONN, "╚══════════════════════════════════════════════════════════╝");
            write(CONN, "");
            write(CONN, "  Welcome.  This system records your National Finance ID.");
            write(CONN, "  Your profile includes: IQ, education, social skills,");
            write(CONN, "  equipment, trust level, parents, societal beliefs,");
            write(CONN, "  social standing, and promissory note (projected value).");
            write(CONN, "");
            write(CONN, "  If you have an existing 8-digit National ID, enter it now.");
            write(CONN, "  Otherwise press ENTER to register as a new user.");
            write(CONN, "");

            String firstLine = prompt(CONN, "  National ID (or ENTER for new): ");

            // ── returning user: look up by national ID ────────────────────────
            if (firstLine != null && firstLine.matches("\\d{8}"))
            {
                long id = Long.parseLong(firstLine);
                NationalFinanceID existing = N21Store.loadNationalFinanceID(id);
                if (existing != null)
                {
                    write(CONN, "");
                    write(CONN, "  National ID " + id + " recognised.  Welcome back.");
                    write(CONN, "");
                    financePrompt(CONN, existing);
                    return existing;
                }
                write(CONN, "  ID not found — continuing as new user.");
            }

            // ── new user: collect all fields ──────────────────────────────────
            NationalFinanceID nfid = new NationalFinanceID();
            nfid.remoteAddress = CONN.remote_address != null ? CONN.remote_address : "";

            // Assign a new National ID
            national.NationalID natId = new national.NationalID();
            nfid.nationalId = natId.EIGHT_DIGITS;

            write(CONN, "");
            write(CONN, "  Your assigned National ID: " + nfid.nationalId);
            write(CONN, "  Please answer the following questions.");
            write(CONN, "  (Press ENTER to skip any field.)");
            write(CONN, "");

            // IQ
            write(CONN, "  IQ — Your estimated intelligence quotient (e.g. 100).");
            nfid.iq = parseInt(prompt(CONN, "  IQ: "), 0);

            // Education
            write(CONN, "");
            write(CONN, "  Education — Highest level attained.");
            write(CONN, "  Options: none / high school / associates / bachelors / masters / phd / trade");
            nfid.educationLevel = defaultStr(prompt(CONN, "  Education: "), "none");

            // Social skills
            write(CONN, "");
            write(CONN, "  Social Skills — Score 0-100 measuring ability to operate in");
            write(CONN, "  group, institutional, and public settings.");
            nfid.socialSkills = parseInt(prompt(CONN, "  Social Skills (0-100): "), 0);

            // Equipment
            write(CONN, "");
            write(CONN, "  Equipment — Comma-separated hardware/tools/resources you possess");
            write(CONN, "  (e.g. laptop,radio,vehicle).");
            nfid.equipment = defaultStr(prompt(CONN, "  Equipment: "), "");

            // Trust level
            write(CONN, "");
            write(CONN, "  Trust Level — Your institutional trust score 0-100.");
            write(CONN, "  Higher means more trusted by the national system.");
            nfid.trustLevel = parseInt(prompt(CONN, "  Trust Level (0-100): "), 0);

            // Parents
            write(CONN, "");
            write(CONN, "  Parent One — Full name of your first parent or legal guardian.");
            nfid.parentOne = defaultStr(prompt(CONN, "  Parent One: "), "");

            write(CONN, "");
            write(CONN, "  Parent Two — Full name of your second parent or legal guardian.");
            nfid.parentTwo = defaultStr(prompt(CONN, "  Parent Two: "), "");

            // Suspects (societal beliefs)
            write(CONN, "");
            write(CONN, "  Societal Beliefs — What do you probably believe in society?");
            write(CONN, "  Describe your ideological settings, affiliations, or tendencies.");
            nfid.suspects = defaultStr(prompt(CONN, "  Beliefs: "), "");

            // Social spotting
            write(CONN, "");
            write(CONN, "  Social Spotting — Where does society most likely place you?");
            write(CONN, "  Describe your perceived class, role, or standing.");
            nfid.socialSpotting = defaultStr(prompt(CONN, "  Social Standing: "), "");

            // Promissory note
            write(CONN, "");
            write(CONN, "  Promissory Note — Your projected future profit value (USD).");
            write(CONN, "  Enter the monetary amount you expect to generate or receive.");
            nfid.promissoryNote = parseDouble(prompt(CONN, "  Promissory Note (USD): "), 0.0);

            // Persist
            N21Store.storeNationalFinanceID(nfid);

            // Generate per-user cryptographic keypairs (RSA, DSA, AES)
            NationalKeypairGenerator keypair = new NationalKeypairGenerator();
            N21Store.storeKeypair(nfid.nationalId, keypair);

            write(CONN, "");
            write(CONN, "  ✔  National Finance ID " + nfid.nationalId + " registered and stored.");
            write(CONN, "  ✔  RSA-2048, DSA-2048, AES-256 keypairs generated and stored.");
            write(CONN, "");

            financePrompt(CONN, nfid);
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

    private static void financePrompt(final Connection CONN, final NationalFinanceID NFID)
    {
        write(CONN, "National ID Finance");
        write(CONN, "");

        int line = 1;
        for (;;)
        {
            String input = prompt(CONN, line + " > ");
            if (input == null || input.equalsIgnoreCase("quit") || input.equalsIgnoreCase("exit")) break;

            if (input.trim().toLowerCase().startsWith("crypto"))
            {
                cryptoPrompt(CONN, NFID);
                write(CONN, line + " < Returned from crypto management.");
            }
            else
            {
                write(CONN, line + " < " + trade(input, NFID));
            }
            line++;
        }
    }

    /**
     * Produce a trading-context reply for the given input.
     * Recognises basic directives; anything else echoes a market acknowledgement.
     */
    private static String trade(final String INPUT, final NationalFinanceID NFID)
    {
        String cmd = INPUT.trim().toLowerCase();
        if (cmd.isEmpty())                          return "Ready.";
        if (cmd.equals("help"))                     return HELP;
        if (cmd.startsWith("buy"))                  return "BUY order noted for National ID " + NFID.nationalId + ".  Awaiting market confirmation.";
        if (cmd.startsWith("sell"))                 return "SELL order noted for National ID " + NFID.nationalId + ".  Awaiting market confirmation.";
        if (cmd.startsWith("balance"))              return "Promissory balance: $" + String.format("%.2f", NFID.promissoryNote) + " USD.";
        if (cmd.startsWith("id"))                   return "National ID: " + NFID.nationalId + "  Trust: " + NFID.trustLevel + "  Education: " + NFID.educationLevel + ".";
        if (cmd.startsWith("status"))               return "National ID " + NFID.nationalId + " active.  Trust " + NFID.trustLevel + "/100.  Promissory $" + String.format("%.2f", NFID.promissoryNote) + ".";
        if (cmd.equals("crypto"))                   return "Entering crypto key management...";
        return "Received: [" + INPUT + "]  — National ID " + NFID.nationalId + " logged.";
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
        "  crypto          Manage cryptographic keys (RSA/DSA/AES)\r\n" +
        "  help            Show this command list\r\n" +
        "  quit / exit     End this session\r\n" +
        "  ────────────────────────────────────────────────────";

    // ─────────────────────────────────────────────────────────────────────────
    // Crypto key management sub-prompt
    // ─────────────────────────────────────────────────────────────────────────

    private static void cryptoPrompt(final Connection CONN, final NationalFinanceID NFID)
    {
        write(CONN, "");
        write(CONN, "  ╔════════════════════════════════════════╗");
        write(CONN, "  ║      CRYPTO KEY MANAGEMENT             ║");
        write(CONN, "  ╚════════════════════════════════════════╝");
        write(CONN, "");
        write(CONN, "  Commands:  create <type>  | replace <type>");
        write(CONN, "             check  <type>  | delete  <type>");
        write(CONN, "  Types:     rsa  |  dsa  |  aes");
        write(CONN, "  back       Return to finance prompt");
        write(CONN, "");

        for (;;)
        {
            String input = prompt(CONN, "  crypto> ");
            if (input == null || input.equalsIgnoreCase("back") || input.equalsIgnoreCase("exit")) break;

            String[] parts = input.trim().toLowerCase().split("\\s+", 2);
            String action = parts[0];
            String type = parts.length > 1 ? parts[1] : "";

            if (!type.matches("rsa|dsa|aes") && !action.equals("help"))
            {
                write(CONN, "  Usage: <create|replace|check|delete> <rsa|dsa|aes>");
                continue;
            }

            switch (action)
            {
                case "create" -> {
                    String[] existing = N21Store.loadKeypair(NFID.nationalId, type);
                    if (existing != null && existing.length > 0 && !existing[0].isEmpty())
                    {
                        write(CONN, "  ✗  " + type.toUpperCase() + " key already exists. Use 'replace " + type + "' to regenerate.");
                    }
                    else
                    {
                        NationalKeypairGenerator gen = new NationalKeypairGenerator();
                        N21Store.storeKeypair(NFID.nationalId, gen);
                        write(CONN, "  ✔  " + type.toUpperCase() + " keypair created and stored.");
                    }
                }
                case "replace" -> {
                    boolean ok = N21Store.replaceKeypair(NFID.nationalId, type);
                    if (ok) write(CONN, "  ✔  " + type.toUpperCase() + " keypair replaced with new keys.");
                    else    write(CONN, "  ✗  No existing keypair to replace. Use 'create " + type + "' first.");
                }
                case "check" -> {
                    String[] keys = N21Store.loadKeypair(NFID.nationalId, type);
                    if (keys == null || keys.length == 0 || keys[0].isEmpty())
                    {
                        write(CONN, "  ✗  No " + type.toUpperCase() + " key found for National ID " + NFID.nationalId + ".");
                    }
                    else
                    {
                        write(CONN, "  ✔  " + type.toUpperCase() + " key present for National ID " + NFID.nationalId + ".");
                        if (type.equals("aes"))
                        {
                            write(CONN, "     AES-256 key: " + keys[0].substring(0, Math.min(12, keys[0].length())) + "...");
                        }
                        else
                        {
                            write(CONN, "     Public:  " + keys[0].substring(0, Math.min(20, keys[0].length())) + "...");
                            write(CONN, "     Private: " + keys[1].substring(0, Math.min(20, keys[1].length())) + "...");
                        }
                    }
                }
                case "delete" -> {
                    boolean ok = N21Store.deleteKeypair(NFID.nationalId, type);
                    if (ok) write(CONN, "  ✔  " + type.toUpperCase() + " key deleted for National ID " + NFID.nationalId + ".");
                    else    write(CONN, "  ✗  No " + type.toUpperCase() + " key found to delete.");
                }
                case "help" -> {
                    write(CONN, "  Commands:  create <type>  | replace <type>");
                    write(CONN, "             check  <type>  | delete  <type>");
                    write(CONN, "  Types:     rsa  |  dsa  |  aes");
                }
                default -> write(CONN, "  Unknown command. Try: create, replace, check, delete, help, back");
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static void write(final Connection CONN, final String LINE)
    {
        try
        {
            BufferedWriter w = CONN.writer;
            if (w == null) return;
            w.write(LINE + "\r\n");
            w.flush();
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private static String prompt(final Connection CONN, final String QUESTION)
    {
        try
        {
            write(CONN, QUESTION);
            if (CONN.reader == null) return "";
            String line = CONN.reader.readLine();
            return line != null ? line.trim() : "";
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); return ""; }
    }

    private static int    parseInt(final String S, final int DEF)     { try { return Integer.parseInt(S.replaceAll("[^\\d]","")); } catch (Exception e) { return DEF; } }
    private static double parseDouble(final String S, final double D) { try { return Double.parseDouble(S); }                       catch (Exception e) { return D;   } }
    private static String defaultStr(final String S, final String D)  { return (S == null || S.isEmpty()) ? D : S; }
}
