package source;

import java.io.*;
import java.net.*;

/**
 * ChatProtocolHandler™ — Client-side protocol handler for NWE Chat
 * Connects to ChatServer on port 49230.
 *
 * Protocol: COMMAND|ARG1|ARG2|...
 *
 * Installer Tech ID: Max Rupplin
 * MEARVK LLC — NitroWebExpress™ 2026
 */
public class ChatProtocolHandler {

    private static final int PORT = 49230;
    private static final int TIMEOUT_MS = 10000;

    public static String sendCommand(String command) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", PORT), TIMEOUT_MS);
            socket.setSoTimeout(TIMEOUT_MS);
            PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            // Read banner lines
            String line;
            while ((line = in.readLine()) != null && line.startsWith("║") || (line != null && line.startsWith("╔")) || (line != null && line.startsWith("╚")) || (line != null && line.startsWith("Commands:"))) {
                if (line.startsWith("Commands:")) break;
            }
            out.println(command);
            String response = in.readLine();
            out.println("QUIT");
            return response != null ? response : "ERROR|No response";
        } catch (Exception e) {
            return "ERROR|Connection failed: " + e.getMessage();
        }
    }

    public static String register(String username, String password, String email) {
        return sendCommand("REGISTER|" + username + "|" + password + "|" + email);
    }

    public static String login(String username, String password) {
        return sendCommand("LOGIN|" + username + "|" + password);
    }

    public static String status() {
        return sendCommand("STATUS");
    }
}
