package modules.Defined.source.ai.module;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;

/**
 * NTSBCommunicator — Direct communication with NTSB web server.
 * Provides a second option on the Defined™ chat window that allows
 * direct communication with www.ntsb.gov via HTTP port 80.
 *
 * Includes the NTSB in the categories and provides interactive query capability.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class NTSBCommunicator
{
    private static final String NTSB_HOST = "www.ntsb.gov";
    private static final int NTSB_PORT = 80;
    private static final int CONNECT_TIMEOUT = 10000;
    private static final int READ_TIMEOUT = 15000;

    private static final String NTSB_BANNER =
        "\n" +
        "╔═══════════════════════════════════════════════════════════════════════════╗\n" +
        "║  NTSB Communication Interface                                            ║\n" +
        "║  National Transportation Safety Board — www.ntsb.gov                     ║\n" +
        "║  Direct HTTP communication via port 80                                   ║\n" +
        "╚═══════════════════════════════════════════════════════════════════════════╝\n";

    private static final String NTSB_MENU =
        "\n  NTSB Options:\n" +
        "  [1] Search accident reports\n" +
        "  [2] Recent aviation accidents\n" +
        "  [3] Safety recommendations\n" +
        "  [4] Marine investigations\n" +
        "  [5] Railroad investigations\n" +
        "  [6] Highway investigations\n" +
        "  [7] Pipeline investigations\n" +
        "  [8] Most wanted list (safety improvements)\n" +
        "  [9] Fetch NTSB page (enter URL path)\n" +
        "  [0] Return to Defined™ main menu\n";

    public NTSBCommunicator()
    {
        // Ready for NTSB communication
    }

    /**
     * Interactive NTSB communication session within the Defined™ telnet chat.
     * This is the second option for NTSB on the chat window that allows us
     * to directly communicate with the NTSB web server.
     */
    public void interact(BufferedReader in, PrintWriter out) throws IOException
    {
        out.print(NTSB_BANNER);
        out.print(NTSB_MENU);
        out.print("\nntsb> ");
        out.flush();

        String line;
        while ((line = in.readLine()) != null)
        {
            line = line.trim();

            if (line.equals("0") || line.equalsIgnoreCase("back") || line.equalsIgnoreCase("quit"))
            {
                out.println("Returning to Defined™ main menu.");
                return;
            }

            switch (line)
            {
                case "1":
                    out.println("Querying NTSB accident search...");
                    fetchAndDisplay("/investigations/AccidentReports/Pages/default.aspx", out);
                    break;
                case "2":
                    out.println("Fetching recent aviation accidents...");
                    fetchAndDisplay("/investigations/AccidentReports/Pages/aviation.aspx", out);
                    break;
                case "3":
                    out.println("Fetching safety recommendations...");
                    fetchAndDisplay("/safety/safety-recs/Pages/default.aspx", out);
                    break;
                case "4":
                    out.println("Fetching marine investigations...");
                    fetchAndDisplay("/investigations/AccidentReports/Pages/marine.aspx", out);
                    break;
                case "5":
                    out.println("Fetching railroad investigations...");
                    fetchAndDisplay("/investigations/AccidentReports/Pages/railroad.aspx", out);
                    break;
                case "6":
                    out.println("Fetching highway investigations...");
                    fetchAndDisplay("/investigations/AccidentReports/Pages/highway.aspx", out);
                    break;
                case "7":
                    out.println("Fetching pipeline investigations...");
                    fetchAndDisplay("/investigations/AccidentReports/Pages/pipeline.aspx", out);
                    break;
                case "8":
                    out.println("Fetching NTSB Most Wanted list...");
                    fetchAndDisplay("/safety/mwl/Pages/default.aspx", out);
                    break;
                case "9":
                    out.print("Enter NTSB URL path (e.g., /news): ");
                    out.flush();
                    String path = in.readLine();
                    if (path != null && !path.isEmpty())
                    {
                        out.println("Fetching: http://" + NTSB_HOST + path.trim());
                        fetchAndDisplay(path.trim(), out);
                    }
                    break;
                default:
                    out.println("Unknown option: " + line);
                    out.print(NTSB_MENU);
                    break;
            }

            out.print("\nntsb> ");
            out.flush();
        }
    }

    /**
     * Fetch a page from www.ntsb.gov via HTTP port 80 and display summary to user.
     */
    private void fetchAndDisplay(String path, PrintWriter out)
    {
        try
        {
            URL url = new URL("http", NTSB_HOST, NTSB_PORT, path);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setConnectTimeout(CONNECT_TIMEOUT);
            conn.setReadTimeout(READ_TIMEOUT);
            conn.setRequestMethod("GET");
            conn.setRequestProperty("User-Agent", "Defined-AI-NTSB/1.0 (NitroWebExpress; DarkGray)");
            conn.setRequestProperty("Accept", "text/html");
            conn.setInstanceFollowRedirects(true);

            int responseCode = conn.getResponseCode();
            out.println("  HTTP " + responseCode + " " + conn.getResponseMessage());

            if (responseCode == 200)
            {
                try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
                {
                    StringBuilder content = new StringBuilder();
                    String line;
                    int lineCount = 0;
                    while ((line = reader.readLine()) != null && lineCount < 100)
                    {
                        // Extract text content (strip HTML tags for display)
                        String text = line.replaceAll("<[^>]*>", " ").replaceAll("\\s+", " ").trim();
                        if (!text.isEmpty() && text.length() > 10)
                        {
                            content.append("  ").append(text).append("\n");
                            lineCount++;
                        }
                    }

                    if (content.length() > 0)
                    {
                        out.println("\n  ── NTSB Response ──────────────────────────────────────");
                        out.print(content.toString().substring(0, Math.min(content.length(), 3000)));
                        out.println("  ──────────────────────────────────────────────────────");
                    }
                    else
                    {
                        out.println("  (Page loaded but no readable text content extracted)");
                    }
                }
            }
            else if (responseCode == 301 || responseCode == 302)
            {
                String redirect = conn.getHeaderField("Location");
                out.println("  Redirected to: " + redirect);
                out.println("  (NTSB may require HTTPS — content may be limited via port 80)");
            }
            else
            {
                out.println("  Error fetching NTSB page. Response: " + responseCode);
            }

            conn.disconnect();
        }
        catch (Exception e)
        {
            out.println("  [ERROR] NTSB connection failed: " + e.getMessage());
            out.println("  (www.ntsb.gov may require HTTPS. Port 80 attempt logged.)");
        }
    }

    /**
     * Perform a background NTSB scan for the AI module.
     * Returns extracted text content from the given path.
     */
    public String backgroundFetch(String path)
    {
        try
        {
            URL url = new URL("http", NTSB_HOST, NTSB_PORT, path);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setConnectTimeout(CONNECT_TIMEOUT);
            conn.setReadTimeout(READ_TIMEOUT);
            conn.setRequestProperty("User-Agent", "Defined-AI-NTSB/1.0 (NitroWebExpress; DarkGray)");
            conn.setInstanceFollowRedirects(true);

            if (conn.getResponseCode() == 200)
            {
                try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
                {
                    StringBuilder content = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null)
                    {
                        String text = line.replaceAll("<[^>]*>", " ").replaceAll("\\s+", " ").trim();
                        if (!text.isEmpty()) content.append(text).append("\n");
                    }
                    return content.toString();
                }
            }
            conn.disconnect();
        }
        catch (Exception e)
        {
            return "[NTSB-ERROR] " + e.getMessage();
        }
        return "";
    }
}
