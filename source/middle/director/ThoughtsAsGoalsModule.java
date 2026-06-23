package middle.director;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import java.io.File;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.List;

/**
 * Thoughts As Goals Module — captures trades about weights and notions
 * that cool to formulations for further review.
 * Includes women as they trade in sex with rated/weighted value thereupon.
 * The thought is then captured and persisted.
 */
public class ThoughtsAsGoalsModule implements DirectorModule
{
    private static final String CONFIG = commons.AppRoot.resolveString("configuration/thoughts-as-goals-trades.xml");

    private final List<Trade> trades = new CopyOnWriteArrayList<>();

    public ThoughtsAsGoalsModule()
    {
        loadTrades();
    }

    @Override public String name() { return "ThoughtsAsGoals"; }

    @Override
    public String process(String input)
    {
        String cmd = input.trim().toLowerCase();
        for (Trade t : trades)
        {
            if (cmd.contains(t.name.toLowerCase()))
                return "[ThoughtGoal:" + t.name + "/" + t.type + "] " + input;
        }
        return "[ThoughtGoal] " + input;
    }

    public String processAndRecord(String input, long nationalId, String ip,
                                   String publicKey, long signatoryId, String signatoryKey,
                                   boolean employed, boolean democrat,
                                   int trustLevel, String educationLevel)
    {
        String tradeType = resolveTradeType(input);
        recordTrade(tradeType, nationalId, ip, publicKey, signatoryId, signatoryKey, employed, democrat);
        return evaluateAndProcess(input, tradeType, nationalId, trustLevel, educationLevel);
    }

    private String resolveTradeType(String input)
    {
        String cmd = input.trim().toLowerCase();
        for (Trade t : trades)
            if (cmd.contains(t.name.toLowerCase())) return t.name;
        return "thought";
    }

    public List<Trade> getTrades() { return trades; }

    private void loadTrades()
    {
        try
        {
            File file = new File(CONFIG);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
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
                ". ThoughtsAsGoalsModule loaded " + trades.size() + " trade types from XML .");
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
