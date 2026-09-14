package commons.process;

import commons.printing.ComponentPrinter;

import java.util.Collections;
import java.util.List;
import java.util.concurrent.*;

public final class ProcessRegistry {

    private static final List<Process> PROCESSES =
            Collections.synchronizedList(new java.util.ArrayList<>());

    private static final ExecutorService EXEC =
            Executors.newCachedThreadPool();

    private ProcessRegistry() {}

    public static void register(ProcessBuilder pb, Process p, Object owner) {
        if (p == null) return;

        PROCESSES.add(p);

        ProcessDescriptor desc = ProcessDescriptor.from(pb, p);

        ComponentPrinter.print(owner, p.hashCode(),
                ". Registered process: " + desc + " .");

        p.onExit().thenAccept(proc -> {
            ComponentPrinter.print(owner, proc.hashCode(),
                    ". Process exited: " + desc + " exit=" + proc.exitValue() + " .");
            PROCESSES.remove(proc);
        });

        EXEC.submit(() -> {
            try {
                if (!p.waitFor(2, TimeUnit.HOURS)) {
                    ComponentPrinter.print(owner, p.hashCode(),
                            ". Process timeout exceeded; destroying: " + desc + " .");
                    p.destroyForcibly();
                }
            } catch (Exception ignored) {}
        });
    }
}
