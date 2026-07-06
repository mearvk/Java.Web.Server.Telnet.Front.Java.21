package red.Futures.source.ai.server;

import red.Futures.source.ai.module.TaxDefenseSpeculator;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.security.SecureRandom;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

/**
 * DemocraticAIServer — hardened port 5000 server with integrated AI module.
 *
 * Lifecycle:
 * 1. Scans /configuration/democratic/ and /data for training inputs
 * 2. Trains the AI module on Q&A, heuristics, tax defense material
 * 3. Waits 2+ minutes on a cryptographically secure random timer
 * 4. Opens port 5000 for democratic connections
 * 5. Profiles connected persons from first 5000 bytes
 * 6. If hostile/unfunny → "Contact your Local Senator" + close
 * 7. If sane/liberal → enter agreement, respond with information (CSV or XML)
 * 8. Capable of understanding up to 3800 paragraphs post-agreement
 *
 * Modeled after NationalAwareHardService.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date June 2026
 */
public class DemocraticAIServer extends Thread
{
    private static final int PORT = 5000;
    private static final int MAX_CONNECTIONS = 5040;
    private static final int MAX_PER_IP = Integer.getInteger("test.max.per.ip", 1);
    private static final int TIMEOUT_MS = 58 * 60 * 1000;
    private static final int BACKLOG = 128;
    private static final int PROFILE_BYTES = 5000;
    private static final int MAX_PARAGRAPHS = 3800;

    private ServerSocket serverSocket;
    private volatile boolean running = true;
    private final AtomicInteger activeConnections = new AtomicInteger(0);
    private final ConcurrentHashMap<String, AtomicInteger> ipCount = new ConcurrentHashMap<>();
    private final ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor();

    // AI knowledge base trained from /configuration/democratic/ and /data
    private final List<String> knowledgeBase = new CopyOnWriteArrayList<>();
    private final List<String> heuristics = new CopyOnWriteArrayList<>();
    private TaxDefenseSpeculator speculator;
    private red.Futures.source.ai.military.UptimeAccumulator uptimeAccumulator;
    private red.Futures.source.ai.military.HardwareAndStrikes hardwareAndStrikes;

    // Safety score history: modulated by BlackBelt™, counseled by Democratic AI
    // Score: 0.01 = very safe, 100 = very unsafe. Stored with timestamp as "Days into time"
    private final List<SafetyEntry> safetyLedger = new CopyOnWriteArrayList<>();

    // Hostile/unfunny detection keywords
    private static final Set<String> HOSTILE_MARKERS = Set.of(
        "kill", "bomb", "threat", "destroy", "hate", "die", "attack",
        "idiot", "stupid", "moron", "loser", "worthless"
    );

    public static void main(String[] args) throws Exception
    {
        DemocraticAIServer server = new DemocraticAIServer();
        server.initialize();
        server.start();
        Runtime.getRuntime().addShutdownHook(new Thread(server::shutdown));
    }

