package exceptions;

import java.time.Instant;
import java.util.Arrays;
import java.util.stream.Collectors;

public record ExceptionRecord(
        Throwable exception,
        String origin,
        String stackTrace,
        Instant timestamp
) {

    public static ExceptionRecord from(Throwable ex) {
        return new ExceptionRecord(
                ex,
                resolveOrigin(ex),
                resolveStackTrace(ex),
                Instant.now()
        );
    }

    private static String resolveOrigin(Throwable ex) {
        StackTraceElement[] trace = ex.getStackTrace();
        if (trace.length == 0) {
            return "unknown";
        }
        return trace[0].toString();
    }

    private static String resolveStackTrace(Throwable ex) {
        return Arrays.stream(ex.getStackTrace())
                .map(StackTraceElement::toString)
                .collect(Collectors.joining(System.lineSeparator()));
    }
}
