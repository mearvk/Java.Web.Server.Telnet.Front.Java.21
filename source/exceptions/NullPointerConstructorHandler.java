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
        Throwable ex = RECORD.EXCEPTION();

        if (!(ex instanceof NullPointerException))
        {
            return false;
        }

        String origin = RECORD.ORIGIN();

        return origin != null && origin.contains("<init>");
    }

    private void logConstructorFailure(final ExceptionRecord RECORD)
    {
        System.err.println("[CONSTRUCTOR-NPE] " + Instant.now() + " | " + "Origin=" + RECORD.ORIGIN() + " | " + "Message=" + RECORD.EXCEPTION().getMessage());
    }

    private void annotateForDiagnostics(final ExceptionRecord RECORD)
    {

    }
}
