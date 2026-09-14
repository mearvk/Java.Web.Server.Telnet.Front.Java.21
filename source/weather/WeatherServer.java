package weather;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;

/**
 * WeatherServer — port 49133
 *
 * Telnet-style server.  After connecting, the client types a city name
 * (or "lat,lon") and receives current weather from wttr.in (no API key needed).
 *
 * Commands:
 *   <city>          Fetch weather for the named city (e.g. "London")
 *   <lat,lon>       Fetch weather by coordinates (e.g. "35.6895,139.6917")
 *   lang <code>     Switch LanguagePack language
 *   help            Show command list
 *   quit            Disconnect
 */
public class WeatherServer extends Thread
{
    public static final int PORT = 49133;

    private final String HOST;
    private ServerSocket SERVER_SOCKET;

    public WeatherServer(final String HOST)
    {
        if (HOST == null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);
        this.HOST = HOST;
        this.setName("WeatherServer");
        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            SERVER_SOCKET = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". WeatherServer listening on port " + PORT + " .");
            while (!Thread.currentThread().isInterrupted())
            {
                Socket client = SERVER_SOCKET.accept();
                Thread h = new Thread(() -> handle(client));
                h.setDaemon(true);
                h.start();
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private void handle(final Socket CLIENT)
    {
        String ip = CLIENT.getInetAddress().getHostAddress();
        try (
            BufferedReader in  = new BufferedReader(new InputStreamReader(CLIENT.getInputStream(), StandardCharsets.UTF_8));
            BufferedWriter out = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream(), StandardCharsets.UTF_8))
        ) {
            writeLine(out, "[ NWE port " + PORT + " — Weather Service ]");
            writeLine(out, "Enter a city name or lat,lon coordinates. Type 'help' for commands.");

            String line;
            while ((line = in.readLine()) != null)
            {
                line = line.trim();
                if (line.isEmpty()) continue;

                if (line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")) break;

                if (line.equalsIgnoreCase("help"))
                {
                    writeLine(out, "Commands: <city> | <lat,lon> | lang <code> | quit");
                    continue;
                }

                String[] parts = line.split("\\s+", 2);
                if (parts[0].equalsIgnoreCase("lang"))
                {
                    if (parts.length < 2) { writeLine(out, "Usage: lang <code>"); continue; }
                    writeLine(out, languages.LanguagePack.handleLangCommand(ip, parts[1]));
                    continue;
                }

                writeLine(out, fetch(line));
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        finally { try { CLIENT.close(); } catch (Exception ignored) {} }
    }

    /** Fetch plain-text weather from wttr.in for a city or "lat,lon". */
    private static String fetch(final String QUERY)
    {
        try
        {
            // wttr.in accepts city names and lat,lon; ?format=3 gives "City: ☀️ +20°C"
            String encoded = URLEncoder.encode(QUERY.trim(), StandardCharsets.UTF_8);
            HttpURLConnection conn = (HttpURLConnection)
                new URI("https://wttr.in/" + encoded + "?format=3").toURL().openConnection();
            conn.setConnectTimeout(8_000);
            conn.setReadTimeout(8_000);
            conn.setRequestProperty("User-Agent", "NWE-WeatherServer/1.0");
            try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
            {
                StringBuilder sb = new StringBuilder();
                String l;
                while ((l = br.readLine()) != null) sb.append(l).append("\r\n");
                return sb.toString().stripTrailing();
            }
        }
        catch (Exception e) { return "ERR could not fetch weather: " + e.getMessage(); }
    }

    private static void writeLine(final BufferedWriter OUT, final String LINE)
    {
        try { OUT.write(LINE + "\r\n"); OUT.flush(); } catch (Exception ignored) {}
    }
}
