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
import java.util.concurrent.ConcurrentHashMap;

public class StrernaryServer implements Runnable
{
    public static final int PORT = 20000;
    public static final String THREAD_NAME = "STRERNARY_SERVER";

    private final String host;
    private volatile boolean running = true;

    /** Tracks whether the OS port 20000 listener is reachable */
    private volatile boolean osPortAlive = false;

    /** Simple frequency map for best-guess pattern matching */
    private final ConcurrentHashMap<String, String> knowledgeBase = new ConcurrentHashMap<>();

    /**
     * Constructs the Strernary server.
     *
     * @param host bind address
     * @javaowner Max Rupplin
     */
    public StrernaryServer(String host)
    {
        this.host = host;
        probeOsPort();
        Thread.ofVirtual().name(THREAD_NAME).start(this);
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary™ now starting on port " + PORT + " .");
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

    /**
     * Handles incoming client requests.
     *
     * @javaowner Max Rupplin
     */
    private void handleClient(Socket client)
    {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             OutputStream out = client.getOutputStream())
        {
            // Welcome banner + IQ joke
            out.write(("\n").getBytes(StandardCharsets.UTF_8));
            out.write(("═══════════════════════════════════════════════════════════\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Strernary™ Java Port 20000 — Deep Inference Edition\n").getBytes(StandardCharsets.UTF_8));
            out.write(("═══════════════════════════════════════════════════════════\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Q: Why do people with high IQs make terrible friends?\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  A: They finish your sentences — and your arguments.\n").getBytes(StandardCharsets.UTF_8));
            out.write(("═══════════════════════════════════════════════════════════\n").getBytes(StandardCharsets.UTF_8));
            out.write(("\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Commands: ASK|<text>  RELAY|<text>  STATUS  quit\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Or just type naturally — I'll do my best.\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  strernary-deep> ").getBytes(StandardCharsets.UTF_8));
            out.flush();

            String request;
            while ((request = in.readLine()) != null)
            {
                request = request.trim();
                if (request.equalsIgnoreCase("quit") || request.equalsIgnoreCase("exit")) break;
                if (request.isEmpty()) { out.write(("  strernary-deep> ").getBytes(StandardCharsets.UTF_8)); out.flush(); continue; }

                String response;
                if (request.startsWith("ASK|"))
                {
                    String text = request.substring(4).trim();
                    response = "RESPONSE|" + bestGuess(text);
                }
                else if (request.startsWith("RELAY|"))
                {
                    String text = request.substring(6).trim();
                    response = "OS_RESPONSE|" + relayToOsPort(text);
                }
                else if ("STATUS".equalsIgnoreCase(request))
                {
                    response = "ALIVE|strernary|port=" + PORT + "|os_port_alive=" + osPortAlive;
                }
                else
                {
                    // Treat plain text as an ASK
                    response = bestGuess(request);
                }

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
     * Best-guess response engine. Checks local knowledge base first,
     * then attempts DJL inference if available, then falls back to
     * keyword heuristics.
     *
     * @param input the standard information text
     * @return best-guess response
     * @javaowner Max Rupplin
     */
    private String bestGuess(String input)
    {
        // Check knowledge base for cached response
        String cached = knowledgeBase.get(normalize(input));
        if (cached != null) return cached;

        // Attempt DJL inference via reflection (avoids hard dependency)
        String djlResponse = attemptDjlInference(input);
        if (djlResponse != null)
        {
            knowledgeBase.put(normalize(input), djlResponse);
            return djlResponse;
        }

        // Attempt relay to OS port (they sometimes talk)
        if (osPortAlive)
        {
            String osResponse = relayToOsPort(input);
            if (osResponse != null && !osResponse.startsWith("ERROR"))
            {
                knowledgeBase.put(normalize(input), osResponse);
                return osResponse;
            }
        }

        // Fallback: keyword heuristic
        String heuristic = heuristicResponse(input);
        knowledgeBase.put(normalize(input), heuristic);
        return heuristic;
    }

    /**
     * Deep inference using DJL (Deep Java Library) with PyTorch engine.
     * Performs text classification / sentiment analysis for best-guess routing.
     * Falls back to null if DJL is unavailable or model fails.
     *
     * Jars required (jars/djl/):
     *   api-0.31.0.jar, basicdataset-0.31.0.jar, model-zoo-0.31.0.jar,
     *   pytorch-engine-0.31.0.jar, pytorch-model-zoo-0.31.0.jar, tokenizers-0.31.0.jar
     *
     * @javaowner Max Rupplin
     */
    private String attemptDjlInference(String input)
    {
        try
        {
            return DjlInferenceEngine.infer(input);
        }
        catch (NoClassDefFoundError | Exception e)
        {
            // DJL not on classpath or model unavailable — expected fallback
            return null;
        }
    }

    /**
     * Relays text to the OS-level port 20000 listener.
     * They sometimes talk; sometimes they don't.
     *
     * @javaowner Max Rupplin
     */
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
        catch (Exception e)
        {
            osPortAlive = false;
            return "ERROR|OS_PORT_UNREACHABLE";
        }
    }

    /**
     * Probes the OS port 20000 to check if it's alive at startup.
     *
     * @javaowner Max Rupplin
     */
    private void probeOsPort()
    {
        try (Socket probe = new Socket())
        {
            probe.connect(new InetSocketAddress("127.0.0.1", PORT), 1000);
            osPortAlive = true;
            probe.close();
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Strernary™ OS port 20000 detected alive .");
        }
        catch (Exception e)
        {
            osPortAlive = false;
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Strernary™ OS port 20000 not detected .");
        }
    }

    /**
     * Keyword-based heuristic best-guess fallback.
     *
     * @javaowner Max Rupplin
     */
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
        if (lower.contains("status") || lower.contains("alive") || lower.contains("health"))
            return "GUESS|status_query|try STATUS command on any server";

        return "GUESS|unknown|insufficient context for definitive response";
    }

    /** @javaowner Max Rupplin */
    private String normalize(String input)
    {
        return input.toLowerCase().trim().replaceAll("\\s+", " ");
    }

    /** @javaowner Max Rupplin */
    public void stop() { running = false; }

    /**
     * Reports unrecognized or suspicious requests as security concerns.
     *
     * @javaowner Max Rupplin
     */
    private void reportSecurityConcern(Socket client, String request)
    {
        String ip = client.getInetAddress().getHostAddress();
        String msg = "Unrecognized request from " + ip + ":" + client.getPort() + " — \"" + request + "\"";
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary™ SECURITY: " + msg + " .", commons.color.ColorPalette.COLOR_STANDARD_RED);
        ExceptionHandler.dispatch(new SecurityException("[Strernary] " + msg));
    }
}
