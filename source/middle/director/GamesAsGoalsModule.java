package middle.director;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import java.io.File;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.List;

/**
 * Games As Goals Module — takes in roughing sketches for angular math (.mdmd).
 * Reviewable for composure value and trade value.
 *
 * Submissions gated by IQ:
 *   - IQ 150+ : standard acceptance
 *   - IQ 125+ : accepted if NationalID overall value is good (trust >= 70)
 *   - Below 125: rejected
 */
public class GamesAsGoalsModule implements DirectorModule
{
    private static final String CONFIG = "configuration/games-as-goals-sketches.xml";

    private final List<Trade> trades = new CopyOnWriteArrayList<>();
    private int iqStandard = 150;
    private int iqLowered = 125;
    private int trustMinForLowered = 70;

    public GamesAsGoalsModule()
    {
        loadConfig();
    }

    @Override public String name() { return "GamesAsGoals"; }

    @Override
    public String process(String input)
    {
        String cmd = input.trim().toLowerCase();
        for (Trade t : trades)
        {
            if (cmd.contains(t.name.toLowerCase()))
                return "[GameGoal:" + t.name + "/" + t.type + "] " + input;
        }
        return "[GameGoal] " + input;
    }

    /**
     * Process with IQ gating for .mdmd sketch submissions.
     */
    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat,
                                   int trustLevel, String educationLevel, int iq)
    {
        String tradeType = resolveTradeType(input);
        recordTrade(tradeType, nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);

        // IQ gating
        if (iq >= iqStandard)
            return process(input) + " [ACCEPTED — IQ " + iq + " meets standard]";
        else if (iq >= iqLowered && trustLevel >= trustMinForLowered)
            return process(input) + " [ACCEPTED — IQ " + iq + ", good NationalID value (trust " + trustLevel + ")]";
        else if (iq >= iqLowered)
        {
            TradeEvaluator.evaluate(name(), tradeType, nationalId, trustLevel, educationLevel, input);
            return process(input) + " [HELD 48hrs — IQ " + iq + " but NationalID value insufficient (trust " + trustLevel + ")]";
        }
        else
            return process(input) + " [REJECTED — IQ " + iq + " below minimum " + iqLowered + "]";
    }

    private String resolveTradeType(String input)
    {
        String cmd = input.trim().toLowerCase();
        for (Trade t : trades)
            if (cmd.contains(t.name.toLowerCase())) return t.name;
        return "sketch";
    }

    public List<Trade> getTrades() { return trades; }

    private void loadConfig()
    {
        try
        {
            File file = new File(CONFIG);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);

            NodeList iqNodes = doc.getElementsByTagName("iq-standard");
            if (iqNodes.getLength() > 0)
                iqStandard = Integer.parseInt(((Element) iqNodes.item(0)).getAttribute("value"));

            NodeList iqLow = doc.getElementsByTagName("iq-lowered");
            if (iqLow.getLength() > 0)
                iqLowered = Integer.parseInt(((Element) iqLow.item(0)).getAttribute("value"));

            NodeList trustNodes = doc.getElementsByTagName("trust-minimum-for-lowered");
            if (trustNodes.getLength() > 0)
                trustMinForLowered = Integer.parseInt(((Element) trustNodes.item(0)).getAttribute("value"));

            NodeList nodes = doc.getElementsByTagName("trade");
            for (int i = 0; i < nodes.getLength(); i++)
            {
                Element el = (Element) nodes.item(i);
                trades.add(new Trade(
                    el.getAttribute("name"),
                    el.getAttribute("type"),
                    el.getAttribute("description")
                ));
            }

            commons.CommonRails.printSystemComponent(this, this.hashCode(),
                ". GamesAsGoalsModule loaded " + trades.size() + " trades, IQ standard=" + iqStandard + " lowered=" + iqLowered + " .");
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    public static class Trade
    {
        public final String name;
        public final String type;
        public final String description;

        public Trade(String name, String type, String description)
        {
            this.name = name;
            this.type = type;
            this.description = description;
        }
    }
}