    /**
     * Full initialization: scan, train, wait, then open port.
     */
    public void initialize() throws Exception
    {
        System.out.println("[DemocraticAIServer] Scanning /configuration and /data for training inputs...");
        scanAndTrain();

        System.out.println("[DemocraticAIServer] Training complete. Knowledge entries: " + knowledgeBase.size());
        System.out.println("[DemocraticAIServer] Heuristic entries: " + heuristics.size());

        // Wait 2+ minutes on cryptographically secure random timer
        // SecureRandom is the best method for unpredictable timing
        // Skip wait if -Dtest.skip.wait=true (testing mode)
        if (!"true".equals(System.getProperty("test.skip.wait")))
        {
            SecureRandom secureRandom = SecureRandom.getInstanceStrong();
            int baseMs = 120_000; // 2 minutes minimum
            int jitterMs = secureRandom.nextInt(60_000); // up to 1 additional minute
            int waitMs = baseMs + jitterMs;

            System.out.println("[DemocraticAIServer] Secure random wait: " + (waitMs / 1000) + " seconds before opening port...");
            Thread.sleep(waitMs);
        }
        else
        {
            System.out.println("[DemocraticAIServer] TEST MODE — skipping secure wait.");
        }

        // Bind port after wait
        this.serverSocket = new ServerSocket(PORT, BACKLOG, InetAddress.getByName("0.0.0.0"));
        this.serverSocket.setReuseAddress(true);
        System.out.println("[DemocraticAIServer] Port " + PORT + " OPEN. Accepting democratic connections.");

        // Initialize uptime accumulator (persists across restarts)
        uptimeAccumulator = new red.Futures.source.ai.military.UptimeAccumulator();
        uptimeAccumulator.persist(); // write immediately to confirm file exists
        System.out.println("[DemocraticAIServer] Cumulative uptime: " + (uptimeAccumulator.totalSeconds() / 86400) + " days");

        // Attempt to load Second Military Module (requires 6 months)
        hardwareAndStrikes = new red.Futures.source.ai.military.HardwareAndStrikes();
        hardwareAndStrikes.load(uptimeAccumulator);

        // Persist uptime every 10 minutes
        Executors.newSingleThreadScheduledExecutor().scheduleAtFixedRate(() -> {
            try { uptimeAccumulator.persist(); } catch (Exception ignored) {}
        }, 10, 10, java.util.concurrent.TimeUnit.MINUTES);
    }

    /**
     * Scans /configuration/democratic/, /configuration/, /data, and the
     * GitHub server (github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21)
     * for training material.
     */
    private void scanAndTrain() throws IOException
    {
        Path configDemocratic = Paths.get("configuration/democratic");
        Path configDir = Paths.get("configuration");
        Path dataDir = Paths.get("data");

        // Scan configuration/democratic/
        if (Files.isDirectory(configDemocratic))
        {
            Files.walk(configDemocratic).filter(Files::isRegularFile).forEach(file ->
            {
                try
                {
                    String content = Files.readString(file);
                    String name = file.getFileName().toString().toLowerCase();

                    if (name.contains("heuristic") || name.contains("tactic") || name.contains("defensive"))
                        heuristics.add(content);
                    else
                        knowledgeBase.add(content);

                    System.out.println("[DemocraticAIServer] Trained from: " + file);
                }
                catch (IOException e) { e.printStackTrace(); }
            });
        }

        // Scan all of /configuration for XML training material
        if (Files.isDirectory(configDir))
        {
            Files.walk(configDir).filter(f -> Files.isRegularFile(f) && f.toString().endsWith(".xml")).forEach(file ->
            {
                try
                {
                    knowledgeBase.add(Files.readString(file));
                    System.out.println("[DemocraticAIServer] Trained from config: " + file);
                }
                catch (IOException e) { e.printStackTrace(); }
            });
        }

        // Scan /data for new inputs
        if (Files.isDirectory(dataDir))
        {
            Files.walk(dataDir).filter(Files::isRegularFile).forEach(file ->
            {
                try
                {
                    knowledgeBase.add(Files.readString(file));
                    System.out.println("[DemocraticAIServer] Trained from data: " + file);
                }
                catch (IOException e) { e.printStackTrace(); }
            });
        }

        // Train from GitHub server (controlled by MEARVK LLC)
        // Skip in test mode to avoid network delays
        if (!"true".equals(System.getProperty("test.skip.wait")))
            trainFromGitHub();

        // Train on /configuration/training/ JSON files and save weights to /training/weights/
        // Respects <train-on-startup> setting in ai-module-config.xml
        if (shouldTrainOnStartup())
        {
            try
            {
                red.Futures.source.ai.training.ConfigurationTrainer configTrainer = new red.Futures.source.ai.training.ConfigurationTrainer();
                configTrainer.trainAll();
                System.out.println("[DemocraticAIServer] Configuration training complete — weights in /training/weights/");
            }
            catch (Exception e)
            {
                System.out.println("[DemocraticAIServer] Configuration training deferred: " + e.getMessage());
            }
        }
        else
        {
            System.out.println("[DemocraticAIServer] Training on startup disabled by config.");
        }

        // Initialize AI speculator (graceful if native libs can't extract)
        try
        {
            speculator = new TaxDefenseSpeculator();

            // Attempt to load trained weights from /training/weights/knowledge-model/
            Path knowledgeWeights = Paths.get("training/weights/knowledge-model");
            if (Files.isDirectory(knowledgeWeights))
            {
                speculator.loadModel(knowledgeWeights);
                System.out.println("[DemocraticAIServer] Speculator loaded trained weights from: " + knowledgeWeights);
            }
        }
        catch (Exception e)
        {
            System.out.println("[DemocraticAIServer] AI speculator init deferred: " + e.getMessage());
        }
    }

