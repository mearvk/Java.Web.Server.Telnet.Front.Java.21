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
        class Entry { String ref; long ts; int idx; Entry(String r,long t,int i){ref=r;ts=t;idx=i;} }

        List<Entry> nitro = new ArrayList<>();
        List<Entry> web = new ArrayList<>();
        List<Entry> base = new ArrayList<>();
        List<Entry> telnet = new ArrayList<>();
        List<Entry> aes = new ArrayList<>();
        List<Entry> bitcoin = new ArrayList<>();
        List<Entry> remainder = new ArrayList<>();

        int index = 0;
        for (String ref : STARTUP_REFERENCES)
        {
            String cn = extractClassName(ref);
            String low = cn.toLowerCase();
            long ts = extractTimestamp(ref); // may be -1 on parse failure

            if (cn.equalsIgnoreCase("NitroWebExpress") || low.contains("nitrowebexpress")) nitro.add(new Entry(ref, ts, index));
            else if (cn.equalsIgnoreCase("WebExpress") || low.contains("webexpress")) web.add(new Entry(ref, ts, index));
            else if (cn.equalsIgnoreCase("BaseServer") || low.contains("baseserver")) base.add(new Entry(ref, ts, index));
            else if (low.contains("telnet")) telnet.add(new Entry(ref, ts, index));
            else if (low.contains("aes") || low.contains("aesc") || low.contains("aesen")) aes.add(new Entry(ref, ts, index));
            else if (low.contains("bitcoin")) bitcoin.add(new Entry(ref, ts, index));
            else remainder.add(new Entry(ref, ts, index));

            index++;
        }

        // Sort each group by timestamp (ascending). If timestamp unknown (-1), preserve original index ordering.
        java.util.Comparator<Entry> cmp = (a,b) -> {
            if (a.ts != -1 && b.ts != -1) return Long.compare(a.ts, b.ts);
            if (a.ts != -1) return -1;
            if (b.ts != -1) return 1;
            return Integer.compare(a.idx, b.idx);
        };

        nitro.sort(cmp); web.sort(cmp); base.sort(cmp); telnet.sort(cmp); aes.sort(cmp); bitcoin.sort(cmp); remainder.sort(cmp);

        // Print in the requested sequence using CommonRails.delayableFinePrinter to preserve formatting/animation.
        try
        {
            for (Entry e : nitro) CommonRails.delayableFinePrinter(e.ref, 21);
            for (Entry e : web) CommonRails.delayableFinePrinter(e.ref, 21);
            for (Entry e : base) CommonRails.delayableFinePrinter(e.ref, 21);
            for (Entry e : telnet) CommonRails.delayableFinePrinter(e.ref, 21);
            for (Entry e : aes) CommonRails.delayableFinePrinter(e.ref, 21);
            for (Entry e : bitcoin) CommonRails.delayableFinePrinter(e.ref, 21);
            for (Entry e : remainder) CommonRails.delayableFinePrinter(e.ref, 21);
        }
        catch (Throwable t)
        {
            // best-effort printing; if CommonRails printing fails, fall back to System.out
            try
            {
                for (Entry e : nitro) System.out.println(e.ref);
                for (Entry e : web) System.out.println(e.ref);
                for (Entry e : base) System.out.println(e.ref);
                for (Entry e : telnet) System.out.println(e.ref);
                for (Entry e : aes) System.out.println(e.ref);
                for (Entry e : bitcoin) System.out.println(e.ref);
                for (Entry e : remainder) System.out.println(e.ref);
            }
            catch (Throwable ignored) {}
        }
    }

    /**
     * Extract epoch millis from the reference's Date field. Returns -1 on failure.
     */
    protected static long extractTimestamp(String reference)
    {
        if (reference == null) return -1;
        int idx = reference.indexOf("[Date:");
        if (idx < 0) return -1;
        int start = idx + "[Date:".length();
        int end = reference.indexOf(']', start);
        if (end < 0) return -1;
        String dateText = reference.substring(start, end).trim();
        // dateText format expected: yyyy-MM-dd HH:mm:ss z
        try
        {
            java.text.SimpleDateFormat fmt = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
            java.util.Date d = fmt.parse(dateText);
            return d.getTime();
        }
        catch (Exception e)
        {
            return -1;
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