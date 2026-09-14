package windows;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

/** Minimal HTTP boundary for the Windows execution model. */
public final class WindowsHttpFrontend implements HttpHandler {
    private final WindowsFrontendAdapter adapter;

    public WindowsHttpFrontend(WindowsFrontendAdapter adapter) {
        this.adapter = Objects.requireNonNull(adapter, "adapter");
    }

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
            exchange.sendResponseHeaders(405, -1);
            return;
        }

        String body = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
        WindowsCall call = WindowsCall.parse(body);
        WindowsExecution.Result result = adapter.accept(call).toCompletableFuture().join();
        byte[] response = result.toJson().getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(result.exitCode(), response.length);
        try (var output = exchange.getResponseBody()) {
            output.write(response);
        }
    }
}
