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
    protected static List<List<String>> GROUPED_STARTUP_REFERENCES = null;
    protected static List<String> GROUP_NAMES = null;

    public static synchronized List<List<String>> getGroupedStartupReferences()
    {
        return GROUPED_STARTUP_REFERENCES;
    }

    public static synchronized List<String> getGroupNames()
    {
        return GROUP_NAMES;
    }

    public static synchronized void printCorrectedOrder()
    {
        class Entry { String ref; long ts; int idx; String className; Entry(String r,long t,int i,String cn){ref=r;ts=t;idx=i;className=cn;} }

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

            // treat any mention of "nitro" as NitroWebExpress group to ensure they print first
            if (low.contains("nitro")) nitro.add(new Entry(ref, ts, index, cn));
            else if (cn.equalsIgnoreCase("WebExpress") || low.contains("webexpress")) web.add(new Entry(ref, ts, index, cn));
            else if (cn.equalsIgnoreCase("BaseServer") || low.contains("baseserver")) base.add(new Entry(ref, ts, index, cn));
            else if (low.contains("telnet")) telnet.add(new Entry(ref, ts, index, cn));
            else if (low.contains("aes") || low.contains("aesc") || low.contains("aesen")) aes.add(new Entry(ref, ts, index, cn));
            else if (low.contains("bitcoin")) bitcoin.add(new Entry(ref, ts, index, cn));
            else remainder.add(new Entry(ref, ts, index, cn));

            index++;
        }

        // Sort each group by timestamp (ascending). If timestamp unknown (-1), preserve original index ordering.
        java.util.Comparator<Entry> cmp = (a,b) -> {
            if (a.ts != -1 && b.ts != -1)
            {
                int r = Long.compare(a.ts, b.ts);
                if (r != 0) return r;
            }
            else if (a.ts != -1) return -1;
            else if (b.ts != -1) return 1;

            // secondary: class name alphabetical to group similar subentries, then original index
            int cn = a.className.compareToIgnoreCase(b.className);
            if (cn != 0) return cn;
            return Integer.compare(a.idx, b.idx);
        };

        nitro.sort(cmp); web.sort(cmp); base.sort(cmp); telnet.sort(cmp); aes.sort(cmp); bitcoin.sort(cmp); remainder.sort(cmp);

        // Convert to lists of strings and store grouped arrays
        List<String> nitroRefs = new ArrayList<>(); for (Entry e: nitro) nitroRefs.add(e.ref);
        List<String> webRefs = new ArrayList<>(); for (Entry e: web) webRefs.add(e.ref);
        List<String> baseRefs = new ArrayList<>(); for (Entry e: base) baseRefs.add(e.ref);
        List<String> telnetRefs = new ArrayList<>(); for (Entry e: telnet) telnetRefs.add(e.ref);
        List<String> aesRefs = new ArrayList<>(); for (Entry e: aes) aesRefs.add(e.ref);
        List<String> bitcoinRefs = new ArrayList<>(); for (Entry e: bitcoin) bitcoinRefs.add(e.ref);
        List<String> remainderRefs = new ArrayList<>(); for (Entry e: remainder) remainderRefs.add(e.ref);

        List<List<String>> grouped = new ArrayList<>();
        grouped.add(nitroRefs);
        grouped.add(webRefs);
        grouped.add(baseRefs);
        grouped.add(telnetRefs);
        grouped.add(aesRefs);
        grouped.add(bitcoinRefs);
        grouped.add(remainderRefs);

        List<String> groupNames = new ArrayList<>();
        groupNames.add("NITRO");
        groupNames.add("WEBEXPRESS");
        groupNames.add("BASESERVER");
        groupNames.add("TELNET");
        groupNames.add("AES");
        groupNames.add("BITCOIN");
        groupNames.add("REMAINDER");

        GROUPED_STARTUP_REFERENCES = grouped;
        GROUP_NAMES = groupNames;

        // Print groups in order; each group's entries are printed together
        try
        {
            for (int gi = 0; gi < grouped.size(); gi++)
            {
                List<String> g = grouped.get(gi);
                String gname = groupNames.get(gi);
                //CommonRails.delayableFinePrinter(". START GROUP: " + gname + " (" + g.size() + ") .", 21);
                //for (String s : g) CommonRails.delayableFinePrinter(s, 21);
            }
        }
        catch (Throwable t)
        {
            try
            {
                for (int gi = 0; gi < grouped.size(); gi++)
                {
                    List<String> g = grouped.get(gi);
                    String gname = groupNames.get(gi);
                    System.out.println("START GROUP: " + gname + " (" + g.size() + ")");
                    for (String s : g) System.out.println(s);
                }
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