import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.io.BufferedReader;
import java.io.InputStreamReader;

/** Linux-friendly Java 21 Black Belt Ethical Auditor CLI. */
public final class BlackBeltCLI {
    private static void usage() {
        System.out.println("Usage: java BlackBeltCLI [--file FILE] [--version] [--help]");
        System.out.println("       cat audit.json | java BlackBeltCLI");
        System.out.println("Environment: BBEA_ENGINE_URL, BBEA_MODEL, BBEA_SYSTEM_PROMPT");
    }

    private static String quoteJson(String s) {
        StringBuilder b = new StringBuilder(s.length() + 16).append('"');
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"' -> b.append("\\\"");
                case '\\' -> b.append("\\\\");
                case '\n' -> b.append("\\n");
                case '\r' -> b.append("\\r");
                case '\t' -> b.append("\\t");
                default -> {
                    if (c < 0x20) b.append(String.format("\\u%04x", (int)c));
                    else b.append(c);
                }
            }
        }
        return b.append('"').toString();
    }

    private static Path resolvePrompt() {
        String configured = System.getenv("BBEA_SYSTEM_PROMPT");
        if (configured != null && !configured.isBlank()) return Path.of(configured);
        Path repo = Path.of("../../../black.belt/sharp/system.prompt");
        if (Files.isRegularFile(repo)) return repo;
        return Path.of("/usr/share/blackbelt/sharp/system.prompt");
    }

    private static int runEngine(String input) throws Exception {
        String prompt = Files.readString(resolvePrompt(), StandardCharsets.UTF_8);
        String model = System.getenv().getOrDefault("BBEA_MODEL", "llama3.2:latest");
        String url = System.getenv().getOrDefault("BBEA_ENGINE_URL", "http://127.0.0.1:11434/api/generate");
        String requestJson = "{" +
                "\"model\":" + quoteJson(model) + "," +
                "\"system\":" + quoteJson(prompt) + "," +
                "\"prompt\":" + quoteJson(input.trim()) + "," +
                "\"stream\":false," +
                "\"format\":\"json\"}";

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestJson, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            System.err.println("AI engine HTTP " + response.statusCode());
            System.err.println(response.body());
            return 3;
        }
        System.out.println(response.body());
        return 0;
    }

    private static int interactive() throws Exception {
        System.out.println("Black Belt Ethical Auditor");
        System.out.println("Enter a JSON audit object, or type 'help' or 'quit'.");
        BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
        for (;;) {
            System.out.print("black-belt> ");
            System.out.flush();
            String line = reader.readLine();
            if (line == null) break;
            if (line.isBlank()) continue;
            if (line.equals("quit") || line.equals("exit")) break;
            if (line.equals("help")) {
                System.out.println("Paste a complete BBEA JSON audit object at the prompt.");
                System.out.println("Commands: help, quit, exit");
                continue;
            }
            int rc = runEngine(line);
            if (rc != 0) System.err.println("Audit failed (exit " + rc + ").");
        }
        System.out.println();
        return 0;
    }

    public static void main(String[] args) throws Exception {
        String file = null;
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--help", "-h" -> { usage(); return; }
                case "--version" -> { System.out.println("blackbelt-java 1.2 (BBEA CLI v2 transport)"); return; }
                case "--file" -> {
                    if (++i >= args.length) { usage(); System.exit(2); }
                    file = args[i];
                }
                default -> { System.err.println("Unknown argument: " + args[i]); usage(); System.exit(2); }
            }
        }

        if (file == null && System.console() != null) {
            System.exit(interactive());
        }

        String input = file == null
                ? new String(System.in.readAllBytes(), StandardCharsets.UTF_8)
                : Files.readString(Path.of(file), StandardCharsets.UTF_8);
        if (input.trim().isEmpty()) { System.err.println("No JSON audit input received."); System.exit(2); }
        if (!input.trim().startsWith("{") || !input.trim().endsWith("}")) {
            System.err.println("Audit input must be a JSON object."); System.exit(2); }
        System.exit(runEngine(input));
    }
}
