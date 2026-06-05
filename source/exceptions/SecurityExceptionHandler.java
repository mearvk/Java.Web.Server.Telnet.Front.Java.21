package exceptions;

import exceptions.ExceptionListener;
import exceptions.ExceptionRecord;

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
    public void onException(ExceptionRecord record)
    {

        if (!isSecurityEvent(record)) {
            return;
        }

        logSecurityEvent(record);

        triggerSecurityAlert(record);
    }

    private boolean isSecurityEvent(ExceptionRecord record)
    {
        Throwable ex = record.exception();

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

    private void logSecurityEvent(ExceptionRecord record)
    {
        System.err.println("[SECURITY] " + Instant.now() + " | " + "Type=" + record.exception().getClass().getSimpleName() + " | " + "Message=" + record.exception().getMessage() + " | " + "Origin=" + record.origin());
    }

    private void triggerSecurityAlert(ExceptionRecord record)
    {

    }
}
