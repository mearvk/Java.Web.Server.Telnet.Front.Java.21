package exceptions;

import java.io.FileWriter;
import java.io.IOException;
import java.time.Instant;

public class ExceptionPersistenceService
{

    private final String filePath;

    public ExceptionPersistenceService(String filePath)
    {
        this.filePath = filePath;
    }

    /**
     * Persist an ExceptionRecord to disk synchronously.
     * This method must NEVER throw — persistence failures
     * are logged but do not interrupt the exception pipeline.
     */
    public void persist(ExceptionRecord record)
    {
        try (FileWriter writer = new FileWriter(filePath, true))
        {

            writer.write("[EXCEPTION] " + Instant.now() + System.lineSeparator() +
                            "Type: " + record.exception().getClass().getName() + System.lineSeparator() +
                            "Message: " + record.exception().getMessage() + System.lineSeparator() +
                            "Origin: " + record.origin() + System.lineSeparator() +
                            "StackTrace:" + System.lineSeparator() +
                            record.stackTrace() + System.lineSeparator() +
                            "------------------------------------------------------------" +
                            System.lineSeparator()
            );

        } catch (IOException ioEx)
        {
            System.err.println("[PERSISTENCE-ERROR] Failed to write exception record: " + ioEx.getMessage());
        }
    }
}
