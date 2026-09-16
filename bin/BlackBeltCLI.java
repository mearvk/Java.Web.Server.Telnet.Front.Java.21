import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/** Linux-friendly Java 21 Black Belt Ethical Auditor CLI.
 * Uses the same Ollama-compatible engine contract as the C/C++ clients.
 */
public final class BlackBeltCLI {
    private static void usage() {
        System.out.println("Usage: java BlackBeltCLI [--file FILE] [--version] [--help]");
        System.out.println("       cat audit.json | java BlackBeltCLI");
        System.out.println("Environment: BBEA_ENGINE_URL, BBEA_MODEL, BBEA_SYSTEM_PROMPT");
    }

    private static String quoteJson(String s) {
        StringBuilder b = new StringBuilder(s.length() + 16);
        b.append('"');
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

    public static void main(String[] args) throws Exception {
        String file = null;
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--help", "-h" -> { usage(); return; }
                case "--version" -> { System.out.println("blackbelt-java 1.0 (BBEA CLI v2 transport)"); return; }
                case "--file" -> {
                    if (++i >= args.length) { usage(); System.exit(2); }
                    file = args[i];
                }
                default -> { System.err.println("Unknown argument: " + args[i]); usage(); System.exit(2); }
            }
        }

        String input = file == null
                ? new String(System.in.readAllBytes(), StandardCharsets.UTF_8)
                : Files.readString(Path.of(file), StandardCharsets.UTF_8);
        if (input.trim().isEmpty()) { System.err.println("No JSON audit input received."); System.exit(2); }

        // Validate that the front-end received a JSON object without adding a third-party JSON dependency.
        if (!input.trim().startsWith("{") || !input.trim().endsWith("}")) {
            System.err.println("Audit input must be a JSON object."); System.exit(2);
        }

        String promptFile = System.getenv().getOrDefault("BBEA_SYSTEM_PROMPT", "black.belt/sharp/system.prompt");
        String prompt = Files.readString(Path.of(promptFile), StandardCharsets.UTF_8);
        String model = System.getenv().getOrDefault("BBEA_MODEL", "llama3.1:8b");
        String url = System.getenv().getOrDefault("BBEA_ENGINE_URL", "http://127.0.0.1:11434/api/generate");

        String requestJson = "{" +
                "\"model\":" + quoteJson(model) + "," +
                "\"system\":" + quoteJson(prompt) + "," +
                "\"prompt\":" + quoteJson(input.trim()) + "," +
                "\"stream\":false," +
                "\"format\":\"json\"" +
                "}";

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestJson, StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            System.err.println("AI engine HTTP " + response.statusCode());
            System.err.println(response.body());
            System.exit(3);
        }
        System.out.println(response.body());
    }
}
