package windows;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/** Describes a Windows executable or command without executing it. */
public record WindowsProgram(String name, Path executable) {
    public WindowsProgram {
        if (name == null || name.isBlank()) throw new IllegalArgumentException("name is required");
        if (executable == null) throw new IllegalArgumentException("executable is required");
    }

    public List<String> command(List<String> arguments) {
        List<String> command = new ArrayList<>();
        command.add(executable.toString());
        command.addAll(arguments);
        return List.copyOf(command);
    }
}
