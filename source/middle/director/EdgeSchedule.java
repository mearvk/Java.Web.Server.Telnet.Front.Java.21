package middle.director;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import java.io.File;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Weighted Edge Schedule for Middle Director modules.
 *
 * Default weights: SHM=1, MHM=4, TAGM=6, GAGM=8, ACM=19.
 *
 * LOCKED: Independent/non-central NWE installations may only alter these
 * weights with explicit approval from central NWEs (github.com/mearvk).
 * Approval is verified via GitHub personal access token against the
 * central repository.
 */
public class EdgeSchedule
{
    private static final String CONFIG = "configuration/edge-schedule.xml";
    private static final String CENTRAL_REPO = "mearvk/Java.Web.Server.Telnet.Front.Java.21";
    private static final String GITHUB_API = "https://api.github.com/repos/" + CENTRAL_REPO;

    /** Module name → edge weight. */
    private static final Map<String, Integer> WEIGHTS = new LinkedHashMap<>();

    static
    {
        // Defaults
        WEIGHTS.put("ShortHops", 1);
        WEIGHTS.put("MediumHops", 4);
        WEIGHTS.put("ThoughtsAsGoals", 6);
        WEIGHTS.put("GamesAsGoals", 8);
        WEIGHTS.put("AuditorContent", 19);
        loadFromXml();
    }

    public static int getWeight(String moduleName)
    {
        return WEIGHTS.getOrDefault(moduleName, 0);
    }

    public static Map<String, Integer> getAllWeights()
    {
        return Map.copyOf(WEIGHTS);
    }

    /**
     * Attempt to alter a weight. Requires valid central NWE access token.
     * Only succeeds if the token authenticates against github.com/mearvk.
     *
     * @return true if alteration approved and applied, false otherwise.
     */
    public static boolean alterWeight(String moduleName, int newWeight, String accessToken)
    {
        if (accessToken == null || accessToken.isBlank())
            return false;

        if (!verifyCentralAuthority(accessToken))
            return false;

        WEIGHTS.put(moduleName, newWeight);

        commons.CommonRails.printSystemComponent(new EdgeSchedule(), 0,
            ". EdgeSchedule: weight for " + moduleName + " altered to " + newWeight + " (central approved) .");

        return true;
    }

    /**
     * Verify token against central NWE repository (github.com/mearvk).
     * Token must have repo access to the central repository.
     */
    private static boolean verifyCentralAuthority(String token)
    {
        try
        {
            HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(GITHUB_API))
                .header("Authorization", "Bearer " + token)
                .header("Accept", "application/vnd.github+json")
                .GET()
                .build();

            HttpResponse<String> resp = HttpClient.newHttpClient()
                .send(req, HttpResponse.BodyHandlers.ofString());

            // 200 = token has access to central repo = authorized
            return resp.statusCode() == 200;
        }
        catch (Exception e)
        {
            return false;
        }
    }

    private static void loadFromXml()
    {
        try
        {
            File file = new File(CONFIG);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            NodeList nodes = doc.getElementsByTagName("weight");

            for (int i = 0; i < nodes.getLength(); i++)
            {
                Element el = (Element) nodes.item(i);
                WEIGHTS.put(el.getAttribute("module"), Integer.parseInt(el.getAttribute("value")));
            }
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }
}
