package windows;

import java.time.Instant;

/** Immutable record of a requested Windows operation. */
public record WindowsCall(
        String id,
        WindowsCitizen citizen,
        WindowsProgram program,
        WindowsDirective directive,
        Instant requestedAt) {
    public WindowsCall {
        if (id == null || id.isBlank()) throw new IllegalArgumentException("id is required");
        if (requestedAt == null) throw new IllegalArgumentException("requestedAt is required");
    }
}
