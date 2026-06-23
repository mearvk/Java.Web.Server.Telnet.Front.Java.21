/**
 * Custom Security exception that captures a related stack call and metadata.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */
package commons.security;

import java.time.Instant;

public class BodiSecurityException extends SecurityException
{
    private final Instant timestamp;

    private final StackTraceElement relatedStackCall;

    public BodiSecurityException(final String MESSAGE, final StackTraceElement RELATEDSTACKCALL)
    {
        super(MESSAGE);
        this.timestamp = Instant.now();
        this.relatedStackCall = RELATEDSTACKCALL;
        try
        {
            SecurityExceptionHandler.handle(this);
        }
        catch (Exception ignored)
        {
        }
    }

    public BodiSecurityException(final String MESSAGE, final Throwable CAUSE, final StackTraceElement RELATEDSTACKCALL)
    {
        super(MESSAGE, CAUSE);
        this.timestamp = Instant.now();
        this.relatedStackCall = RELATEDSTACKCALL;
        try
        {
            SecurityExceptionHandler.handle(this);
        }
        catch (Exception ignored)
        {
        }
    }

    public Instant getTimestamp()
    {
        return this.timestamp;
    }

    public StackTraceElement getRelatedStackCall()
    {
        return this.relatedStackCall;
    }

    @Override
    public String toString()
    {
        return "BodiSecurityException{" + getMessage() + ", time=" + timestamp + ", at=" + relatedStackCall + "}";
    }
}
