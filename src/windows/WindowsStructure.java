package windows;

import java.time.Instant;
import java.util.Map;

/** Common envelope tying execution, program, directive, citizen, call, and choice together. */
public record WindowsStructure(
        WindowsExecution execution,
        WindowsProgram program,
        WindowsDirective directive,
        WindowsCitizen citizen,
        WindowsCall call,
        WindowsChoice choice,
        Instant createdAt,
        Map<String, String> metadata) {
    public WindowsStructure {
        if (execution == null || program == null || directive == null || citizen == null
                || call == null || choice == null || createdAt == null) {
            throw new IllegalArgumentException("all Windows structure components are required");
        }
        metadata = Map.copyOf(metadata);
    }
}
