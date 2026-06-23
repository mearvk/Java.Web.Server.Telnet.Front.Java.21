package exceptions;

import java.time.Instant;
import java.util.Arrays;
import java.util.stream.Collectors;

public record ExceptionRecord(
        Throwable EXCEPTION,
        String ORIGIN,
        String STACKTRACE,
        Instant TIMESTAMP
) {

    public static ExceptionRecord from(final Throwable EX) {
        return new ExceptionRecord(
                EX,
                resolveOrigin(EX),
                resolveStackTrace(EX),
                Instant.now()
        );
    }

    private static String resolveOrigin(final Throwable EX) {
        StackTraceElement[] trace = EX.getStackTrace();
        if (trace.length == 0) {
            return "unknown";
        }
        return trace[0].toString();
    }

    private static String resolveStackTrace(final Throwable EX) {
        return Arrays.stream(EX.getStackTrace())
                .map(StackTraceElement::toString)
                .collect(Collectors.joining(System.lineSeparator()));
    }
}
