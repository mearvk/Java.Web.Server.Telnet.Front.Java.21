package exceptions;

import java.io.FileWriter;
import java.io.IOException;
import java.time.Instant;

public class PersistenceListener implements ExceptionListener
{
    private static final int PRIORITY = 100;

    private final String filePath;

    public PersistenceListener(final String FILEPATH)
    {
        this.filePath = FILEPATH;
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
        try (FileWriter writer = new FileWriter(filePath, true))
        {
            writer.write("[EXCEPTION] " + Instant.now() + System.lineSeparator() + "Type: " + RECORD.exception().getClass().getName() + System.lineSeparator() + "Message: " + RECORD.exception().getMessage() + System.lineSeparator() + "Origin: " + RECORD.origin() + System.lineSeparator() + "StackTrace: " + RECORD.stackTrace() + System.lineSeparator() + "------------------------------------------------------------" + System.lineSeparator());
        }
        catch (IOException ioEx)
        {
            System.err.println("[PERSISTENCE-ERROR] Failed to write exception RECORD: " + ioEx.getMessage());
        }
    }
}
