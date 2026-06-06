package exceptions;

import db.N21Store;

/**
 * Persists every dispatched exception (and security events) to the N21 MySQL database.
 * Registered as a listener in ExceptionHandler alongside SecurityExceptionHandler.
 */
public class N21ExceptionListener implements ExceptionListener
{
    private static final int PRIORITY = 10;

    @Override
    public int getPriority() { return PRIORITY; }

    @Override
    public void onException(ExceptionRecord record)
    {
        boolean isSecurity = record.exception() instanceof SecurityException
            || isSecurityKeyword(record.exception());

        N21Store.storeException(record, isSecurity);

        if (isSecurity)
            N21Store.storeSecurityEvent(record, null);
    }

    private boolean isSecurityKeyword(Throwable ex)
    {
        String name = ex.getClass().getSimpleName().toLowerCase();
        String msg  = ex.getMessage() != null ? ex.getMessage().toLowerCase() : "";
        return name.contains("auth") || name.contains("access") || msg.contains("unauthorized");
    }
}
