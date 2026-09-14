package middle.director;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import java.io.File;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.List;

/**
 * Final medium-range hops before national module delivery.
 * Handles science conclusions, postulates, explorations, rich research,
 * and final commodities for grain review.
 *
 * IQ is forwarded as relevant — PhD-level structural methods (exact understanding)
 * are required for immediate approval; otherwise held for auditor review.
 */
public class FinalMediumHopsModule implements DirectorModule
{
    private static final String CONFIG = commons.AppRoot.resolveString("configuration/final-medium-hops-commodities.xml");

    private final List<Commodity> commodities = new CopyOnWriteArrayList<>();
    private int iqThreshold = 120;

    public FinalMediumHopsModule()
    {
        loadCommodities();
    }

    @Override public String name() { return "FinalMediumHops"; }

    @Override
    public String process(String input)
    {
        String cmd = input.trim().toLowerCase();
        for (Commodity c : commodities)
        {
            if (cmd.contains(c.name.toLowerCase()))
                return "[FinalMediumHop:" + c.name + "/" + c.type + "] " + input;
        }
        return "[FinalMediumHop] " + input;
    }

    /**
     * Process, evaluate (IQ + PhD required for structural sign-off), persist.
     */
    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat,
                                   int trustLevel, String educationLevel, int iq)
    {
        String commodityType = resolveCommodity(input);
        recordTrade(commodityType, nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);

        // PhD + IQ threshold for structural method exact understanding
        boolean phdLevel = "phd".equalsIgnoreCase(educationLevel != null ? educationLevel.trim() : "");
        boolean iqSufficient = iq >= iqThreshold;

        if (phdLevel && iqSufficient)
            return process(input) + " [APPROVED — PhD structural, IQ " + iq + "]";
        else if (phdLevel)
            return process(input) + " [APPROVED — PhD structural, IQ forwarded]";
        else
        {
            TradeEvaluator.evaluate(name(), commodityType, nationalId, trustLevel, educationLevel, input);
            return process(input) + " [HELD 48hrs — requires PhD-level exact understanding]";
        }
    }

    private String resolveCommodity(String input)
    {
        String cmd = input.trim().toLowerCase();
        for (Commodity c : commodities)
            if (cmd.contains(c.name.toLowerCase())) return c.name;
        return "research";
    }

    public List<Commodity> getCommodities() { return commodities; }

    private void loadCommodities()
    {
        try
        {
            File file = new File(CONFIG);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);

            // Load IQ threshold
            NodeList evalNodes = doc.getElementsByTagName("iq-threshold");
            if (evalNodes.getLength() > 0)
                iqThreshold = Integer.parseInt(((Element) evalNodes.item(0)).getAttribute("value"));

            // Load commodities
            NodeList nodes = doc.getElementsByTagName("commodity");
            for (int i = 0; i < nodes.getLength(); i++)
            {
                Element el = (Element) nodes.item(i);
                commodities.add(new Commodity(
                    el.getAttribute("name"),
                    el.getAttribute("type"),
                    el.getAttribute("description")
                ));
            }

            commons.CommonRails.printSystemComponent(this, this.hashCode(),
                ". FinalMediumHopsModule loaded " + commodities.size() + " commodities, IQ threshold " + iqThreshold + " .");
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    public static class Commodity
    {
        public final String name;
        public final String type;
        public final String description;

        public Commodity(String name, String type, String description)
        {
            this.name = name;
            this.type = type;
            this.description = description;
        }
    }
}
