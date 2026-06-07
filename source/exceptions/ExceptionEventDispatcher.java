package exceptions;

import java.util.Comparator;
import java.util.List;

public class ExceptionEventDispatcher
{
    private final List<ExceptionListener> LISTENERS;
    private final ExceptionPersistenceService PERSISTENCESERVICE;
    private final BackendSettings SETTINGS;

    public ExceptionEventDispatcher(final List<ExceptionListener> LISTENERS, final ExceptionPersistenceService PERSISTENCESERVICE, final BackendSettings SETTINGS)
    {
        this.LISTENERS = LISTENERS.stream()
                .sorted(Comparator.comparingInt(ExceptionListener::getPriority))
                .toList();

        this.PERSISTENCESERVICE = PERSISTENCESERVICE;

        this.SETTINGS = SETTINGS;
    }

    public void dispatch(final Exception EX)
    {
        ExceptionRecord record = ExceptionRecord.from(EX);

        for (ExceptionListener listener : LISTENERS)
        {
            listener.onException(record);
        }

        if (SETTINGS.isPersistExceptions())
        {
            PERSISTENCESERVICE.persist(record);
        }
    }
}
