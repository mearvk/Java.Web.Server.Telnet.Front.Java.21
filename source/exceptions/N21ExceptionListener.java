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
    public void onException(final ExceptionRecord RECORD)
    {
        boolean isSecurity = RECORD.exception() instanceof SecurityException
            || isSecurityKeyword(RECORD.exception());

        N21Store.storeException(RECORD, isSecurity);

        if (isSecurity)
            N21Store.storeSecurityEvent(RECORD, null);
    }

    private boolean isSecurityKeyword(final Throwable EX)
    {
        String name = EX.getClass().getSimpleName().toLowerCase();
        String msg  = EX.getMessage() != null ? EX.getMessage().toLowerCase() : "";
        return name.contains("auth") || name.contains("access") || msg.contains("unauthorized");
    }
}
