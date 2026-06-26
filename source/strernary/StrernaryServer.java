/**
 * StrernaryServer — Port 20000 best-guess inference server.
 *
 * Accepts standard information on port 20000 (Java edition) and returns
 * best-guess responses. An OS-level listener may also exist on the same port
 * (public OS port 20000); the two sometimes talk, sometimes they don't.
 *
 * Protocol:
 *   ASK|<text>         — Submit information, receive best-guess response.
 *   RELAY|<text>       — Forward to OS port 20000 listener (if alive).
 *   STATUS             — Return alive status.
 *
 * Uses DJL (Deep Java Library) for local inference when available,
 * falls back to pattern heuristics otherwise.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package strernary;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.concurrent.ConcurrentHashMap;

public class StrernaryServer implements Runnable
{
    public static final int PORT = 20000;
    public static final String THREAD_NAME = "STRERNARY_SERVER";

    private final String host;
    private volatile boolean running = true;
    private volatile boolean osPortAlive = false;
    private final ConcurrentHashMap<String, String> knowledgeBase = new ConcurrentHashMap<>();
    private final StrernaryKnowledgeFetcher fetcher;
    private final StrernaryTranslationLayer translator;
    private final StrernaryLaborLawFetcher laborLaw;

    public StrernaryServer(String host)
    {
        this.host = host;
        this.fetcher = new StrernaryKnowledgeFetcher();
        this.translator = new StrernaryTranslationLayer();
        this.laborLaw = new StrernaryLaborLawFetcher(fetcher);
        probeOsPort();
        Thread.ofVirtual().name(THREAD_NAME).start(this);
        // Schedule AI training: load TSV data immediately, labor law fetch after 1 min
        Thread.ofVirtual().name("STRERNARY_TRAIN").start(() -> {
            try {
                new StrernaryTrainingLoader(fetcher).loadAll();
                Thread.sleep(60_000);
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". Strernary\u2122 AI training scheduled \u2014 labor laws fetching .");
                laborLaw.fetchAll();
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". Strernary\u2122 AI training complete \u2014 model stored .");
            } catch (Exception e) { ExceptionHandler.dispatch(e); }
        });
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary\u2122 now starting on port " + PORT + " .");
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary\u2122 registered as @20000 .");
    }

    @Override
    public void run()
    {
        try (ServerSocket ss = new ServerSocket(PORT, 50, InetAddress.getByName(host)))
        {
            while (running)
            {
                Socket client = ss.accept();
                Thread.ofVirtual().start(() -> handleClient(client));
            }
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
    }

    private void handleClient(Socket client)
    {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             OutputStream out = client.getOutputStream())
        {
            out.write(("\n").getBytes(StandardCharsets.UTF_8));
            out.write(("\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Strernary\u2122 Java Port 20000 \u2014 Deep Inference Edition\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Model: DJL 0.31.0 / PyTorch / DistilBERT Sentiment\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Knowledge: nwe_strernary (Wikipedia + DuckDuckGo + MySQL)\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  MEARVK LLC — Max Rupplin\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Discussions: github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions\n").getBytes(StandardCharsets.UTF_8));
            out.write(("\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Q: Why do people with high IQs make terrible friends?\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  A: They finish your sentences \u2014 and your arguments.\n").getBytes(StandardCharsets.UTF_8));
            out.write(("\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\n").getBytes(StandardCharsets.UTF_8));
            out.write(("\n").getBytes(StandardCharsets.UTF_8));

            // NationalID prompt
            out.write(("  Enter NationalID (or press Enter to continue without):\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  > ").getBytes(StandardCharsets.UTF_8));
            out.flush();

            String idLine = in.readLine();
            long nationalId = -1;
            if (idLine != null && !idLine.trim().isEmpty())
            {
                try
                {
                    nationalId = Long.parseLong(idLine.trim());
                    var profile = database.N21Store.loadNationalFinanceID(nationalId);
                    if (profile != null)
                        out.write(("  Welcome, NationalID " + nationalId + ".\n").getBytes(StandardCharsets.UTF_8));
                    else
                    {
                        out.write(("  NationalID not found. Connect to port 49152 to register.\n").getBytes(StandardCharsets.UTF_8));
                        nationalId = -1;
                    }
                }
                catch (NumberFormatException e)
                {
                    out.write(("  Invalid ID. Continuing without NationalID.\n").getBytes(StandardCharsets.UTF_8));
                }
            }
            else
            {
                out.write(("  Continuing without NationalID. Register at port 49152.\n").getBytes(StandardCharsets.UTF_8));
            }

            out.write(("\n  Commands: ASK|<text>  RELAY|<text>  STATUS  quit\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Or just type naturally \u2014 I'll do my best.\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  strernary-deep> ").getBytes(StandardCharsets.UTF_8));
            out.flush();

            final long sessionNid = nationalId;
            String request;
            while ((request = in.readLine()) != null)
            {
                request = request.trim();
                if (request.equalsIgnoreCase("quit") || request.equalsIgnoreCase("exit")) break;
                if (request.isEmpty()) { out.write(("  strernary-deep> ").getBytes(StandardCharsets.UTF_8)); out.flush(); continue; }

                String response;
                if (request.startsWith("ASK|"))
                    response = "RESPONSE|" + bestGuess(request.substring(4).trim());
                else if (request.startsWith("RELAY|"))
                    response = "OS_RESPONSE|" + relayToOsPort(request.substring(6).trim());
                else if ("STATUS".equalsIgnoreCase(request))
                    response = "ALIVE|strernary|port=" + PORT + "|os_port_alive=" + osPortAlive + "|model=DJL-0.31.0-DistilBERT";
                else
                    response = bestGuess(request);

                // Store session interaction and populate D44
                final String q = request, a = response;
                Thread.ofVirtual().start(() -> recordInteraction(sessionNid, q, a));

                out.write(("  " + response + "\n").getBytes(StandardCharsets.UTF_8));
                out.write(("  strernary-deep> ").getBytes(StandardCharsets.UTF_8));
                out.flush();
            }

            out.write(("  Goodbye. Think deeply.\n").getBytes(StandardCharsets.UTF_8));
            out.flush();
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
    }

    /**
     * Records interaction to nwe_strernary.user_sessions and nwe_calendar_d44.d44_interactions.
     */
    private void recordInteraction(long nationalId, String question, String answer)
    {
        try (Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/nwe_strernary", "mearvk", "$$Ironman1"))
        {
            try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO user_sessions (national_id, port, question, answer) VALUES (?, ?, ?, ?)"))
            {
                ps.setObject(1, nationalId > 0 ? nationalId : null);
                ps.setInt(2, PORT);
                ps.setString(3, question);
                ps.setString(4, answer);
                ps.executeUpdate();
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }

        // Populate D44 database
        try (Connection conn = java.sql.DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/nwe_calendar_d44", "mearvk", "$$Ironman1"))
        {
            try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO d44_interactions (national_id, source_port, question, answer) VALUES (?, ?, ?, ?)"))
            {
                ps.setObject(1, nationalId > 0 ? nationalId : null);
                ps.setInt(2, PORT);
                ps.setString(3, question);
                ps.setString(4, answer);
                ps.executeUpdate();
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private String bestGuess(String input)
    {
        String cached = knowledgeBase.get(normalize(input));
        if (cached != null) return cached;

        // Check MySQL knowledge base first (factual answers)
        String dbAnswer = fetcher.lookup(input);
        if (dbAnswer != null) { knowledgeBase.put(normalize(input), "KB|" + dbAnswer); return "KB|" + dbAnswer; }

        // Check labor law database for labor/employment questions
        if (isLaborQuestion(input))
        {
            String lawAnswer = laborLaw.queryLaborLaw(input);
            if (lawAnswer != null) { knowledgeBase.put(normalize(input), "LAW|" + lawAnswer); return "LAW|" + lawAnswer; }
        }

        // Try DJL deep inference (reasoning/sentiment)
        String djlResponse = attemptDjlInference(input);
        if (djlResponse != null) { knowledgeBase.put(normalize(input), djlResponse); return djlResponse; }

        // Query national signal servers (Japan, Russia, Mexico, Greece) with translation
        String nationalResponse = translator.queryNationals(input);
        if (nationalResponse != null) { knowledgeBase.put(normalize(input), "NATL|" + nationalResponse); return "NATL|" + nationalResponse; }

        // Fetch from Wikipedia/search for factual questions
        String fetched = fetcher.fetchAndStore(input);
        if (fetched != null) { knowledgeBase.put(normalize(input), "WIKI|" + fetched); return "WIKI|" + fetched; }

        // Try OS port relay
        if (osPortAlive)
        {
            String osResponse = relayToOsPort(input);
            if (osResponse != null && !osResponse.startsWith("ERROR"))
            { knowledgeBase.put(normalize(input), osResponse); return osResponse; }
        }

        String heuristic = heuristicResponse(input);
        knowledgeBase.put(normalize(input), heuristic);
        return heuristic;
    }

    private String attemptDjlInference(String input)
    {
        try { return DjlInferenceEngine.infer(input); }
        catch (NoClassDefFoundError | Exception e) { return null; }
    }

    private String relayToOsPort(String text)
    {
        try (Socket os = new Socket())
        {
            os.connect(new InetSocketAddress("127.0.0.1", PORT), 2000);
            os.setSoTimeout(3000);
            OutputStream out = os.getOutputStream();
            out.write((text + "\n").getBytes(StandardCharsets.UTF_8));
            out.flush();
            BufferedReader in = new BufferedReader(new InputStreamReader(os.getInputStream()));
            String response = in.readLine();
            osPortAlive = true;
            return response != null ? response : "NO_RESPONSE";
        }
        catch (Exception e) { osPortAlive = false; return "ERROR|OS_PORT_UNREACHABLE"; }
    }

    private void probeOsPort()
    {
        try (Socket probe = new Socket())
        {
            probe.connect(new InetSocketAddress("127.0.0.1", PORT), 1000);
            osPortAlive = true;
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Strernary\u2122 OS port 20000 detected alive .");
        }
        catch (Exception e)
        {
            osPortAlive = false;
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Strernary\u2122 OS port 20000 not detected .");
        }
    }

    private String heuristicResponse(String input)
    {
        String lower = input.toLowerCase();
        if (lower.contains("weather") || lower.contains("temperature"))
            return "GUESS|weather_related|try port 49133 WeatherServer";
        if (lower.contains("bitcoin") || lower.contains("btc") || lower.contains("crypto"))
            return "GUESS|crypto_related|try port 6682 BitcoinCompliant";
        if (lower.contains("encrypt") || lower.contains("aes") || lower.contains("rsa"))
            return "GUESS|encryption_related|try port 5512 AesCompliant";
        if (lower.contains("japan") || lower.contains("nikkei"))
            return "GUESS|japan_signal|try port 49201 JapanSignalServer";
        if (lower.contains("russia") || lower.contains("moex"))
            return "GUESS|russia_signal|try port 49202 RussiaSignalServer";
        if (lower.contains("mexico") || lower.contains("bmv") || lower.contains("pemex"))
            return "GUESS|mexico_signal|try port 49203 MexicoSignalServer";
        if (lower.contains("greece") || lower.contains("athens") || lower.contains("baltic"))
            return "GUESS|greece_signal|try port 49204 GreeceInternationalSignalServer";
        if (lower.contains("democratic") || lower.contains("futures") || lower.contains("tax defense") || lower.contains("d500"))
            return "GUESS|democratic_futures|try port 5000 DemocraticProFrontNational (Futures™)";
        if (lower.contains("labor") || lower.contains("appree") || lower.contains("grass") || lower.contains("herb") || lower.contains("ethical") || lower.contains("moral"))
            return "GUESS|green_durham|try port 20000 Green.Durham.Grass.and.Herb™ (NC Socialist-College)";
        if (lower.contains("species") || lower.contains("postal") || lower.contains("ssa") || lower.contains("brarner"))
            return "GUESS|brarner_alete|try port 49152 Brarner.M.Alete™ (NC Socialist-College)";
        if (lower.contains("status") || lower.contains("alive") || lower.contains("health"))
            return "GUESS|status_query|try STATUS command on any server";
        return "GUESS|unknown|insufficient context for definitive response";
    }

    private String normalize(String input) { return input.toLowerCase().trim().replaceAll("\\s+", " "); }

    private boolean isLaborQuestion(String input)
    {
        String l = input.toLowerCase();
        return l.contains("labor") || l.contains("labour") || l.contains("employ") || l.contains("wage")
            || l.contains("overtime") || l.contains("osha") || l.contains("fmla") || l.contains("flsa")
            || l.contains("worker") || l.contains("union") || l.contains("discrimination")
            || l.contains("termination") || l.contains("at-will") || l.contains("minimum wage")
            || l.contains("working hours") || l.contains("leave") || l.contains("safety");
    }

    public void stop() { running = false; }

    private void reportSecurityConcern(Socket client, String request)
    {
        String ip = client.getInetAddress().getHostAddress();
        String msg = "Unrecognized request from " + ip + ":" + client.getPort() + " \u2014 \"" + request + "\"";
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary\u2122 SECURITY: " + msg + " .", commons.color.ColorPalette.COLOR_STANDARD_RED);
        ExceptionHandler.dispatch(new SecurityException("[Strernary] " + msg));
    }
}
