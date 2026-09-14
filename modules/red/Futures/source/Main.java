package red.Futures.source;
import red.Futures.source.ai.server.DemocraticAIServer;

/**
 * Main — Entry point for Democratic ProFront National 1.0.
 *
 * Initializes and starts the DemocraticAIServer on port 5000.
 * Registers a shutdown hook for graceful transfer of state.
 *
 * @author MEARVK LLC — Max Rupplin
 */
public class Main
{
    public static void main(String[] args) throws Exception
    {
        System.out.println("=== Democratic ProFront National 1.0 ===");
        System.out.println("=== D500 — Max Rupplin — A9000 Clear ===");
        System.out.println();

        DemocraticAIServer server = new DemocraticAIServer();
        server.initialize();
        server.start();

        Runtime.getRuntime().addShutdownHook(new Thread(server::shutdown));

        System.out.println("[Main] Server thread started. Awaiting democratic connections.");
    }
}
