package exceptions;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.Instant;

public class ExceptionPersistenceService
{

    private final String FILEPATH;

    public ExceptionPersistenceService(final String FILEPATH)
    {
        this.FILEPATH = FILEPATH;
    }

    /**
     * Persist an ExceptionRecord to disk synchronously.
     * This method must NEVER throw — persistence failures
     * are logged but do not interrupt the exception pipeline.
     */
    public void persist(final ExceptionRecord RECORD)
    {
        try
        {
            new File(FILEPATH).getParentFile().mkdirs();
        }
        catch (Exception ignored) {}

        try (FileWriter writer = new FileWriter(FILEPATH, true))
        {

            writer.write("[EXCEPTION] " + Instant.now() + System.lineSeparator() +
                            "Type: " + RECORD.EXCEPTION().getClass().getName() + System.lineSeparator() +
                            "Message: " + RECORD.EXCEPTION().getMessage() + System.lineSeparator() +
                            "Origin: " + RECORD.ORIGIN() + System.lineSeparator() +
                            "StackTrace:" + System.lineSeparator() +
                            RECORD.STACKTRACE() + System.lineSeparator() +
                            "------------------------------------------------------------" +
                            System.lineSeparator()
            );

        } catch (IOException ioEx)
        {
            System.err.println("[PERSISTENCE-ERROR] Failed to write exception RECORD: " + ioEx.getMessage());
        }
    }
}
