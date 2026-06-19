/**
 * StrernaryOsPortModule — Quick public OS port 20000 listener.
 *
 * Lightweight module that handles fast responses on the public-facing
 * OS port. Accepts plain text, returns quick best-guess answers via
 * keyword routing. Talks to the deeper StrernaryServer (Java edition)
 * when it needs more sophisticated inference.
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

public class StrernaryOsPortModule implements Runnable
{
    public static final int PORT = 20000;
    public static final String THREAD_NAME = "STRERNARY_OS_PORT";

    private final String host;
    private volatile boolean running = true;

    public StrernaryOsPortModule(String host)
    {
        this.host = host;
        Thread.ofVirtual().name(THREAD_NAME).start(this);
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary™ OS public port 20000 listener now starting .");
    }

    @Override
    public void run()
    {
        try (ServerSocket ss = new ServerSocket(PORT, 100, InetAddress.getByName(host)))
        {
            while (running)
            {
                Socket client = ss.accept();
                Thread.ofVirtual().start(() -> handleQuick(client));
            }
        }
        catch (Exception e)
        {
            // Port likely in use by the Java edition — this is expected
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Strernary™ OS port 20000 yielded to Java edition .");
        }
    }

    /**
     * Quick response handler — fast keyword routing, no deep inference.
     */
    private void handleQuick(Socket client)
    {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             OutputStream out = client.getOutputStream())
        {
            // Welcome banner + IQ joke
            out.write(("\n").getBytes(StandardCharsets.UTF_8));
            out.write(("═══════════════════════════════════════════════════════\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Strernary™ OS Port 20000 — Metal Linux Edition\n").getBytes(StandardCharsets.UTF_8));
            out.write(("═══════════════════════════════════════════════════════\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Q: What's the difference between IQ 100 and IQ 150?\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  A: About 50 points and one existential crisis.\n").getBytes(StandardCharsets.UTF_8));
            out.write(("═══════════════════════════════════════════════════════\n").getBytes(StandardCharsets.UTF_8));
            out.write(("\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  Type anything for a quick guess, or 'quit' to exit.\n").getBytes(StandardCharsets.UTF_8));
            out.write(("  strernary> ").getBytes(StandardCharsets.UTF_8));
            out.flush();

            String line;
            while ((line = in.readLine()) != null)
            {
                line = line.trim();
                if (line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")) break;
                if (line.isEmpty()) { out.write(("  strernary> ").getBytes(StandardCharsets.UTF_8)); out.flush(); continue; }

                String response = quickRoute(line);
                out.write(("  " + response + "\n").getBytes(StandardCharsets.UTF_8));
                out.write(("  strernary> ").getBytes(StandardCharsets.UTF_8));
                out.flush();
            }

            out.write(("  Goodbye.\n").getBytes(StandardCharsets.UTF_8));
            out.flush();
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
    }

    /**
     * Fast keyword-based routing — instant responses.
     */
    private String quickRoute(String input)
    {
        String lower = input.toLowerCase();

        if (lower.contains("hello") || lower.contains("hi"))
            return "ACK|Strernary OS port active";
        if (lower.contains("time"))
            return "TIME|" + java.time.Instant.now();
        if (lower.contains("status") || lower.contains("alive"))
            return "ALIVE|strernary_os|port=20000";
        if (lower.contains("help"))
            return "HELP|Send plain text for quick routing. Use ASK| prefix for deep inference via Java port.";

        // Forward to Java edition for deeper analysis
        return forwardToJavaPort(input);
    }

    /**
     * Forwards to the Java edition Strernary port for deeper thinking.
     */
    private String forwardToJavaPort(String input)
    {
        try (Socket java = new Socket())
        {
            java.connect(new InetSocketAddress("127.0.0.1", PORT), 1000);
            java.setSoTimeout(5000);

            OutputStream out = java.getOutputStream();
            out.write(("ASK|" + input + "\n").getBytes(StandardCharsets.UTF_8));
            out.flush();

            BufferedReader in = new BufferedReader(new InputStreamReader(java.getInputStream()));
            String response = in.readLine();
            return response != null ? response : "DEFERRED|no_java_response";
        }
        catch (Exception e)
        {
            return "QUICK_GUESS|" + fallback(input);
        }
    }

    private String fallback(String input)
    {
        return "insufficient_context_for_quick_response";
    }

    public void stop() { running = false; }
}
