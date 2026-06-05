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
    public void onException(ExceptionRecord record)
    {

        if (!isConstructorNPE(record)) {
            return;
        }

        logConstructorFailure(record);

        annotateForDiagnostics(record);
    }

    private boolean isConstructorNPE(ExceptionRecord record)
    {
        Throwable ex = record.exception();

        if (!(ex instanceof NullPointerException))
        {
            return false;
        }

        String origin = record.origin();

        return origin != null && origin.contains("<init>");
    }

    private void logConstructorFailure(ExceptionRecord record)
    {
        System.err.println("[CONSTRUCTOR-NPE] " + Instant.now() + " | " + "Origin=" + record.origin() + " | " + "Message=" + record.exception().getMessage());
    }

    private void annotateForDiagnostics(ExceptionRecord record)
    {

    }
}
