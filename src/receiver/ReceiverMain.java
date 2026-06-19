package receiver;

import javax.net.ssl.*;
import java.io.*;
import java.net.Socket;
import java.security.KeyStore;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * ReceiverMain — NitroWebExpress™ Receiver-Only Mode
 * Listens on port 443 with RSA/TLS. No password required.
 * Stores to MySQL or binary wallet per receiver.only.xml config.
 *
 * MEARVK LLC — Max Rupplin
 */
public class ReceiverMain {

    private final ReceiverConfig config;
    private final ReceiverStorage storage;
    private final ExecutorService pool = Executors.newCachedThreadPool();
    private volatile boolean running = true;

    public ReceiverMain(String configPath) throws Exception {
        this.config = new ReceiverConfig(configPath);
        this.storage = new ReceiverStorage(config);
    }

    public void start() throws Exception {
        SSLServerSocket serverSocket = createTlsSocket();
        System.out.println("-- : [ReceiverMain] . NitroWebExpress™ Receiver listening on port " + config.getPort() + " (TLS, no password) .");

        while (running) {
            Socket client = serverSocket.accept();
            pool.submit(() -> handle(client));
        }
    }

    private SSLServerSocket createTlsSocket() throws Exception {
        KeyStore ks = KeyStore.getInstance("JKS");
        try (FileInputStream fis = new FileInputStream(config.getKeystorePath())) {
            ks.load(fis, config.getKeystorePassword().toCharArray());
        }
        KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
        kmf.init(ks, config.getKeystorePassword().toCharArray());

        SSLContext ctx = SSLContext.getInstance(config.getTlsVersion());
        ctx.init(kmf.getKeyManagers(), null, null);

        SSLServerSocketFactory factory = ctx.getServerSocketFactory();
        SSLServerSocket ss = (SSLServerSocket) factory.createServerSocket(config.getPort());
        ss.setNeedClientAuth(config.isRequireClientAuth());
        return ss;
    }

    private void handle(Socket client) {
        try (InputStream in = client.getInputStream();
             OutputStream out = client.getOutputStream()) {

            // Read HTTP request line
            BufferedReader reader = new BufferedReader(new InputStreamReader(in));
            String requestLine = reader.readLine();
            if (requestLine == null) return;

            // Heartbeat / proof-of-life endpoint
            if (requestLine.contains("/receiver/heartbeat")) {
                String response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nALIVE";
                out.write(response.getBytes());
                out.flush();
                return;
            }

            // Receive data payload (POST body)
            StringBuilder body = new StringBuilder();
            String line;
            boolean headersDone = false;
            int contentLength = 0;
            while ((line = reader.readLine()) != null) {
                if (line.startsWith("Content-Length:")) {
                    contentLength = Integer.parseInt(line.substring(15).trim());
                }
                if (line.isEmpty()) { headersDone = true; break; }
            }
            if (headersDone && contentLength > 0) {
                char[] buf = new char[contentLength];
                int read = reader.read(buf, 0, contentLength);
                body.append(buf, 0, read);
            }

            // Store received data
            storage.store(client.getInetAddress().getHostAddress(), body.toString());

            String response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nACK";
            out.write(response.getBytes());
            out.flush();

        } catch (Exception e) {
            System.err.println("[ReceiverMain] Error: " + e.getMessage());
        }
    }

    public void stop() { running = false; pool.shutdownNow(); }

    public static void main(String[] args) throws Exception {
        String configPath = args.length > 0 ? args[0] : "configuration/receiver.only.xml";
        new ReceiverMain(configPath).start();
    }
}
