package exceptions;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.Instant;

public class PersistenceListener implements ExceptionListener
{
    private static final int PRIORITY = 100;

    private final String FILEPATH;

    public PersistenceListener(final String FILEPATH)
    {
        this.FILEPATH = FILEPATH;
    }

    @Override
    public int getPriority()
    {
        return PRIORITY;
    }

    @Override
    public void onException(final ExceptionRecord RECORD)
    {
        writeRecordToFile(RECORD);
    }

    private void writeRecordToFile(final ExceptionRecord RECORD)
    {
        try
        {
            new File(FILEPATH).getParentFile().mkdirs();
        }
        catch (Exception ignored) {}

        try (FileWriter writer = new FileWriter(FILEPATH, true))
        {
            writer.write("[EXCEPTION] " + Instant.now() + System.lineSeparator() + "Type: " + RECORD.EXCEPTION().getClass().getName() + System.lineSeparator() + "Message: " + RECORD.EXCEPTION().getMessage() + System.lineSeparator() + "Origin: " + RECORD.ORIGIN() + System.lineSeparator() + "StackTrace: " + RECORD.STACKTRACE() + System.lineSeparator() + "------------------------------------------------------------" + System.lineSeparator());
        }
        catch (IOException ioEx)
        {
            System.err.println("[PERSISTENCE-ERROR] Failed to write exception RECORD: " + ioEx.getMessage());
        }
    }
}
