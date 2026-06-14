package telnet;

import commons.CommonRails;
import exceptions.ExceptionHandler;
import server.webexpress.WebExpress;

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

            try
            {
                CommonRails.registerProcess(this.process_builder, this.process, this);
            }
            catch (Exception ignore)
            {
                ignore.printStackTrace(System.err);
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