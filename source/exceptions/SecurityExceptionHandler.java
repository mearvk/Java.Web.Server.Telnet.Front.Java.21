package exceptions;

import java.time.Instant;

public class SecurityExceptionHandler implements ExceptionListener
{
    private static final int PRIORITY = 0;

    @Override
    public int getPriority()
    {
        return PRIORITY;
    }

    @Override
    public void onException(final ExceptionRecord RECORD)
    {

        if (!isSecurityEvent(RECORD)) {
            return;
        }

        logSecurityEvent(RECORD);

        triggerSecurityAlert(RECORD);
    }

    private boolean isSecurityEvent(final ExceptionRecord RECORD)
    {
        Throwable ex = RECORD.exception();

        if (ex instanceof SecurityException)
        {
            return true;
        }

        String simple = ex.getClass().getSimpleName().toLowerCase();

        if (simple.contains("auth") || simple.contains("access"))
        {
            return true;
        }

        String msg = ex.getMessage();

        return msg != null && msg.toLowerCase().contains("unauthorized");
    }

    private void logSecurityEvent(final ExceptionRecord RECORD)
    {
        System.err.println("[SECURITY] " + Instant.now() + " | " + "Type=" + RECORD.exception().getClass().getSimpleName() + " | " + "Message=" + RECORD.exception().getMessage() + " | " + "Origin=" + RECORD.origin());
    }

    private void triggerSecurityAlert(final ExceptionRecord RECORD)
    {

    }
}
