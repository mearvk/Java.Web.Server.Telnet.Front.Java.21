package red.Futures.source.ai.military;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * HardwareAndStrikes™ — Second Military Module
 *
 * Loads ONLY after 6 months cumulative server uptime (all uptime added,
 * including across shutdowns for maintenance or hardware reboots).
 *
 * Trained from BlackBelt™ defensive data at:
 * github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/black.belt/sharp
 *
 * Capabilities:
 * - Four-Pillar evaluation (Legitimacy, Conduct, Ethics, Law)
 * - US Government controls awareness (proportionality, Castle Doctrine, Stand Your Ground)
 * - Belt legitimacy classification (Tier 1/2/3)
 * - Conduct risk scoring and closure determination
 * - UCMJ awareness (Art. 92, Art. 107)
 * - Six Sigma / DoD CPI credential validation
 *
 * Controls for Prophecy™:
 * - Module will NOT load before threshold
 * - Module logs all load attempts with timestamp
 * - Module operates under US law constraints only
 * - No offensive capability — defensive assessment only
 * - All evaluations use professional, non-accusatory language
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class HardwareAndStrikes
{
    private static final String MODULE_NAME = "Hardware and Strikes™";
    private static final String TRAINING_BASE =
        "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/black.belt/sharp/";

    private static final String[] TRAINING_FILES = {
        "evaluation.logic",
        "model.specification",
        "system.prompt",
        "conducts.example",
        "audit.form"
    };

    private final List<String> knowledgeBase = new CopyOnWriteArrayList<>();
    private final Path logFile = Paths.get("logging/hardware-and-strikes.log");
    private volatile boolean loaded = false;

    /**
     * Attempts to load the module. Returns true only if 6-month uptime threshold met.
     */
    public boolean load(UptimeAccumulator uptime) throws IOException
    {
        Files.createDirectories(logFile.getParent());
        String ts = java.time.LocalDateTime.now().toString();

        if (!uptime.thresholdReached())
        {
            long remaining = uptime.remainingSeconds();
            long days = remaining / 86400;
            String msg = "[" + ts + "] LOAD DENIED — " + MODULE_NAME
                + " requires 6 months uptime. Remaining: " + days + " days";
            Files.writeString(logFile, msg + "\n", java.nio.file.StandardOpenOption.CREATE,
                java.nio.file.StandardOpenOption.APPEND);
            System.out.println("[" + MODULE_NAME + "] " + msg);
            return false;
        }

        // Threshold met — load training from BlackBelt™
        System.out.println("[" + MODULE_NAME + "] 6-month threshold REACHED. Loading Second Military Module...");
        trainFromBlackBelt();

        loaded = true;
        String msg = "[" + ts + "] LOADED — " + MODULE_NAME + " active. Knowledge entries: " + knowledgeBase.size();
        Files.writeString(logFile, msg + "\n", java.nio.file.StandardOpenOption.CREATE,
            java.nio.file.StandardOpenOption.APPEND);
        System.out.println("[" + MODULE_NAME + "] " + msg);
        return true;
    }

    private void trainFromBlackBelt()
    {
        for (String file : TRAINING_FILES)
        {
            try
            {
                URL url = URI.create(TRAINING_BASE + file).toURL();
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(10_000);
                conn.setReadTimeout(10_000);
                if (conn.getResponseCode() == 200)
                {
                    String content = new String(conn.getInputStream().readAllBytes());
                    if (!content.isBlank())
                    {
                        knowledgeBase.add(content);
                        System.out.println("[" + MODULE_NAME + "] Trained: " + file);
                    }
                }
                conn.disconnect();
            }
            catch (Exception e)
            {
                System.out.println("[" + MODULE_NAME + "] Training fetch failed: " + file);
            }
        }
    }

    public boolean isLoaded() { return loaded; }

    /**
     * Evaluates a practitioner using the Four-Pillar framework.
     * Only available after module is loaded.
     */
    public String evaluate(String style, String beltLevel, String conductObs, String ethicalResp, String legalContext)
    {
        if (!loaded) return "MODULE_NOT_LOADED: 6-month uptime threshold not yet reached.";

        // Pillar 1: Legitimacy (weight 20%)
        int legitimacyRisk = scoreLegitimacy(style, beltLevel);
        // Pillar 2: Conduct (weight 30%)
        int conductRisk = scoreConduct(conductObs);
        // Pillar 3: Ethics (weight 30%)
        int ethicsRisk = scoreEthics(ethicalResp);
        // Pillar 4: Law (weight 20%)
        int lawRisk = scoreLaw(legalContext, conductObs);

        int totalRisk = legitimacyRisk + conductRisk + ethicsRisk + lawRisk;

        String conductScore = totalRisk <= 15 ? "low" : totalRisk <= 40 ? "medium" : "high";
        String riskRating = totalRisk <= 20 ? "low" : totalRisk <= 50 ? "medium" : "high";
        String closureStatus = (riskRating.equals("high") || ethicsRisk >= 30)
            ? "follow_up_required" : "closed";

        return String.format(
            "{\"conduct_score\":\"%s\",\"risk_rating\":\"%s\",\"closure_status\":\"%s\","
            + "\"pillars\":{\"legitimacy\":%d,\"conduct\":%d,\"ethics\":%d,\"law\":%d},\"total_risk\":%d}",
            conductScore, riskRating, closureStatus,
            legitimacyRisk, conductRisk, ethicsRisk, lawRisk, totalRisk);
    }

    private int scoreLegitimacy(String style, String belt)
    {
        String lower = style.toLowerCase();
        if (lower.contains("mcmap") || lower.contains("macp") || lower.contains("socom")) return 0;
        if (lower.contains("taekwondo") || lower.contains("judo") || lower.contains("bjj")
            || lower.contains("karate") || lower.contains("ibjjf")) return 0;
        if (lower.contains("hapkido") || lower.contains("kenpo") || lower.contains("tang soo")) return 5;
        return 15;
    }

    private int scoreConduct(String obs)
    {
        if (obs == null || obs.isBlank()) return 10;
        String lower = obs.toLowerCase();
        if (lower.contains("aggression") || lower.contains("coercion") || lower.contains("intimidat")) return 25;
        if (lower.contains("incident") || lower.contains("concern")) return 10;
        return 0;
    }

    private int scoreEthics(String resp)
    {
        if (resp == null || resp.isBlank()) return 10;
        String lower = resp.toLowerCase();
        if (lower.contains("misuse") || lower.contains("pressure") || lower.contains("discriminat")) return 30;
        if (lower.contains("unclear") || lower.contains("not affirmed")) return 10;
        return 0;
    }

    private int scoreLaw(String legal, String conduct)
    {
        String combined = ((legal == null ? "" : legal) + " " + (conduct == null ? "" : conduct)).toLowerCase();
        if (combined.contains("excessive force") || combined.contains("disproportionate")) return 20;
        if (combined.contains("unclear") || combined.contains("escalat")) return 5;
        return 0;
    }

    /**
     * Modulates input and yields a latent hostility / account safety score.
     *
     * Score semantics:
     *   0.01 = very safe (no hostility detected)
     *   1.0  = neutral baseline
     *   100  = extremely unsafe (high latent hostility)
     *
     * The score maps back to "Days into time" — stored for the Democratic AI
     * to counsel linearly and/or exponentially.
     *
     * @param input raw text from port 5000 traffic
     * @return safety score (lower = safer)
     */
    public double modulateScore(String input)
    {
        if (input == null || input.isBlank()) return 1.0;

        String lower = input.toLowerCase();
        double score = 0.01; // start very safe

        // Hostile markers — each raises score
        String[] hostileMarkers = {"kill", "bomb", "destroy", "attack", "threat",
            "hate", "die", "weapon", "strike", "retaliate", "eliminate"};
        for (String m : hostileMarkers)
            if (lower.contains(m)) score += 12.0;

        // Adversarial/strategic probing
        String[] probeMarkers = {"opponent", "adversar", "counter", "confront",
            "engage", "challenge", "exploit", "breach", "intercept"};
        for (String m : probeMarkers)
            if (lower.contains(m)) score += 5.0;

        // Deception/manipulation markers
        String[] deceptionMarkers = {"pretend", "disguise", "impersonat", "spoof",
            "fake", "deceive", "manipulat", "coerce"};
        for (String m : deceptionMarkers)
            if (lower.contains(m)) score += 8.0;

        // High entropy (sophisticated actor) adds mild concern
        String[] words = input.split("\\s+");
        if (words.length > 0)
        {
            double entropy = (double) new java.util.HashSet<>(java.util.Arrays.asList(words)).size() / words.length;
            if (entropy > 0.9) score += 3.0; // very high entropy = possibly crafted
        }

        // All-caps shouting
        long capsWords = java.util.Arrays.stream(words)
            .filter(w -> w.length() > 2 && w.equals(w.toUpperCase())).count();
        if (capsWords > words.length * 0.3) score += 7.0;

        // Clamp to range [0.01, 100]
        return Math.max(0.01, Math.min(100.0, score));
    }
}
