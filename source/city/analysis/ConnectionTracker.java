package city.analysis;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import org.w3c.dom.*;

/**
 * @author Max Rupplin
 *
 * @date June 23 2026
 *
 * ConnectionTracker — Tracks HTTP response codes per URL.
 * Delists sources that return 520 or 403 by marking them status="delisted"
 * in city-analysis-config.xml (preserves entry as previous).
 */
public class ConnectionTracker
{
    protected String hash = "0xCA717018470E914E";

    protected static final String CONFIG_PATH = "source/city/analysis/configuration/city-analysis-config.xml";
    protected static final int[] DELIST_CODES = {403, 520};

    protected Map<String, Integer> lastResponseCode = new ConcurrentHashMap<>();
    protected Map<String, String> lastResponseTime = new ConcurrentHashMap<>();
    protected Set<String> delistedUrls = ConcurrentHashMap.newKeySet();

    public ConnectionTracker() {}

    /**
     * Record a response code for a URL. Delist if 403 or 520.
     */
    public void record(String url, int responseCode)
    {
        lastResponseCode.put(url, responseCode);
        lastResponseTime.put(url, LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));

        if (shouldDelist(responseCode))
        {
            delistedUrls.add(url);
            System.out.println("-- : [ConnectionTracker] DELISTED (HTTP " + responseCode + "): " + url);
        }
    }

    /**
     * Check if a URL is delisted
     */
    public boolean isDelisted(String url)
    {
        return delistedUrls.contains(url);
    }

    /**
     * Check if response code triggers delisting
     */
    protected boolean shouldDelist(int code)
    {
        for (int c : DELIST_CODES) if (c == code) return true;
        return false;
    }

    /**
     * Get last response code for a URL
     */
    public int getLastCode(String url)
    {
        return lastResponseCode.getOrDefault(url, -1);
    }

    /**
     * Persist delisted URLs to XML — marks source as status="delisted" but preserves entry
     */
    public void persistToXml()
    {
        if (delistedUrls.isEmpty()) return;

        try
        {
            File configFile = new File(CONFIG_PATH);
            DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
            Document doc = builder.parse(configFile);
            doc.getDocumentElement().normalize();

            NodeList cityNodes = doc.getElementsByTagName("city");
            for (int i = 0; i < cityNodes.getLength(); i++)
            {
                Element cityEl = (Element) cityNodes.item(i);
                if (!"true".equals(cityEl.getAttribute("selected"))) continue;

                NodeList sourceNodes = cityEl.getElementsByTagName("source");
                for (int j = 0; j < sourceNodes.getLength(); j++)
                {
                    Element sourceEl = (Element) sourceNodes.item(j);
                    String url = sourceEl.getTextContent().trim();
                    if (delistedUrls.contains(url))
                    {
                        sourceEl.setAttribute("status", "delisted");
                        sourceEl.setAttribute("delisted-code", String.valueOf(lastResponseCode.getOrDefault(url, 0)));
                        sourceEl.setAttribute("delisted-at", lastResponseTime.getOrDefault(url, ""));
                    }
                }

                // Also check primary URLs
                String[] primaryTags = {"deeds-url", "property-records-url", "register-of-deeds-url"};
                for (String tag : primaryTags)
                {
                    NodeList nodes = cityEl.getElementsByTagName(tag);
                    if (nodes.getLength() > 0)
                    {
                        Element el = (Element) nodes.item(0);
                        if (delistedUrls.contains(el.getTextContent().trim()))
                        {
                            el.setAttribute("status", "delisted");
                            el.setAttribute("delisted-code", String.valueOf(lastResponseCode.getOrDefault(el.getTextContent().trim(), 0)));
                        }
                    }
                }
            }

            Transformer transformer = TransformerFactory.newInstance().newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");
            transformer.transform(new DOMSource(doc), new StreamResult(configFile));

            System.out.println("-- : [ConnectionTracker] Persisted " + delistedUrls.size() + " delisted URLs to XML");
        }
        catch (Exception e)
        {
            System.err.println("-- : [ConnectionTracker] XML persist error: " + e.getMessage());
        }
    }

    /**
     * Print tracker summary
     */
    public void printSummary()
    {
        System.out.println("-- : [ConnectionTracker] Tracked " + lastResponseCode.size() + " connections, " + delistedUrls.size() + " delisted");
        for (String url : delistedUrls)
        {
            System.out.println("-- : [ConnectionTracker]   DELISTED: " + url + " (HTTP " + lastResponseCode.get(url) + ")");
        }
    }
}
