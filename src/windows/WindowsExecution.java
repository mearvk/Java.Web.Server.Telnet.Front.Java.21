package windows;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/** A controlled Windows process execution request and result. */
public final class WindowsExecution {
    private final WindowsProgram program;
    private final WindowsDirective directive;
    private final WindowsCitizen citizen;
    private final List<String> arguments;
    private final Map<String, String> environment;

    public WindowsExecution(
            WindowsProgram program,
            WindowsDirective directive,
            WindowsCitizen citizen,
            List<String> arguments,
            Map<String, String> environment) {
        this.program = program;
        this.directive = directive;
        this.citizen = citizen;
        this.arguments = List.copyOf(arguments);
        this.environment = Map.copyOf(environment);
    }

    public WindowsProgram program() { return program; }
    public WindowsDirective directive() { return directive; }
    public WindowsCitizen citizen() { return citizen; }
    public List<String> arguments() { return arguments; }
    public Map<String, String> environment() { return environment; }

    public WindowsExecutionResult execute() throws Exception {
        if (!directive.allowsExecution()) {
            throw new SecurityException("Windows directive does not permit execution: " + directive.name());
        }

        ProcessBuilder builder = new ProcessBuilder(program.command(arguments));
        builder.environment().putAll(environment);
        builder.redirectErrorStream(true);

        Instant started = Instant.now();
        Process process = builder.start();
        String output = new String(process.getInputStream().readAllBytes());
        int exitCode = process.waitFor();
        Instant finished = Instant.now();

        return new WindowsExecutionResult(exitCode, output, started, finished);
    }

    public record WindowsExecutionResult(
            int exitCode,
            String output,
            Instant started,
            Instant finished) {
        public boolean successful() { return exitCode == 0; }
    }
}
