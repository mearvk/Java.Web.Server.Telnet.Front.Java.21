package exceptions;

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

    private final ExceptionEventDispatcher dispatcher;

    private ExceptionHandler()
    {
        ExceptionPersistenceService persistence = new ExceptionPersistenceService("exceptions.log");

        BackendSettings settings = new BackendSettings(
            true,
            "exceptions.log",
            List.of(
                new SecurityExceptionHandler(),
                new NullPointerConstructorHandler(),
                new PersistenceListener("exceptions.log")
            )
        );

        dispatcher = new ExceptionEventDispatcher(
            List.of(
                new SecurityExceptionHandler(),
                new NullPointerConstructorHandler(),
                new PersistenceListener("exceptions.log"),
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
}
