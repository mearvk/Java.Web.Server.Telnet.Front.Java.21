package exceptions;

import java.io.FileWriter;
import java.io.IOException;
import java.time.Instant;

public class PersistenceListener implements ExceptionListener
{
    private static final int PRIORITY = 100;

    private final String filePath;

    public PersistenceListener(String filePath)
    {
        this.filePath = filePath;
    }

    @Override
    public int getPriority()
    {
        return PRIORITY;
    }

    @Override
    public void onException(ExceptionRecord record)
    {
        writeRecordToFile(record);
    }

    private void writeRecordToFile(ExceptionRecord record)
    {
        try (FileWriter writer = new FileWriter(filePath, true))
        {
            writer.write("[EXCEPTION] " + Instant.now() + System.lineSeparator() + "Type: " + record.exception().getClass().getName() + System.lineSeparator() + "Message: " + record.exception().getMessage() + System.lineSeparator() + "Origin: " + record.origin() + System.lineSeparator() + "StackTrace: " + record.stackTrace() + System.lineSeparator() + "------------------------------------------------------------" + System.lineSeparator());
        }
        catch (IOException ioEx)
        {
            System.err.println("[PERSISTENCE-ERROR] Failed to write exception record: " + ioEx.getMessage());
        }
    }
}
