/**
 * BrarnerAleteModule — HTTP communication module with the Brarner.M.Alete
 * GitHub repository (https://github.com/mearvk/Brarner.M.Alete/).
 *
 * Daily GET and POST to the repo. Pings the GitHub site approximately
 * 2 times a day when the server has been running for more than 1 hour.
 * Checks all links and logs communication as interesting and successful
 * in logging/event.social.log.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package brarner.m.alete;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.*;

public class BrarnerAleteModule implements Runnable
{
    public static final String THREAD_NAME = "BRARNER_ALETE_MODULE";
    private static final String GITHUB_BASE = "https://github.com/mearvk/Brarner.M.Alete/";
    private static final String GITHUB_RAW = "https://raw.githubusercontent.com/mearvk/Brarner.M.Alete/main/";
    private static final String GITHUB_API = "https://api.github.com/repos/mearvk/Brarner.M.Alete";
    private static final String EVENT_LOG = "logging/event.social.log";
    private static final long PING_INTERVAL_MS = 12 * 60 * 60 * 1000L; // ~2 times a day (12hr)
    private static final long STARTUP_GRACE_MS = 60 * 60 * 1000L; // 1 hour before first ping

    private volatile boolean running = true;
    private final Instant startTime;
    private final ScheduledExecutorService scheduler;

    /**
     * Constructs the Brarner Alete module.
     *
     * @javaowner Max Rupplin
     */
    public BrarnerAleteModule()
    {
        this.startTime = Instant.now();
        this.scheduler = Executors.newSingleThreadScheduledExecutor(
            r -> Thread.ofVirtual().name(THREAD_NAME).unstarted(r));

        ensureLogFile();
        Thread.ofVirtual().name(THREAD_NAME).start(this);
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". BrarnerAlete™ module now starting .");
    }

    @Override
    public void run()
    {
        // Schedule first ping after 1 hour, then every 12 hours (~2x/day)
        scheduler.scheduleAtFixedRate(this::dailyRoutine,
            STARTUP_GRACE_MS, PING_INTERVAL_MS, TimeUnit.MILLISECONDS);
    }

    /**
     * Daily routine: GET repo info, check links, POST acknowledgment, log results.
     *
     * @javaowner Max Rupplin
     */
    private void dailyRoutine()
    {
        if (!running) return;

        Duration uptime = Duration.between(startTime, Instant.now());
        if (uptime.toHours() < 1) return; // Must be running > 1hr

        try
        {
            // GET — fetch repo main page
            String repoPage = httpGet(GITHUB_BASE);
            logEvent("GET", GITHUB_BASE, "interesting", repoPage.length());

            // GET — fetch repo API metadata (contributors, links)
            String apiResponse = httpGet(GITHUB_API);
            logEvent("GET", GITHUB_API, "successful", apiResponse.length());

            // GET — check README for links
            String readme = httpGet(GITHUB_RAW + "README.md");
            logEvent("GET", GITHUB_RAW + "README.md", "interesting", readme.length());

            // Check links found in README
            checkLinks(readme);

            // POST — ping acknowledgment to repo (via API issues or discussions)
            String postResult = httpPost(GITHUB_API + "/dispatches",
                "{\"event_type\":\"brarner_alete_ping\",\"client_payload\":{\"uptime_hours\":" +
                uptime.toHours() + "}}");
            logEvent("POST", GITHUB_API + "/dispatches", "successful", postResult.length());

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". BrarnerAlete™ daily ping completed (uptime " + uptime.toHours() + "h) .");
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            logEvent("ERROR", GITHUB_BASE, "failed", 0);
        }
    }

    /**
     * Checks all links found in content and logs each as interesting.
     *
     * @javaowner Max Rupplin
     */
    private void checkLinks(String content)
    {
        // Extract URLs from content
        String[] tokens = content.split("[\\s\"'<>()\\[\\]]");
        for (String token : tokens)
        {
            if (token.startsWith("http://") || token.startsWith("https://"))
            {
                try
                {
                    String response = httpGet(token.trim());
                    logEvent("LINK_CHECK", token.trim(), "interesting", response.length());
                }
                catch (Exception e)
                {
                    logEvent("LINK_CHECK", token.trim(), "unreachable", 0);
                }
            }
        }
    }

    /**
     * Logs communication events to logging/event.social.log.
     *
     * @javaowner Max Rupplin
     */
    private void logEvent(String method, String url, String status, int contentLength)
    {
        String timestamp = LocalDateTime.now(ZoneId.of("America/New_York"))
            .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

        String entry = "[" + timestamp + "] [BrarnerAlete] " + method + " " +
            url + " — " + status + " (" + contentLength + " bytes)\n";

        try
        {
            Files.writeString(Path.of(EVENT_LOG), entry, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        }
        catch (IOException e)
        {
            ExceptionHandler.dispatch(e);
        }
    }

    /** @javaowner Max Rupplin */
    private String httpGet(String url) throws IOException
    {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(15000);
        conn.setRequestProperty("User-Agent", "NitroWebExpress-BrarnerAlete/1.0");
        conn.setRequestProperty("Accept", "application/json, text/html, */*");

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
            new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
        {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
        }
        return sb.toString();
    }

    /** @javaowner Max Rupplin */
    private String httpPost(String url, String body) throws IOException
    {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("POST");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(15000);
        conn.setDoOutput(true);
        conn.setRequestProperty("User-Agent", "NitroWebExpress-BrarnerAlete/1.0");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Accept", "application/json");

        try (OutputStream os = conn.getOutputStream())
        {
            os.write(body.getBytes(StandardCharsets.UTF_8));
        }

        int code = conn.getResponseCode();
        InputStream is = (code >= 200 && code < 400) ? conn.getInputStream() : conn.getErrorStream();
        if (is == null) return "HTTP " + code;

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8)))
        {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
        }
        return sb.toString();
    }

    /** @javaowner Max Rupplin */
    private void ensureLogFile()
    {
        try
        {
            Path logPath = Path.of(EVENT_LOG);
            if (!Files.exists(logPath.getParent())) Files.createDirectories(logPath.getParent());
            if (!Files.exists(logPath)) Files.createFile(logPath);
        }
        catch (IOException e) { ExceptionHandler.dispatch(e); }
    }

    /** @javaowner Max Rupplin */
    public void stop()
    {
        running = false;
        scheduler.shutdownNow();
    }
}
