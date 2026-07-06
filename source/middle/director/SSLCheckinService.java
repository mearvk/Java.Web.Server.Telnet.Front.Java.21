package middle.director;

import javax.net.ssl.*;
import java.io.*;
import java.net.URI;
import java.net.http.*;
import java.security.SecureRandom;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * SSLCheckinService — periodic SSL checkins toward middle servers.
 * Validates connectivity, certificate trust, and server liveness
 * for main, middle, occupy-writ, and endpoint server tiers.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 */
public class SSLCheckinService extends Thread
{
    private final List<String> mainServers;
    private final List<String> middleServers;
    private final List<String> occupyWritServers;
    private final List<String> endpointServers;
    private volatile boolean running = true;
    private long intervalMs = 60_000;

    public SSLCheckinService(List<String> mainServers, List<String> middleServers,
                             List<String> occupyWritServers, List<String> endpointServers)
    {
        this.mainServers = new CopyOnWriteArrayList<>(mainServers);
        this.middleServers = new CopyOnWriteArrayList<>(middleServers);
        this.occupyWritServers = new CopyOnWriteArrayList<>(occupyWritServers);
        this.endpointServers = new CopyOnWriteArrayList<>(endpointServers);
        setName("SSLCheckinService");
        setDaemon(true);
    }

    @Override
    public void run()
    {
        commons.CommonRails.printSystemComponent(this, this.hashCode(),
            ". SSLCheckinService™ starting — monitoring all server tiers .");

        while (running)
        {
            checkinAll("MAIN", mainServers);
            checkinAll("MIDDLE", middleServers);
            checkinAll("OCCUPY-WRIT", occupyWritServers);
            checkinAll("ENDPOINT", endpointServers);

            try { Thread.sleep(intervalMs); }
            catch (InterruptedException e) { Thread.currentThread().interrupt(); break; }
        }
    }

    private void checkinAll(String tier, List<String> servers)
    {
        for (String server : servers)
        {
            try
            {
                HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create("https://" + server + "/nwe/checkin"))
                    .timeout(java.time.Duration.ofSeconds(10))
                    .GET()
                    .build();

                HttpResponse<String> resp = HttpClient.newHttpClient()
                    .send(req, HttpResponse.BodyHandlers.ofString());

                if (resp.statusCode() != 200)
                    commons.CommonRails.printSystemComponent(this, this.hashCode(),
                        ". SSLCheckinService™ " + tier + " " + server + " responded " + resp.statusCode() + " .");
            }
            catch (Exception e)
            {
                exceptions.ExceptionHandler.dispatch(e);
            }
        }
    }

    public void shutdown() { running = false; interrupt(); }
}
