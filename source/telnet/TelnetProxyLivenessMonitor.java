package telnet;

import commons.CommonRails;
import commons.formatting.LineFormatter;
import commons.printing.StartsCanonical;
import exceptions.ExceptionHandler;

import java.util.concurrent.TimeUnit;

/**
 * Monitors liveness of the backend telnet proxy process.
 *
 * Behaviour:
 *  - Runs continuously as a daemon thread.
 *  - When at least one frontend client is connected it probes the proxy
 *    every PROBE_INTERVAL_MS by writing a NOP (empty flush) to the writer.
 *  - If the probe fails, or the backing process is no longer alive,
 *    it calls TelnetCommunicationProxy.reconnect() to restart the session.
 *  - When no clients are connected it sleeps at IDLE_INTERVAL_MS to avoid
 *    unnecessary reconnection churn.
 */
public class TelnetProxyLivenessMonitor extends Thread
{
    private static final long PROBE_INTERVAL_MS  = 15_000L;
    private static final long IDLE_INTERVAL_MS   = 5_000L;
    private static final long RECONNECT_DELAY_MS = 3_000L;

    private final TelnetCommunicationProxy PROXY;

    public TelnetProxyLivenessMonitor(final TelnetCommunicationProxy PROXY)
    {
        this.PROXY = PROXY;
        this.setName("TelnetProxyLivenessMonitor");
        this.setDaemon(true);
    }

    @StartsCanonical
    @Override
    public void run()
    {
        CommonRails.printSystemComponent(this, this.hashCode(), ". TelnetProxyLivenessMonitor " + LineFormatter.starts() + " .");

        while (!Thread.currentThread().isInterrupted())
        {
            try
            {
                boolean clientsConnected = PROXY.WEB_EXPRESS.CURRENT_CONNECTIONS.size() > 0;

                if (clientsConnected)
                {
                    if (!isProxyAlive())
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),
                            ". TelnetProxyLivenessMonitor >> proxy dead with active clients — reconnecting .");

                        reconnect();
                    }
                    else
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),
                            ". TelnetProxyLivenessMonitor >> proxy alive, clients=" + PROXY.WEB_EXPRESS.CURRENT_CONNECTIONS.size() + " .");
                    }

                    Thread.sleep(PROBE_INTERVAL_MS);
                }
                else
                {
                    Thread.sleep(IDLE_INTERVAL_MS);
                }
            }
            catch (InterruptedException ie)
            {
                Thread.currentThread().interrupt();
                return;
            }
            catch (Exception e)
            {
                ExceptionHandler.dispatch(e);
                e.printStackTrace(System.err);
            }
        }
    }

    /**
     * Returns true if the backing process is alive.
     */
    private boolean isProxyAlive()
    {
        return PROXY.process != null && PROXY.process.isAlive();
    }

    /**
     * Tears down the dead proxy resources and restarts via TelnetInstaller,
     * then re-wires the proxy's reader/writer/process references.
     */
    private void reconnect()
    {
        try
        {
            // Destroy the old process if still lingering
            try
            {
                if (PROXY.process != null && PROXY.process.isAlive())
                {
                    PROXY.process.destroyForcibly();
                    PROXY.process.waitFor(5, TimeUnit.SECONDS);
                }
            }
            catch (Exception e)
            {
                ExceptionHandler.dispatch(e);
            }

            Thread.sleep(RECONNECT_DELAY_MS);

            // Reinstall — TelnetInstaller starts a fresh telnet process and sets up new streams
            TelnetInstaller installer = new TelnetInstaller(PROXY.WEB_EXPRESS);

            PROXY.process_builder = installer.process_builder;
            PROXY.process          = installer.process;
            PROXY.writer           = installer.writer;
            PROXY.reader           = installer.reader;

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". TelnetProxyLivenessMonitor >> proxy reconnected, process=" + PROXY.process + " .");
        }
        catch (InterruptedException ie)
        {
            Thread.currentThread().interrupt();
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);
        }
    }
}
