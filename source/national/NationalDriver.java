package national;

import commons.CommonRails;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Backend to record CommonRails startup print order and re-print in a corrected order.
 */
public class NationalDriver
{
    protected static final List<String> STARTUP_REFERENCES = Collections.synchronizedList(new ArrayList<>());

    /**
     * Record a printed reference line from CommonRails. Stored as-is.
     */
    public static synchronized void record(String reference)
    {
        if (reference == null) return;
        STARTUP_REFERENCES.add(reference);
    }

    protected static String extractClassName(String reference)
    {
        if (reference == null) return "";

        int idx = reference.indexOf("[Current:");
        if (idx < 0) return "";

        int start = idx + "[Current:".length();
        int end = reference.indexOf(']', start);
        if (end < 0) end = Math.min(reference.length(), start + 200);

        String inner = reference.substring(start, end).trim();
        // inner begins with the class simple name (we padded it earlier). Remove any extra spaces.
        // If inner contains spaces, first token is the class name.
        int firstSpace = inner.indexOf(' ');
        if (firstSpace > 0)
        {
            return inner.substring(0, firstSpace).trim();
        }
        return inner;
    }

    /**
     * Print registered startup references in corrected order using CommonRails.delayableFinePrinter.
     * Desired order: NitroWebExpress, WebExpress, BaseServer, Telnet module, AES module, Bitcoin module, remainder
     */
    public static synchronized void printCorrectedOrder()
    {
        List<String> nitro = new ArrayList<>();
        List<String> web = new ArrayList<>();
        List<String> base = new ArrayList<>();
        List<String> telnet = new ArrayList<>();
        List<String> aes = new ArrayList<>();
        List<String> bitcoin = new ArrayList<>();
        List<String> remainder = new ArrayList<>();

        for (String ref : STARTUP_REFERENCES)
        {
            String cn = extractClassName(ref);
            String low = cn.toLowerCase();

            if (cn.equals("NitroWebExpress") || low.contains("nitrowebexpress")) nitro.add(ref);
            else if (cn.equals("WebExpress") || low.contains("webexpress")) web.add(ref);
            else if (cn.equals("BaseServer") || low.contains("baseserver")) base.add(ref);
            else if (low.contains("telnet")) telnet.add(ref);
            else if (low.contains("aes") || low.contains("aesc") || low.contains("aesen")) aes.add(ref);
            else if (low.contains("bitcoin")) bitcoin.add(ref);
            else remainder.add(ref);
        }

        // Print in the requested sequence using CommonRails.delayableFinePrinter to preserve formatting/animation.
        try
        {
            for (String s : nitro) CommonRails.delayableFinePrinter(s, 21);
            for (String s : web) CommonRails.delayableFinePrinter(s, 21);
            for (String s : base) CommonRails.delayableFinePrinter(s, 21);
            for (String s : telnet) CommonRails.delayableFinePrinter(s, 21);
            for (String s : aes) CommonRails.delayableFinePrinter(s, 21);
            for (String s : bitcoin) CommonRails.delayableFinePrinter(s, 21);
            for (String s : remainder) CommonRails.delayableFinePrinter(s, 21);
        }
        catch (Throwable t)
        {
            // best-effort printing; if CommonRails printing fails, fall back to System.out
            try
            {
                for (String s : nitro) System.out.println(s);
                for (String s : web) System.out.println(s);
                for (String s : base) System.out.println(s);
                for (String s : telnet) System.out.println(s);
                for (String s : aes) System.out.println(s);
                for (String s : bitcoin) System.out.println(s);
                for (String s : remainder) System.out.println(s);
            }
            catch (Throwable ignored) {}
        }
    }

    /**
     * Clear recorded startup references.
     */
    public static synchronized void clear()
    {
        STARTUP_REFERENCES.clear();
    }
}