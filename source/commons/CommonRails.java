package commons;

import server.nitro.WebExpress;

import java.net.Socket;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Collections;

public class CommonRails
{
    protected String hash = "0xDA717018470E213F";

    public CommonRails()
    {

    }

    public static <T> Integer size(ArrayList<T> list)
    {
        return list.size();
    }

    public static void printSystemComponent(Object object, Integer hashcode, String line)
    {
        String classname = "[Current: "+object.getClass().getSimpleName()+"]";

        String compliant_hashcode = String.format("%010d", hashcode);

        String object_id = "-- : [Object ID: "+compliant_hashcode+"]";

        SimpleDateFormat formatter = new SimpleDateFormat("HH:mm:ss");

        String date = "[Date: "+formatter.format(new Date())+"]";

        String reference = object_id + " "+ date + " " + classname + " " + line;

        CommonRails.delayableFinePrinter(reference, 21);

        //System.out.println("\u001B[0m");
    }

    public static void delayableFinePrinter(String text, int delay)
    {
        int[] codes = {232, 233, 234, 235, 236, 237, 238, 241, 244, 247, 250, 253, 188};

        try
        {
            for(int color : codes)
            {
                System.out.print("\033[38;5;" + color + "m" + text + "\r");

                Thread.sleep(delay);
            }

            Thread.sleep(400L);

            System.out.println(text);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }

    protected static void _long(final String orgasm, WebExpress web_express, Integer not_less_than)
    {
        try
        {
            Thread.sleep(not_less_than);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }

        switch (orgasm)
        {
            case "TelnetCommunicator::Close::Hook":

                try
                {
                    TelnetCallOnComplete call_on_complete = new TelnetCallOnComplete(web_express);

                    call_on_complete.run();
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }

                break;
        }
    }

    public static class SocketUtils
    {
        public static Boolean isSocketConnected(Socket socket)
        {
            try
            {
                socket.getOutputStream().write("".getBytes());
            }
            catch (Exception e)
            {
                return false;
            }

            return true;
        }

        public static Boolean isSocketClosed(Socket socket)
        {
            try
            {
                socket.getOutputStream().write("".getBytes());
            }
            catch(Exception e)
            {
                return true;
            }

            return false;
        }
    }

    // Registry for started Processes so CommonRails can monitor them and print on exit
    protected static final List<Process> REGISTERED_PROCESSES = Collections.synchronizedList(new ArrayList<Process>());

    /**
     * Register a started Process with CommonRails. CommonRails will attach a listener
     * to the process' onExit CompletableFuture (Java 9+) and print when the process exits.
     * If onExit is unavailable/throws, a watcher thread using waitFor is started as a fallback.
     */
    public static synchronized void registerProcess(ProcessBuilder pb, Process process, Object owner)
    {
        if (process == null) return;

        REGISTERED_PROCESSES.add(process);

        Object printer = (owner == null) ? CommonRails.class : owner;

        try
        {
            CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails::registerProcess >> registered process: " + process);

            // Attach onExit listener
            process.onExit().thenAccept(p -> {
                try
                {
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails::processExited >> process closed: " + p + " exit=" + p.exitValue());
                }
                catch (Throwable t)
                {
                    // Best-effort printing
                    CommonRails.printSystemComponent(printer, p.hashCode(), ". CommonRails::processExited >> process closed: " + p);
                }
                finally
                {
                    REGISTERED_PROCESSES.remove(p);
                }
            });
        }
        catch (Throwable t)
        {
            // Fallback: spawn a watcher thread that waits for the process
            new Thread(() -> {
                try
                {
                    int rv = process.waitFor();

                    CommonRails.printSystemComponent(printer, process.hashCode(), ". CommonRails::processExited(watcher) >> process closed: " + process + " exit=" + rv);
                }
                catch (Exception e)
                {
                    e.printStackTrace(System.err);
                }
                finally
                {
                    REGISTERED_PROCESSES.remove(process);
                }
            }, "CommonRails-ProcessWatcher-" + process.hashCode()).start();
        }
    }

    public static synchronized List<Process> getRegisteredProcesses()
    {
        return new ArrayList<>(REGISTERED_PROCESSES);
    }

    public static class TelnetCallOnComplete implements Runnable
    {
        protected WebExpress web_express;

        public TelnetCallOnComplete(WebExpress web_express)
        {
            this.web_express = web_express;
        }

        @Override
        public void run()
        {
            try
            {
                int return_value = this.web_express.TELNET_COMMUNICATION_PROXY.process.waitFor();
            }
            catch (Exception e)
            {
                e.printStackTrace(System.err);
            }
        }
    }
}
