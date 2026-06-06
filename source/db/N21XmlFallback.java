package db;

import java.io.File;
import java.io.FileWriter;
import java.time.LocalDate;
import java.time.Instant;

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
}
