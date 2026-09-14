package windows;

import java.util.List;

/** Evaluates an ordered set of safe execution alternatives. */
public record WindowsChoice(List<WindowsProgram> alternatives) {
    public WindowsChoice {
        alternatives = List.copyOf(alternatives);
        if (alternatives.isEmpty()) throw new IllegalArgumentException("at least one alternative is required");
    }

    public WindowsProgram firstAvailable() {
        return alternatives.stream()
                .filter(program -> program.executable().toFile().isFile())
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("no executable alternative is available"));
    }
}