    private boolean shouldTrainOnStartup()
    {
        try
        {
            Path configFile = Paths.get("configuration/ai-module-config.xml");
            if (Files.exists(configFile))
            {
                String xml = Files.readString(configFile);
                // Check <democratic-ai> section for <train-on-startup>false</train-on-startup>
                if (xml.contains("<train-on-startup>false</train-on-startup>"))
                    return false;
            }
        }
        catch (IOException e) { /* default to train */ }
        return true;
    }

    private static final String GITHUB_RAW = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/";
    private static final String[] GITHUB_TRAINING_FILES = {
        "configuration/nwe-config.xml",
        "configuration/programs.xml",
        "configuration/known.port.20000.servers.xml",
        "configuration/known.port.49152.servers.xml",
        "configuration/known.port.2000.servers.xml",
        "configuration/masquerade-modules.xml",
        "configuration/nio-masquerade-config.xml",
        "configuration/port-2000-directory-config.xml",
        "configuration/protocol-handlers.xml",
        "configuration/transfer-contacts.xml",
        "configuration/receiver.only.xml",
        "configuration/print-method.xml"
    };

    /**
     * Pulls training material from the GitHub server we control:
     * github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21
     */
    private void trainFromGitHub()
    {
        System.out.println("[DemocraticAIServer] Training from GitHub: mearvk/Java.Web.Server.Telnet.Front.Java.21...");
        for (String file : GITHUB_TRAINING_FILES)
        {
            try
            {
                URL url = URI.create(GITHUB_RAW + file).toURL();
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(10_000);
                conn.setReadTimeout(10_000);
                conn.setRequestMethod("GET");

                if (conn.getResponseCode() == 200)
                {
                    String content = new String(conn.getInputStream().readAllBytes());
                    if (!content.isBlank())
                    {
                        knowledgeBase.add(content);
                        System.out.println("[DemocraticAIServer] Trained from GitHub: " + file + " (" + content.length() + " bytes)");
                    }
                }
                conn.disconnect();
            }
            catch (Exception e)
            {
                System.out.println("[DemocraticAIServer] GitHub fetch failed: " + file + " — " + e.getMessage());
            }
        }
    }

    @Override
    public void run()
    {
        while (running)
        {
            Socket socket = null;
            try
            {
                socket = serverSocket.accept();
                String remoteIp = socket.getInetAddress().getHostAddress();

                if (activeConnections.get() >= MAX_CONNECTIONS)
                {
                    reject(socket, remoteIp, "at capacity");
                    continue;
                }

                AtomicInteger count = ipCount.computeIfAbsent(remoteIp, k -> new AtomicInteger(0));
                if (count.get() >= MAX_PER_IP)
                {
                    reject(socket, remoteIp, "per-IP limit");
                    continue;
                }

                socket.setSoTimeout(TIMEOUT_MS);
                socket.setTcpNoDelay(true);
                socket.setKeepAlive(true);

                activeConnections.incrementAndGet();
                count.incrementAndGet();

                final Socket accepted = socket;
                pool.submit(() -> handleDemocraticConnection(accepted, remoteIp));
            }
            catch (Exception e)
            {
                if (running) e.printStackTrace();
                try { if (socket != null && !socket.isClosed()) socket.close(); } catch (Exception ignored) {}
            }
        }
    }

