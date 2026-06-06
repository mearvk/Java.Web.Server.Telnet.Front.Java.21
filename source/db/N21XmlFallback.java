package db;

import java.io.File;
import java.io.FileWriter;
import java.time.LocalDate;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

/**
 * XML fallback store — appends records to db/fallback/YYYY-MM-DD/N21.xml
 * when MySQL is unavailable.  Thread-safe via synchronized append.
 */
public class N21XmlFallback
{
    private static File xmlFile = null;

    private static synchronized File file()
    {
        if (xmlFile == null)
        {
            File dir = new File("db/fallback/" + LocalDate.now());
            dir.mkdirs();
            xmlFile = new File(dir, "N21.xml");

            // Write root open-tag once if file is new
            if (!xmlFile.exists() || xmlFile.length() == 0)
            {
                write("<N21>\n");
            }
        }
        return xmlFile;
    }

    public static synchronized void append(String table, String... kvPairs)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("  <record table=\"").append(esc(table)).append("\" ts=\"").append(Instant.now()).append("\">\n");
        for (int i = 0; i + 1 < kvPairs.length; i += 2)
            sb.append("    <").append(kvPairs[i]).append(">").append(esc(kvPairs[i + 1])).append("</").append(kvPairs[i]).append(">\n");
        sb.append("  </record>\n");
        write(sb.toString());
    }

    private static void write(String text)
    {
        try (FileWriter fw = new FileWriter(file(), true))
        {
            fw.write(text);
        }
        catch (Exception e)
        {
            System.err.println("[N21XmlFallback] write failed: " + e.getMessage());
        }
    }

    /** Minimal XML escaping for attribute and element values. */
    private static String esc(String s)
    {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    // ── Replay on reboot ──────────────────────────────────────────────────────

    /**
     * Called at startup. Scans every XML fallback file under db/fallback/,
     * replays any table=national_finance_ids records into MySQL, then removes
     * successfully replayed records from the XML so they are not re-sent.
     */
    public static void replayFallback()
    {
        File root = new File("db/fallback");
        if (!root.exists()) return;

        for (File dayDir : listDirs(root))
        {
            File xml = new File(dayDir, "N21.xml");
            if (!xml.exists() || xml.length() == 0) continue;

            // Close the XML so it is well-formed for parsing
            ensureClosed(xml);

            List<Element> replayed  = new ArrayList<>();
            List<Element> remaining = new ArrayList<>();

            try
            {
                org.w3c.dom.Document doc = DocumentBuilderFactory.newInstance()
                    .newDocumentBuilder().parse(xml);

                NodeList records = doc.getElementsByTagName("record");

                for (int i = 0; i < records.getLength(); i++)
                {
                    Element rec = (Element) records.item(i);
                    String table = rec.getAttribute("table");

                    if ("national_finance_ids".equals(table))
                    {
                        national.NationalFinanceID n = fromElement(rec);
                        boolean ok = tryStore(n);
                        if (ok) replayed.add(rec); else remaining.add(rec);
                    }
                    else
                    {
                        remaining.add(rec);
                    }
                }
            }
            catch (Exception e)
            {
                System.err.println("[N21XmlFallback] replay parse error: " + e.getMessage());
                continue;
            }

            if (replayed.isEmpty()) continue;

            // Rewrite the file keeping only un-replayed records
            rewrite(xml, remaining);

            System.out.println("[N21XmlFallback] replayed " + replayed.size()
                + " national_finance_ids record(s) from " + xml.getPath());
        }
    }

    // ── replay helpers ────────────────────────────────────────────────────────

    private static boolean tryStore(national.NationalFinanceID n)
    {
        try
        {
            N21Store.storeNationalFinanceID(n);
            // storeNationalFinanceID only falls through to XML on failure;
            // if it threw, the catch below will return false.
            return true;
        }
        catch (Exception e)
        {
            System.err.println("[N21XmlFallback] replay store failed for national_id="
                + n.nationalId + ": " + e.getMessage());
            return false;
        }
    }

    private static national.NationalFinanceID fromElement(Element rec)
    {
        national.NationalFinanceID n = new national.NationalFinanceID();
        n.nationalId     = parseLong(child(rec, "national_id"));
        n.remoteAddress  = child(rec, "remote_address");
        n.iq             = parseInt(child(rec, "iq"));
        n.educationLevel = child(rec, "education_level");
        n.socialSkills   = parseInt(child(rec, "social_skills"));
        n.equipment      = child(rec, "equipment");
        n.trustLevel     = parseInt(child(rec, "trust_level"));
        n.parentOne      = child(rec, "parent_one");
        n.parentTwo      = child(rec, "parent_two");
        n.suspects       = child(rec, "suspects");
        n.socialSpotting = child(rec, "social_spotting");
        n.promissoryNote = parseDouble(child(rec, "promissory_note"));
        return n;
    }

    private static void rewrite(File xml, List<Element> keep)
    {
        try (FileWriter fw = new FileWriter(xml, false))
        {
            fw.write("<N21>\n");
            for (Element rec : keep)
            {
                fw.write("  <record table=\"" + rec.getAttribute("table")
                    + "\" ts=\"" + rec.getAttribute("ts") + "\">\n");
                NodeList children = rec.getChildNodes();
                for (int i = 0; i < children.getLength(); i++)
                {
                    if (children.item(i) instanceof Element child)
                        fw.write("    <" + child.getTagName() + ">"
                            + child.getTextContent()
                            + "</" + child.getTagName() + ">\n");
                }
                fw.write("  </record>\n");
            }
        }
        catch (Exception e)
        {
            System.err.println("[N21XmlFallback] rewrite failed: " + e.getMessage());
        }
    }

    /** Appends </N21> if missing so the file is parseable. */
    private static void ensureClosed(File xml)
    {
        try
        {
            String content = new String(java.nio.file.Files.readAllBytes(xml.toPath()));
            if (!content.trim().endsWith("</N21>"))
            {
                try (FileWriter fw = new FileWriter(xml, true)) { fw.write("</N21>\n"); }
            }
        }
        catch (Exception ignored) {}
    }

    private static File[] listDirs(File root)
    {
        File[] dirs = root.listFiles(File::isDirectory);
        return dirs != null ? dirs : new File[0];
    }

    private static String  child(Element e, String tag) { NodeList nl = e.getElementsByTagName(tag); return nl.getLength() > 0 ? nl.item(0).getTextContent().trim() : ""; }
    private static long    parseLong(String s)   { try { return Long.parseLong(s); }   catch (Exception e) { return 0L;  } }
    private static int     parseInt(String s)    { try { return Integer.parseInt(s); } catch (Exception e) { return 0;   } }
    private static double  parseDouble(String s) { try { return Double.parseDouble(s); } catch (Exception e) { return 0.0; } }
}
