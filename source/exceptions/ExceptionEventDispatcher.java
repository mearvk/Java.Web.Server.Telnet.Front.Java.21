package exceptions;

import java.util.Comparator;
import java.util.List;

public class ExceptionEventDispatcher
{
    private final List<ExceptionListener> listeners;
    private final ExceptionPersistenceService persistenceService;
    private final BackendSettings settings;

    public ExceptionEventDispatcher(List<ExceptionListener> listeners, ExceptionPersistenceService persistenceService, BackendSettings settings)
    {
        this.listeners = listeners.stream()
                .sorted(Comparator.comparingInt(ExceptionListener::getPriority))
                .toList();

        this.persistenceService = persistenceService;

        this.settings = settings;
    }

    public void dispatch(Exception ex)
    {
        ExceptionRecord record = ExceptionRecord.from(ex);

        for (ExceptionListener listener : listeners)
        {
            listener.onException(record);
        }

        if (settings.isPersistExceptions())
        {
            persistenceService.persist(record);
        }
    }
}