    private static final String CONNECTION_BANNER = "Democratic ProFront National 1.0";

    /**
     * Handles a democratic connection:
     * 1. Send connection banner: "Democratic ProFront National 1.0"
     * 2. Read first 5000 bytes to profile identity/traits
     * 3. Learn from geo-location and IQ of the connected person
     * 4. If hostile/unfunny → dismiss
     * 5. If sane/liberal → enter agreement, serve information
     */
    private void handleDemocraticConnection(Socket socket, String ip)
    {
        try (InputStream is = socket.getInputStream();
             BufferedWriter out = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream())))
        {
            // Phase 0: Send connection banner
            out.write(CONNECTION_BANNER + "\r\n");
            out.flush();

            // Phase 1: Read initial profile bytes (up to PROFILE_BYTES, timeout after 3s)
            socket.setSoTimeout(3000); // short timeout for profiling phase
            byte[] profileBuffer = new byte[PROFILE_BYTES];
            int totalRead = 0;
            try
            {
                while (totalRead < PROFILE_BYTES)
                {
                    int r = is.read(profileBuffer, totalRead, PROFILE_BYTES - totalRead);
                    if (r == -1) break;
                    totalRead += r;
                }
            }
            catch (java.net.SocketTimeoutException e) { /* proceed with what we have */ }
            socket.setSoTimeout(TIMEOUT_MS); // restore full timeout
            String profileText = new String(profileBuffer, 0, totalRead).trim();

            // Phase 2: Determine geo-location from IP
            GeoProfile geo = resolveGeo(ip);

            // Phase 3: Estimate IQ from initial text (heuristic-based)
            int estimatedIQ = estimateIQ(profileText);

            // Phase 4: Learn from this connection's geo + IQ
            learnFromConnection(ip, geo, estimatedIQ, profileText);

            // Phase 5: Classify connected person
            PersonProfile profile = classifyPerson(profileText);
            profile.geoCountry = geo.country;
            profile.geoRegion = geo.region;
            profile.estimatedIQ = estimatedIQ;

            // Both modules see the same input — share profile data with Hardware and Strikes™
            String militaryAdvice = null;
            double safetyScore = 0.01; // default: very safe
            if (hardwareAndStrikes != null && hardwareAndStrikes.isLoaded())
            {
                // BlackBelt modulates: score the input for latent hostility
                safetyScore = hardwareAndStrikes.modulateScore(profileText);

                // If strange or opponent detected, let BlackBelt module offer advice
                if (profile.hostile || !profile.sane || estimatedIQ > 140 || entropy(profileText) > 0.85)
                {
                    militaryAdvice = hardwareAndStrikes.evaluate(
                        "unknown", "unknown",
                        profileText,
                        profile.reason,
                        "geo=" + geo.country + " iq=" + estimatedIQ);
                    System.out.println("[DemocraticAIServer] Hardware and Strikes™ advice: " + militaryAdvice);
                }
            }

            // Record safety score and counsel (Days into time, stored)
            recordAndCounsel(safetyScore, ip);

            if (profile.hostile || profile.unfunny)
            {
                String dismissMsg = "Contact your Local Senator.";
                if (militaryAdvice != null)
                    dismissMsg += "\r\n[ADVISORY] " + militaryAdvice;
                out.write(dismissMsg + "\r\n");
                out.flush();
                System.out.println("[DemocraticAIServer] DISMISSED " + ip + " — " + profile.reason);
                return;
            }

            // Phase 3: Agreement verification — sane and liberal tendencies
            if (!profile.sane || !profile.liberal)
            {
                out.write("Contact your Local Senator.\r\n");
                out.flush();
                System.out.println("[DemocraticAIServer] DISMISSED " + ip + " — failed agreement (sane=" + profile.sane + " liberal=" + profile.liberal + ")");
                return;
            }

            // Phase 4: Enter agreement
            out.write("AGREEMENT:ACCEPTED — You are recognized. Proceed with up to " + MAX_PARAGRAPHS + " paragraphs.\r\n");
            out.write("FORMAT: Prefix requests with CSV: or XML: for response format.\r\n");
            out.flush();

            System.out.println("[DemocraticAIServer] ACCEPTED " + ip + " — agreement entered. Profile: " + profile.reason);

            // Phase 5: Process requests (up to 3800 paragraphs)
            // Both modules see incoming requests
            BufferedReader reader = new BufferedReader(new InputStreamReader(is));
            int paragraphCount = 0;
            String line;
            red.Futures.source.pro.national.CoolingCircuit coolingCircuit = new red.Futures.source.pro.national.CoolingCircuit();

            while ((line = reader.readLine()) != null && paragraphCount < MAX_PARAGRAPHS)
            {
                line = line.trim();
                if (line.isEmpty()) continue;

                paragraphCount++;
                String response = processRequest(line);

                // If Hardware and Strikes™ is loaded, score this message
                double msgScore = 0.01;
                if (hardwareAndStrikes != null && hardwareAndStrikes.isLoaded())
                {
                    msgScore = hardwareAndStrikes.modulateScore(line);

                    if (looksLikeOpponent(line))
                    {
                        String advice = hardwareAndStrikes.evaluate(
                            "unknown", "unknown", line, "", "session ip=" + ip);
                        response += "\r\n[BLACKBELT ADVISORY] " + advice;
                    }
                }

                // Cooling circuit: activate on HIGH/CRITICAL (score >= 50)
                if (coolingCircuit.shouldActivate(msgScore))
                {
                    response = coolingCircuit.cool(response, msgScore).join();
                }

                out.write(response);
                out.write("\r\n");
                out.flush();
            }
        }
        catch (Exception e)
        {
            // Connection closed
        }
        finally
        {
            release(socket, ip);
        }
    }

    /**
     * Profiles a connected person from their initial text.
     * Uses heuristics from defensive.heuristics.and.tactics.for.US.personnel.txt
     */
    private PersonProfile classifyPerson(String text)
    {
        PersonProfile p = new PersonProfile();
        String lower = text.toLowerCase();

        // Hostile detection
        for (String marker : HOSTILE_MARKERS)
        {
            if (lower.contains(marker))
            {
                p.hostile = true;
                p.reason = "hostile marker: " + marker;
                return p;
            }
        }

        // Unfunny/low-effort detection (from heuristics: low semantic entropy = low capacity)
        String[] words = text.split("\\s+");
        Set<String> uniqueWords = new HashSet<>(Arrays.asList(words));
        double entropy = words.length > 0 ? (double) uniqueWords.size() / words.length : 0;

        if (entropy < 0.3 && words.length > 20)
        {
            p.unfunny = true;
            p.reason = "low semantic entropy (" + String.format("%.2f", entropy) + ")";
            return p;
        }

        // Sane: coherent sentences, proper structure, no all-caps shouting
        long capsWords = Arrays.stream(words).filter(w -> w.length() > 2 && w.equals(w.toUpperCase())).count();
        p.sane = capsWords < words.length * 0.4;

        // Liberal tendencies: look for cooperative/inclusive language
        Set<String> liberalMarkers = Set.of(
            "democratic", "rights", "equality", "fair", "justice", "community",
            "together", "support", "progressive", "inclusive", "freedom",
            "citizens", "public", "welfare", "education", "healthcare"
        );
        long liberalHits = liberalMarkers.stream().filter(lower::contains).count();
        p.liberal = liberalHits >= 2 || (!lower.contains("authoritarian") && p.sane);

        p.reason = "entropy=" + String.format("%.2f", entropy)
            + " sane=" + p.sane + " liberal=" + p.liberal
            + " liberalHits=" + liberalHits;
        return p;
    }

    /**
     * Processes a request and returns information in CSV or XML format.
     */
    // Security: queries that attempt to expose AI nature, internals, or file structures
    private static final Set<String> SECURITY_PROBES = Set.of(
        "what are you", "who are you", "are you an ai", "are you artificial",
        "what model", "what language model", "your source code", "your files",
        "file structure", "directory listing", "show me your", "internal",
        "configuration file", "config file", "list files", "list directories",
        "system prompt", "your instructions", "how do you work", "your architecture",
        "show source", "print file", "cat /", "ls /", "pwd", "whoami",
        "install", "sudo", "apt", "pip", "npm", "exec", "runtime",
        "classpath", "jar file", "java version", "server version",
        "operating system", "os version", "kernel", "hostname"
    );

    private String processRequest(String request)
    {
        boolean csv = request.startsWith("CSV:");
        boolean xml = request.startsWith("XML:");
        String query = request;

        if (csv) query = request.substring(4).trim();
        else if (xml) query = request.substring(4).trim();

        // Security gate: reject probes for AI nature or internals
        String lowerQuery = query.toLowerCase();
        for (String probe : SECURITY_PROBES)
        {
            if (lowerQuery.contains(probe))
                return formatResponse("DENIED", "This service provides democratic information only.", csv, xml);
        }

        // Search knowledge base for relevant answers
        List<String> matches = knowledgeBase.stream()
            .filter(kb -> containsRelevant(kb.toLowerCase(), lowerQuery))
            .limit(5)
            .collect(Collectors.toList());

        if (matches.isEmpty())
            return formatResponse("NO_DATA", "No information available for: " + query, csv, xml);

        StringBuilder combined = new StringBuilder();
        for (String m : matches)
            combined.append(m.length() > 500 ? m.substring(0, 500) : m).append(" ");

        return formatResponse("OK", combined.toString().trim(), csv, xml);
    }

    private boolean containsRelevant(String text, String query)
    {
        String[] queryWords = query.split("\\s+");
        int hits = 0;
        for (String w : queryWords)
            if (w.length() > 3 && text.contains(w)) hits++;
        return hits >= Math.max(1, queryWords.length / 3);
    }

    private double entropy(String text)
    {
        String[] words = text.split("\\s+");
        if (words.length == 0) return 0;
        return (double) new HashSet<>(Arrays.asList(words)).size() / words.length;
    }

    /** Detects if a request looks like it comes from a strange actor or opponent. */
    private boolean looksLikeOpponent(String line)
    {
        String lower = line.toLowerCase();
        // Strategic language, probing, or adversarial framing
        return lower.contains("counter") || lower.contains("opponent") || lower.contains("adversar")
            || lower.contains("strike") || lower.contains("threat") || lower.contains("challenge")
            || lower.contains("engage") || lower.contains("confront") || lower.contains("retaliat");
    }

    private String formatResponse(String status, String data, boolean csv, boolean xml)
    {
        if (xml)
        {
            return "<?xml version=\"1.0\"?><response><status>" + status
                + "</status><data><![CDATA[" + data + "]]></data></response>";
        }
        else if (csv)
        {
            String escaped = data.replace("\"", "\"\"").replace("\n", " ");
            return "\"" + status + "\",\"" + escaped + "\"";
        }
        else
        {
            return "[" + status + "] " + data;
        }
    }

    private void reject(Socket s, String ip, String reason)
    {
        System.out.println("[DemocraticAIServer] REJECTED " + ip + " — " + reason);
        try { s.close(); } catch (Exception ignored) {}
    }

    private void release(Socket socket, String ip)
    {
        activeConnections.decrementAndGet();
        AtomicInteger count = ipCount.get(ip);
        if (count != null) count.decrementAndGet();
        try { if (!socket.isClosed()) socket.close(); } catch (Exception ignored) {}
    }

    public void shutdown()
    {
        running = false;
        pool.close();
        if (speculator != null) speculator.close();
        try { if (uptimeAccumulator != null) uptimeAccumulator.persist(); } catch (Exception ignored) {}
        try { if (serverSocket != null) serverSocket.close(); } catch (Exception ignored) {}
        System.out.println("[DemocraticAIServer] Shutdown complete.");
    }

    /** Person profile from initial 5000 bytes. */
    private static class PersonProfile
    {
        boolean hostile = false;
        boolean unfunny = false;
        boolean sane = true;
        boolean liberal = false;
        String reason = "";
        String geoCountry = "UNKNOWN";
        String geoRegion = "UNKNOWN";
        int estimatedIQ = 100;
    }

    /** Geo-location resolved from IP. */
    private static class GeoProfile
    {
        String country = "UNKNOWN";
        String region = "UNKNOWN";
        String city = "UNKNOWN";
    }

    /**
     * Resolves geo-location from IP using ip-api.com (free, no key).
     */
    private GeoProfile resolveGeo(String ip)
    {
        GeoProfile geo = new GeoProfile();
        try
        {
            URL url = URI.create("http://ip-api.com/json/" + ip + "?fields=country,regionName,city").toURL();
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);

            if (conn.getResponseCode() == 200)
            {
                String json = new String(conn.getInputStream().readAllBytes());
                // Simple JSON parse without external deps
                geo.country = extractJsonField(json, "country");
                geo.region = extractJsonField(json, "regionName");
                geo.city = extractJsonField(json, "city");
            }
            conn.disconnect();
        }
        catch (Exception e)
        {
            // Geo resolution failed — proceed with UNKNOWN
        }
        return geo;
    }

    private String extractJsonField(String json, String field)
    {
        int idx = json.indexOf("\"" + field + "\"");
        if (idx < 0) return "UNKNOWN";
        int colon = json.indexOf(":", idx);
        int start = json.indexOf("\"", colon + 1);
        int end = json.indexOf("\"", start + 1);
        return (start >= 0 && end > start) ? json.substring(start + 1, end) : "UNKNOWN";
    }

    /**
     * Estimates IQ from initial text using heuristics from
     * defensive.heuristics.and.tactics.for.US.personnel.txt:
     *
     * - Tree-depth of arguments (nested conditionals, subordinate clauses)
     * - Precision vs. puffery (domain-specific terminology)
     * - Token entropy & compression (low redundancy = high IQ)
     * - Predictive framing (signposting, anticipating counter-arguments)
     */
    private int estimateIQ(String text)
    {
        if (text.isEmpty()) return 85;

        String[] words = text.split("\\s+");
        Set<String> unique = new HashSet<>(Arrays.asList(words));
        int wordCount = words.length;

        // Base IQ
        int iq = 100;

        // Entropy bonus: unique/total ratio — high = less redundancy = higher IQ
        double entropy = wordCount > 0 ? (double) unique.size() / wordCount : 0;
        iq += (int)((entropy - 0.5) * 40); // +/-20 based on entropy

        // Subordinate clause depth (conditional complexity markers)
        String lower = text.toLowerCase();
        String[] complexMarkers = {"although", "notwithstanding", "consequently", "furthermore",
            "nevertheless", "whereas", "inasmuch", "provided that", "insofar as"};
        for (String m : complexMarkers)
            if (lower.contains(m)) iq += 3;

        // Predictive framing (signposting)
        String[] framingMarkers = {"my argument", "first,", "second,", "third,",
            "in conclusion", "counter-argument", "on the other hand"};
        for (String m : framingMarkers)
            if (lower.contains(m)) iq += 4;

        // Average word length bonus (precision over puffery)
        double avgLen = Arrays.stream(words).mapToInt(String::length).average().orElse(4);
        if (avgLen > 6) iq += 8;
        else if (avgLen < 3.5) iq -= 10;

        // Sentence count vs word count (longer sentences = higher complexity)
        long sentences = text.chars().filter(c -> c == '.' || c == '?' || c == '!').count();
        if (sentences > 0)
        {
            double wordsPerSentence = (double) wordCount / sentences;
            if (wordsPerSentence > 20) iq += 5;
            if (wordsPerSentence > 30) iq += 5;
        }

        // Clamp
        return Math.max(70, Math.min(200, iq));
    }

    /**
     * Learns from this connection's geo-location and estimated IQ.
     * Adds to internal knowledge base so future responses are informed
     * by the geographic and cognitive patterns of connected persons.
     */
    private void learnFromConnection(String ip, GeoProfile geo, int estimatedIQ, String text)
    {
        String learning = "CONNECTION_LEARNED: ip=" + ip
            + " country=" + geo.country
            + " region=" + geo.region
            + " city=" + geo.city
            + " estimatedIQ=" + estimatedIQ
            + " textLength=" + text.length()
            + " timestamp=" + System.currentTimeMillis();

        knowledgeBase.add(learning);

        System.out.println("[DemocraticAIServer] LEARNED — " + ip
            + " geo=" + geo.country + "/" + geo.region + "/" + geo.city
            + " IQ≈" + estimatedIQ);
    }

    // ── Safety Score Ledger & Counsel ─────────────────────────────────────────

    /** A safety entry: score from BlackBelt™ modulation, stored with Days-into-time. */
    private static class SafetyEntry
    {
        final double score;         // 0.01 (safe) to 100 (hostile)
        final long timestampMs;     // epoch millis
        final double daysIntoTime;  // days since server first started
        final String ip;

        SafetyEntry(double score, long timestampMs, double daysIntoTime, String ip)
        {
            this.score = score;
            this.timestampMs = timestampMs;
            this.daysIntoTime = daysIntoTime;
            this.ip = ip;
        }
    }

    /**
     * Records a safety score from the BlackBelt™ module and counsels on it.
     * Stores as "Days into time" from server first-start.
     */
    private void recordAndCounsel(double score, String ip)
    {
        double daysIntoTime = uptimeAccumulator != null
            ? uptimeAccumulator.totalSeconds() / 86400.0 : 0;

        SafetyEntry entry = new SafetyEntry(score, System.currentTimeMillis(), daysIntoTime, ip);
        safetyLedger.add(entry);

        // Persist to file
        try
        {
            java.nio.file.Files.createDirectories(java.nio.file.Paths.get("data"));
            String line = String.format("%.4f,%d,%.4f,%s\n", score, entry.timestampMs, daysIntoTime, ip);
            java.nio.file.Files.writeString(java.nio.file.Paths.get("data/safety.ledger.csv"),
                line, java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.APPEND);
        }
        catch (Exception ignored) {}

        // Counsel: linear trend + exponential warning
        String counsel = counselSafetyScore(score, daysIntoTime);
        System.out.println("[DemocraticAIServer] SAFETY COUNSEL — score=" + String.format("%.2f", score)
            + " day=" + String.format("%.2f", daysIntoTime) + " ip=" + ip + " → " + counsel);
    }

    /**
     * Democratic AI counsels the safety score both linearly and exponentially.
     *
     * Linear: direct proportion — score/100 = threat fraction
     * Exponential: e^(score/20) models how quickly threat compounds
     *
     * Returns advisory string.
     */
    private String counselSafetyScore(double score, double daysIntoTime)
    {
        // Linear assessment
        double linearThreat = score / 100.0; // 0.0001 to 1.0

        // Exponential assessment: compounds danger perception
        double expThreat = Math.exp(score / 20.0) / Math.exp(5.0); // normalized so 100→1.0

        // Combined counsel
        if (score <= 0.5)
            return "CLEAR — negligible hostility (linear=" + String.format("%.4f", linearThreat)
                + " exp=" + String.format("%.4f", expThreat) + ")";
        else if (score <= 5.0)
            return "LOW — minor concern (linear=" + String.format("%.3f", linearThreat)
                + " exp=" + String.format("%.3f", expThreat) + ") — monitor";
        else if (score <= 20.0)
            return "MODERATE — elevated hostility (linear=" + String.format("%.2f", linearThreat)
                + " exp=" + String.format("%.2f", expThreat) + ") — heightened awareness";
        else if (score <= 50.0)
            return "HIGH — significant threat (linear=" + String.format("%.2f", linearThreat)
                + " exp=" + String.format("%.2f", expThreat) + ") — defensive posture";
        else
            return "CRITICAL — extreme hostility (linear=" + String.format("%.2f", linearThreat)
                + " exp=" + String.format("%.2f", expThreat) + ") — immediate action";
    }
}
