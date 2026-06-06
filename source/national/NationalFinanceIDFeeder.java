package national;

import connections.Connection;
import db.N21Store;

/**
 * Reads NationalFinanceID fields from the initial Telnet client connection
 * and persists the record to MySQL.
 *
 * Protocol: the remote client sends key=value lines (one per line) followed
 * by an empty line or "END".  Unknown keys are silently ignored.
 *
 * Example client send sequence:
 *   iq=115
 *   education=bachelors
 *   social_skills=72
 *   equipment=laptop,phone
 *   trust=60
 *   parent_one=Jane Doe
 *   parent_two=John Doe
 *   suspects=libertarian,anti-establishment
 *   social_spotting=middle-class professional
 *   promissory_note=45000.00
 *   END
 */
public class NationalFinanceIDFeeder
{
    /**
     * Feed from a live Connection's reader.
     * Blocks until the client sends "END" or closes.
     * Returns the populated and persisted NationalFinanceID.
     */
    public static NationalFinanceID feed(Connection conn, long nationalId)
    {
        NationalFinanceID nfid = new NationalFinanceID();
        nfid.nationalId    = nationalId;
        nfid.remoteAddress = conn.remote_address != null ? conn.remote_address : "";

        try
        {
            String line;
            while ((line = conn.reader.readLine()) != null)
            {
                line = line.trim();
                if (line.isEmpty() || line.equalsIgnoreCase("END")) break;

                int eq = line.indexOf('=');
                if (eq < 1) continue;

                String key = line.substring(0, eq).trim().toLowerCase();
                String val = line.substring(eq + 1).trim();

                switch (key)
                {
                    case "iq"              -> nfid.iq              = parseInt(val, 0);
                    case "education"       -> nfid.educationLevel  = val;
                    case "social_skills"   -> nfid.socialSkills    = parseInt(val, 0);
                    case "equipment"       -> nfid.equipment       = val;
                    case "trust"           -> nfid.trustLevel      = parseInt(val, 0);
                    case "parent_one"      -> nfid.parentOne       = val;
                    case "parent_two"      -> nfid.parentTwo       = val;
                    case "suspects"        -> nfid.suspects        = val;
                    case "social_spotting" -> nfid.socialSpotting  = val;
                    case "promissory_note" -> nfid.promissoryNote  = parseDouble(val, 0.0);
                }
            }
        }
        catch (Exception e)
        {
            exceptions.ExceptionHandler.dispatch(e);
        }

        N21Store.storeNationalFinanceID(nfid);
        return nfid;
    }

    private static int    parseInt(String s, int def)    { try { return Integer.parseInt(s); }   catch (Exception e) { return def; } }
    private static double parseDouble(String s, double d){ try { return Double.parseDouble(s); } catch (Exception e) { return d;   } }
}
