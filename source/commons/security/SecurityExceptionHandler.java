/**
 * Handler and backend for security exceptions. Writes a simple XML record and performs escalation hooks.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */
package commons.security;

import commons.CommonRails;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Instant;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;

public class SecurityExceptionHandler
{
    private static final Path SECURITY_DIR = Path.of("data", "security");

    private static final BlockingQueue<BodiSecurityException> QUEUE = new ArrayBlockingQueue<>(1024);

    private static final Thread WORKER;

    static
    {
        WORKER = new Thread(() -> {
            while (true)
            {
                try
                {
                    BodiSecurityException ev = QUEUE.poll(5, TimeUnit.SECONDS);

                    if (ev != null)
                    {
                        process(ev);
                    }
                }
                catch (InterruptedException ie)
                {
                    Thread.currentThread().interrupt();
                    break;
                }
                catch (Throwable t)
                {
                    CommonRails.printSystemComponent(SecurityExceptionHandler.class, 0, "SecurityExceptionHandler worker error: " + t.getMessage());
                }
            }
        }, "SecurityExceptionHandler-Worker");

        WORKER.setDaemon(true);

        WORKER.start();
    }

    public static void handle(final BodiSecurityException ex)
    {
        if (ex == null) return;

        // enqueue, try non-blocking first
        if (!QUEUE.offer(ex))
        {
            try
            {
                QUEUE.put(ex);
            }
            catch (InterruptedException ie)
            {
                Thread.currentThread().interrupt();
            }
        }
    }

    private static void process(final BodiSecurityException ex)
    {
        if (ex == null) return;

        try
        {
            if (!Files.exists(SECURITY_DIR)) Files.createDirectories(SECURITY_DIR);

            String fileName = "security-events.xml";

            Path out = SECURITY_DIR.resolve(fileName);

            StringBuilder xml = new StringBuilder();

            xml.append("<securityEvent>\n");

            xml.append("  <message>").append(escapeXml(ex.getMessage())).append("</message>\n");

            xml.append("  <timestamp>").append(Instant.now().toString()).append("</timestamp>\n");

            StackTraceElement st = ex.getRelatedStackCall();

            if (st != null)
            {
                xml.append("  <class>").append(escapeXml(st.getClassName())).append("</class>\n");
                xml.append("  <method>").append(escapeXml(st.getMethodName())).append("</method>\n");
                xml.append("  <file>").append(escapeXml(st.getFileName())).append("</file>\n");
                xml.append("  <line>").append(st.getLineNumber()).append("</line>\n");
            }

            xml.append("</securityEvent>\n");

            Files.writeString(out, xml.toString(), StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        }
        catch (IOException ioe)
        {
            CommonRails.printSystemComponent(SecurityExceptionHandler.class, 0, "SecurityExceptionHandler write failed: " + ioe.getMessage());
        }

        // Backend actions
        try
        {
            final String msg = ex.getMessage();

            // simple escalation: if connection-related, create a lockout file and log an alert
            if (msg != null && msg.contains("//bodi/connect"))
            {
                try
                {
                    Path alerts = SECURITY_DIR.resolve("alerts.log");

                    String alert = Instant.now().toString() + " - Connection access denied at " + (ex.getRelatedStackCall()!=null ? ex.getRelatedStackCall().toString() : "unknown") + "\n";

                    Files.writeString(alerts, alert, StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND);

                    // write a lockout placeholder file
                    String lockName = "lockout_" + System.currentTimeMillis() + ".lock";

                    Path lock = SECURITY_DIR.resolve("lockouts").resolve(lockName);

                    if (!Files.exists(lock.getParent())) Files.createDirectories(lock.getParent());

                    Files.writeString(lock, "LOCKOUT: " + alert, StandardCharsets.UTF_8, StandardOpenOption.CREATE);

                    // firewall placeholder action (do NOT execute system commands here) — just log intended action
                    Path fw = SECURITY_DIR.resolve("firewall_actions.log");

                    String fwAction = Instant.now().toString() + " - ACTION: block-source (placeholder) - origin=" + (ex.getRelatedStackCall()!=null ? ex.getRelatedStackCall().getClassName() : "unknown") + "\n";

                    Files.writeString(fw, fwAction, StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND);

                    CommonRails.printSystemComponent(SecurityExceptionHandler.class, 0, "Security event escalated and recorded.");
                }
                catch (Exception ioe)
                {
                    CommonRails.printSystemComponent(SecurityExceptionHandler.class, 0, "SecurityExceptionHandler escalation failed: " + ioe.getMessage());
                }
            }
        }
        catch (Exception ignored)
        {
        }
    }

    private static String escapeXml(final String s)
    {
        if (s == null) return "";

        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }
}
