package windows;

import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;

/**
 * Windows-facing adapter for translating a received call into a controlled
 * Windows execution request. Transport code remains separate from execution
 * policy so HTTP, Telnet, named pipes, or other frontends can share it.
 */
public final class WindowsFrontendAdapter {
    private final WindowsExecution execution;

    public WindowsFrontendAdapter(WindowsExecution execution) {
        this.execution = Objects.requireNonNull(execution, "execution");
    }

    public CompletionStage<WindowsExecution.Result> accept(WindowsCall call) {
        Objects.requireNonNull(call, "call");
        return CompletableFuture.supplyAsync(() -> execution.execute(call));
    }
}
