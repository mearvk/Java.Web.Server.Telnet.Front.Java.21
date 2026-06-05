package exceptions;

import java.util.List;

public class BackendSettings
{
    private final boolean persistExceptions;
    private final String persistenceFilePath;
    private final List<ExceptionListener> listeners;

    public BackendSettings(boolean persistExceptions, String persistenceFilePath, List<ExceptionListener> listeners)
    {
        this.persistExceptions = persistExceptions;

        this.persistenceFilePath = persistenceFilePath;

        this.listeners = List.copyOf(listeners);
    }

    public boolean isPersistExceptions()
    {
        return persistExceptions;
    }

    public String getPersistenceFilePath()
    {
        return persistenceFilePath;
    }

    public List<ExceptionListener> getListeners()
    {
        return listeners;
    }
}

