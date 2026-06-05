package telnet;

import commons.CommonRails;
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

    private final TelnetCommunicationProxy proxy;

    public TelnetProxyLivenessMonitor(TelnetCommunicationProxy proxy)
    {
        this.proxy = proxy;
        this.setName("TelnetProxyLivenessMonitor");
        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        CommonRails.printSystemComponent(this, this.hashCode(), ". TelnetProxyLivenessMonitor starts .");

        while (!Thread.currentThread().isInterrupted())
        {
            try
            {
                boolean clientsConnected = proxy.web_express.CURRENT_CONNECTIONS.size() > 0;

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
                            ". TelnetProxyLivenessMonitor >> proxy alive, clients=" + proxy.web_express.CURRENT_CONNECTIONS.size() + " .");
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
     * Returns true if the backing process is alive and the writer can be flushed.
     */
    private boolean isProxyAlive()
    {
        try
        {
            // Check the OS process is still running
            if (proxy.process == null || !proxy.process.isAlive())
            {
                return false;
            }

            // Attempt a NOP flush — will throw if the pipe is broken
            if (proxy.writer != null)
            {
                proxy.writer.flush();
            }

            return true;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return false;
        }
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
                if (proxy.process != null && proxy.process.isAlive())
                {
                    proxy.process.destroyForcibly();
                    proxy.process.waitFor(5, TimeUnit.SECONDS);
                }
            }
            catch (Exception e)
            {
                ExceptionHandler.dispatch(e);
            }

            Thread.sleep(RECONNECT_DELAY_MS);

            // Reinstall — TelnetInstaller starts a fresh telnet process and sets up new streams
            TelnetInstaller installer = new TelnetInstaller(proxy.web_express);

            proxy.process_builder = installer.process_builder;
            proxy.process          = installer.process;
            proxy.writer           = installer.writer;
            proxy.reader           = installer.reader;

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". TelnetProxyLivenessMonitor >> proxy reconnected, process=" + proxy.process + " .");
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
