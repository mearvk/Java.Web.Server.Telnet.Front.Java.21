package exceptions;

import java.util.List;

public class BackendSettings
{
    private final boolean persistExceptions;
    private final String persistenceFilePath;
    private final List<ExceptionListener> LISTENERS;

    public BackendSettings(final boolean PERSISTEXCEPTIONS, final String PERSISTENCEFILEPATH, final List<ExceptionListener> LISTENERS)
    {
        this.persistExceptions = PERSISTEXCEPTIONS;

        this.persistenceFilePath = PERSISTENCEFILEPATH;

        this.LISTENERS = List.copyOf(LISTENERS);
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
        return LISTENERS;
    }
}

