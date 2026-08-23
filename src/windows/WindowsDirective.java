package windows;

/** Explicit policy controlling whether and how a Windows operation may run. */
public record WindowsDirective(
        String name,
        boolean allowsExecution,
        boolean allowNetwork,
        boolean allowWrite,
        long timeoutMillis) {
    public WindowsDirective {
        if (name == null || name.isBlank()) throw new IllegalArgumentException("name is required");
        if (timeoutMillis < 0) throw new IllegalArgumentException("timeoutMillis must be non-negative");
    }

    public static WindowsDirective standard(String name) {
        return new WindowsDirective(name, true, false, false, 30_000);
    }
}
