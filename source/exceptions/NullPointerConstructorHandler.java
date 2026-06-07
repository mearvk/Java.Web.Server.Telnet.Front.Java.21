package exceptions;

import java.time.Instant;

public class NullPointerConstructorHandler implements ExceptionListener
{
    private static final int PRIORITY = 10;

    @Override
    public int getPriority()
    {
        return PRIORITY;
    }

    @Override
    public void onException(final ExceptionRecord RECORD)
    {

        if (!isConstructorNPE(RECORD)) {
            return;
        }

        logConstructorFailure(RECORD);

        annotateForDiagnostics(RECORD);
    }

    private boolean isConstructorNPE(final ExceptionRecord RECORD)
    {
        Throwable ex = RECORD.exception();

        if (!(ex instanceof NullPointerException))
        {
            return false;
        }

        String origin = RECORD.origin();

        return origin != null && origin.contains("<init>");
    }

    private void logConstructorFailure(final ExceptionRecord RECORD)
    {
        System.err.println("[CONSTRUCTOR-NPE] " + Instant.now() + " | " + "Origin=" + RECORD.origin() + " | " + "Message=" + RECORD.exception().getMessage());
    }

    private void annotateForDiagnostics(final ExceptionRecord RECORD)
    {

    }
}
