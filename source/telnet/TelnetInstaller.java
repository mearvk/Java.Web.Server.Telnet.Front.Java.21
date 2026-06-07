package telnet;

import commons.CommonRails;
import exceptions.ExceptionHandler;
import server.nitro.WebExpress;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.Socket;

public class TelnetInstaller
{
    public WebExpress WEB_EXPRESS;

    protected ProcessBuilder process_builder = new ProcessBuilder();

    protected Process process;

    protected Socket socket;

    protected BufferedWriter writer;

    protected BufferedReader reader;

    public TelnetInstaller(final WebExpress WEB_EXPRESS)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress Telnet Installer starts .");

        try
        {
            this.WEB_EXPRESS = WEB_EXPRESS;

            this.process_builder.command(WebExpress.TELNET_PROXY_SERVER_ARGS);

            this.process = process_builder.start();

            // register process with CommonRails so it can monitor exit/finish events
            try {
                CommonRails.registerProcess(this.process_builder, this.process, this);
            } catch (Exception ignore) {
                // best-effort: don't let registration prevent initialization
            }

            this.reader = new BufferedReader(new InputStreamReader(process.getInputStream()));

            this.writer = new BufferedWriter(new OutputStreamWriter(process.getOutputStream()));

            //commons.CommonRails._long("TelnetCommunicator Close Hook", this.WEB_EXPRESS, 1000);
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);
        }
    }
}