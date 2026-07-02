package red.Futures.source.pro.national;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;

/**
 * ResponseDispatcher — Async response formatting using thenApplyAsync().
 * CSV/XML responses formatted on a dedicated executor, never blocking the main pipeline.
 */
public class ResponseDispatcher
{
    private final ExecutorService formatExecutor;

    public ResponseDispatcher(ExecutorService formatExecutor) { this.formatExecutor = formatExecutor; }

    public CompletableFuture<String> dispatch(CompletableFuture<String> data, String format)
    {
        return data.thenApplyAsync(content ->
        {
            if ("XML".equalsIgnoreCase(format))
                return "<?xml version=\"1.0\"?><response><data><![CDATA[" + content + "]]></data></response>";
            else if ("CSV".equalsIgnoreCase(format))
                return "\"OK\",\"" + content.replace("\"", "\"\"") + "\"";
            else
                return "[OK] " + content;
        }, formatExecutor);
    }
}
