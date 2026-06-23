package exceptions;

import java.io.FileWriter;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

import commons.CommonRails;

/**
 * Singleton dispatcher wired with all standard listeners.
 * All source classes call ExceptionHandler.dispatch(e) to route exceptions
 * through the full listener/persistence pipeline.
 */
public class ExceptionHandler
{
    private static final ExceptionHandler INSTANCE = new ExceptionHandler();

    private static final String SHUTDOWN_LOG = "logging/shutdown.log";

    private final ExceptionEventDispatcher dispatcher;

    private ExceptionHandler()
    {
        ExceptionPersistenceService persistence = new ExceptionPersistenceService("logging/exceptions.log");

        BackendSettings settings = new BackendSettings(
            true,
            "logging/exceptions.log",
            List.of(
                new SecurityExceptionHandler(),
                new NullPointerConstructorHandler(),
                new PersistenceListener("logging/exceptions.log")
            )
        );

        dispatcher = new ExceptionEventDispatcher(
            List.of(
                new SecurityExceptionHandler(),
                new NullPointerConstructorHandler(),
                new N21ExceptionListener()
            ),
            persistence,
            settings
        );

        // Wire CommonRails catch blocks through this dispatcher without circular import
        CommonRails.setExceptionSink(this.dispatcher::dispatch);
    }

    public static ExceptionHandler getInstance()
    {
        return INSTANCE;
    }

    public static void dispatch(final Exception E)
    {
        INSTANCE.dispatcher.dispatch(E);
    }

    public static void dispatch(final Throwable T)
    {
        if (T instanceof Exception e)
        {
            INSTANCE.dispatcher.dispatch(e);
        }
        else
        {
            INSTANCE.dispatcher.dispatch(new RuntimeException(T));
        }
    }

    /**
     * Logs shutdown-phase exceptions to logging/shutdown.log.
     * Called from ShutdownHooks when file-not-found or other errors
     * occur during the shutdown sequence.
     */
    public static void dispatchShutdown(final Exception E)
    {
        try (PrintWriter pw = new PrintWriter(new FileWriter(SHUTDOWN_LOG, true)))
        {
            pw.printf("[%s] [shutdown] %s: %s%n",
                LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")),
                E.getClass().getSimpleName(),
                E.getMessage());
            E.printStackTrace(pw);
            pw.println();
        }
        catch (Exception ignored)
        {
            E.printStackTrace(System.err);
        }
    }
}
