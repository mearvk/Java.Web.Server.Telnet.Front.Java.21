package middle;

import commons.CommonRails;
import middle.director.*;

import java.io.*;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * MiddleDirectorServer — listens on port 8888, synchronizes finance and target goals
 * across middle nodes and forwards finalized content to national NWE installations (49152).
 *
 * Modules are loaded from configuration/middle-director-modules.xml.
 */
public class MiddleDirectorServer extends Thread
{
    public static final int PORT = 8888;

    private final String HOST;
    private ServerSocket serverSocket;

    /** Active director modules. */
    private final List<DirectorModule> modules = new CopyOnWriteArrayList<>();

    /** Known peer middle nodes (host:port). */
    private final List<String> middlePeers = new CopyOnWriteArrayList<>();

    /** Known national NWE endpoints (host:49152). */
    private final List<String> nationalEndpoints = new CopyOnWriteArrayList<>();

    public MiddleDirectorServer(final String HOST)
    {
        this.HOST = HOST;
        this.setName("MiddleDirectorServer-8888");
        this.setDaemon(true);
        loadModules();
    }

    private void loadModules()
    {
        modules.add(new ShortHopsModule());
        modules.add(new MediumHopsModule());
        modules.add(new ThoughtsAsGoalsModule());
        modules.add(new FinalMediumHopsModule());
        modules.add(new GamesAsGoalsModule());
        modules.add(new AuditorContentModule());
    }

    @Override
    public void run()
    {
        try
        {
            serverSocket = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". MiddleDirectorServer listening on " + HOST + ":" + PORT + " .");

            while (!Thread.currentThread().isInterrupted())
            {
                Socket client = serverSocket.accept();
                Thread.ofVirtual().start(() -> handle(client));
            }
        }
        catch (IOException e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private void handle(final Socket CLIENT)
    {
        try (
            BufferedReader in = new BufferedReader(new InputStreamReader(CLIENT.getInputStream()));
            BufferedWriter out = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream()))
        )
        {
            String line;
            while ((line = in.readLine()) != null)
            {
                line = line.trim();
                if (line.isEmpty()) continue;
                if (line.equalsIgnoreCase("quit")) break;

                String result = processGoal(line);
                out.write(result + "\r\n");
                out.flush();
            }
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
        finally { try { CLIENT.close(); } catch (Exception ignored) {} }
    }

    /**
     * Passes content through each module in sequence, then routes the result.
     */
    private String processGoal(final String INPUT)
    {
        String payload = INPUT;
        for (DirectorModule module : modules)
        {
            payload = module.process(payload);
        }
        return payload;
    }

    // ── Forwarding ───────────────────────────────────────────────────────────

    /** Send content to another middle node. */
    public void sendToMiddle(final String HOST, final int PORT, final String CONTENT)
    {
        forward(HOST, PORT, CONTENT);
    }

    /** Send content to a national NWE installation (port 49152). */
    public void sendToNational(final String HOST, final String CONTENT)
    {
        forward(HOST, 49152, CONTENT);
    }

    private void forward(final String HOST, final int PORT, final String CONTENT)
    {
        try (Socket s = new Socket(HOST, PORT);
             BufferedWriter w = new BufferedWriter(new OutputStreamWriter(s.getOutputStream())))
        {
            w.write(CONTENT + "\r\n");
            w.flush();
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". MiddleDirector forwarded to " + HOST + ":" + PORT + " .");
        }
        catch (IOException e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    public void addMiddlePeer(String hostPort) { middlePeers.add(hostPort); }
    public void addNationalEndpoint(String host) { nationalEndpoints.add(host); }
    public List<String> getMiddlePeers() { return middlePeers; }
    public List<String> getNationalEndpoints() { return nationalEndpoints; }
}
