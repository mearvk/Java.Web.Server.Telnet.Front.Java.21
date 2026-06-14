package ai;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.OutputStream;
import java.io.IOException;
import java.net.*;
import java.nio.charset.StandardCharsets;

/**
 * AIProctorModule — Copilot‑powered AI interface for NWE.
 *
 * Line protocol:
 *   identify <nationalId>
 *   ask <text>
 *   quit
 *
 * Runs on port 49111.
 *
 * @author
 * @date June 2026
 */
public class AIProctorModule extends Thread
{

    public static final int PORT = 49111;

    private final String HOST;
    private ServerSocket serverSocket;

    public AIProctorModule(final String host) {
        if (host == null) throw new SecurityException("//bodi/connect");
        this.HOST = host;
        this.setName("AIProctorModule");
        this.setDaemon(true);
    }

    @Override
    public void run() {
        try {
            serverSocket = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". AIProctorModule listening on port " + PORT + " .");

            while (!Thread.currentThread().isInterrupted()) {
                Socket client = serverSocket.accept();
                Thread h = new Thread(() -> handle(client));
                h.setDaemon(true);
                h.start();
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    // -------------------------------------------------------------------------
    // Session
    // -------------------------------------------------------------------------

    private static final class Session {
        long nationalId = -1;
        BufferedWriter out;
    }

    // -------------------------------------------------------------------------
    // Connection handler
    // -------------------------------------------------------------------------

    private void handle(final Socket client) {
        Session session = new Session();

        try (
                BufferedReader in  = new BufferedReader(new InputStreamReader(client.getInputStream(), StandardCharsets.UTF_8));
                BufferedWriter out = new BufferedWriter(new OutputStreamWriter(client.getOutputStream(), StandardCharsets.UTF_8))
        ) {
            session.out = out;

            write(out, "AIProctorModule (Copilot API) on port " + PORT);
            write(out, "identify <nationalId> to begin");

            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty()) continue;
                if (line.equalsIgnoreCase("quit")) break;

                String[] parts = line.split("\\s+", 2);
                String cmd = parts[0].toLowerCase();

                if (cmd.equals("identify") && session.nationalId < 0) {
                    if (parts.length < 2) { write(out, "Usage: identify <nationalId>"); continue; }
                    write(out, cmdIdentify(parts[1], session));
                    continue;
                }

                if (session.nationalId < 0) {
                    write(out, "Identify first: identify <nationalId>");
                    continue;
                }

                switch (cmd) {
                    case "ask" -> {
                        if (parts.length < 2) { write(out, "Usage: ask <text>"); continue; }
                        write(out, cmdAsk(parts[1], session));
                    }
                    default -> write(out, "Unknown command.\r\n" + HELP);
                }
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        finally {
            try { client.close(); } catch (Exception ignored) {}
        }
    }

    // -------------------------------------------------------------------------
    // Commands
    // -------------------------------------------------------------------------

    private String cmdIdentify(String idStr, Session session) {
        try {
            long id = Long.parseLong(idStr);
            var profile = database.N21Store.loadNationalFinanceID(id);
            if (profile == null) return "[identify] National ID not found.";

            session.nationalId = id;
            return "[identify] Welcome, National ID " + id + ".\r\n" + HELP;
        }
        catch (Exception e) { return "[identify] Invalid National ID."; }
    }

    private String cmdAsk(String text, Session session) {
        try {
            String reply = callCopilotAPI(text);
            return "[ask]\r\n" + reply;
        }
        catch (Exception e) {
            return "[ask] Error: " + e.getMessage();
        }
    }

    // -------------------------------------------------------------------------
    // Copilot API call
    // -------------------------------------------------------------------------

    private String callCopilotAPI(String prompt) throws IOException {
        // Replace with your actual Copilot endpoint + token
        URL url = new URL("https://api.copilot.microsoft.com/v1/chat/completions");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();

        conn.setRequestMethod("POST");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(10000);
        conn.setDoOutput(true);

        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Authorization", "Bearer YOUR_COPILOT_API_KEY");

        String body = """
        {
          "model": "gpt-4o",
          "messages": [
            {"role": "user", "content": "%s"}
          ]
        }
        """.formatted(prompt.replace("\"", "\\\""));

        try (OutputStream os = conn.getOutputStream()) {
            os.write(body.getBytes(StandardCharsets.UTF_8));
        }

        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {

            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) sb.append(line).append("\n");
            return sb.toString().trim();
        }
    }

    // -------------------------------------------------------------------------
    // IO helpers
    // -------------------------------------------------------------------------

    private static void write(BufferedWriter out, String line) {
        try { out.write(line + "\r\n"); out.flush(); } catch (Exception ignored) {}
    }

    // -------------------------------------------------------------------------
    // Help
    // -------------------------------------------------------------------------

    private static final String HELP =
            "Commands:\r\n" +
                    "  ask <text>\r\n" +
                    "  quit";
}
