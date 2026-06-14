package database;

import java.io.File;
import java.io.FileWriter;
import java.time.LocalDate;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
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
            File dir = new File("database/fallback/" + LocalDate.now());
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

    public static synchronized void append(final String TABLE, final String... KVPAIRS)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("  <record TABLE=\"").append(esc(TABLE)).append("\" ts=\"").append(Instant.now()).append("\">\n");
        for (int i = 0; i + 1 < KVPAIRS.length; i += 2)
            sb.append("    <").append(KVPAIRS[i]).append(">").append(esc(KVPAIRS[i + 1])).append("</").append(KVPAIRS[i]).append(">\n");
        sb.append("  </record>\n");
        write(sb.toString());
    }

    private static void write(final String TEXT)
    {
        try (FileWriter fw = new FileWriter(file(), true))
        {
            fw.write(TEXT);
        }
        catch (Exception e)
        {
            System.err.println("[N21XmlFallback] write failed: " + e.getMessage());
        }
    }

    /** Minimal XML escaping for attribute and element values. */
    private static String esc(final String S)
    {
        if (S == null) return "";
        return S.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    // ── Replay on reboot ──────────────────────────────────────────────────────

    /**
     * Called at startup. Scans every XML fallback file under db/fallback/,
     * replays any table=national_finance_ids records into MySQL, then removes
     * successfully replayed records from the XML so they are not re-sent.
     */
    public static void replayFallback()
    {
        File root = new File("database/fallback");
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

    private static boolean tryStore(final national.NationalFinanceID N)
    {
        try
        {
            N21Store.storeNationalFinanceID(N);
            // storeNationalFinanceID only falls through to XML on failure;
            // if it threw, the catch below will return false.
            return true;
        }
        catch (Exception e)
        {
            System.err.println("[N21XmlFallback] replay store failed for national_id="
                + N.nationalId + ": " + e.getMessage());
            return false;
        }
    }

    private static national.NationalFinanceID fromElement(final Element REC)
    {
        national.NationalFinanceID n = new national.NationalFinanceID();
        n.nationalId     = parseLong(child(REC, "national_id"));
        n.remoteAddress  = child(REC, "remote_address");
        n.iq             = parseInt(child(REC, "iq"));
        n.educationLevel = child(REC, "education_level");
        n.socialSkills   = parseInt(child(REC, "social_skills"));
        n.equipment      = child(REC, "equipment");
        n.trustLevel     = parseInt(child(REC, "trust_level"));
        n.parentOne      = child(REC, "parent_one");
        n.parentTwo      = child(REC, "parent_two");
        n.suspects       = child(REC, "suspects");
        n.socialSpotting = child(REC, "social_spotting");
        n.promissoryNote = parseDouble(child(REC, "promissory_note"));
        return n;
    }

    private static void rewrite(final File XML, final List<Element> KEEP)
    {
        try (FileWriter fw = new FileWriter(XML, false))
        {
            fw.write("<N21>\n");
            for (Element rec : KEEP)
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
    private static void ensureClosed(final File XML)
    {
        try
        {
            String content = new String(java.nio.file.Files.readAllBytes(XML.toPath()));
            if (!content.trim().endsWith("</N21>"))
            {
                try (FileWriter fw = new FileWriter(XML, true)) { fw.write("</N21>\n"); }
            }
        }
        catch (Exception ignored) {}
    }

    private static File[] listDirs(final File ROOT)
    {
        File[] dirs = ROOT.listFiles(File::isDirectory);
        return dirs != null ? dirs : new File[0];
    }

    private static String  child(final Element E, final String TAG) { NodeList nl = E.getElementsByTagName(TAG); return nl.getLength() > 0 ? nl.item(0).getTextContent().trim() : ""; }
    private static long    parseLong(final String S)   { try { return Long.parseLong(S); }   catch (Exception e) { return 0L;  } }
    private static int     parseInt(final String S)    { try { return Integer.parseInt(S); } catch (Exception e) { return 0;   } }
    private static double  parseDouble(final String S) { try { return Double.parseDouble(S); } catch (Exception e) { return 0.0; } }
}
