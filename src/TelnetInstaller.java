import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.util.Date;

public class TelnetInstaller
{
    protected WebExpress web_express;

    protected ProcessBuilder process_builder = new ProcessBuilder();

    protected Process process;

    protected BufferedWriter writer;

    protected BufferedReader reader;

    public TelnetInstaller(WebExpress web_express)
    {
        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::Telnet::Installer >> starts [" + new Date() + "].");

        try
        {
            this.web_express = web_express;

            this.process_builder.command(WebExpress.TELNET_PROXY_SERVER_ARGS);

            this.process = process_builder.start();

            this.reader = new BufferedReader(new InputStreamReader(process.getInputStream()));

            this.writer = new BufferedWriter(new OutputStreamWriter(process.getOutputStream()));

            //CommonRails._long("TelnetCommunicator::Close::Hook", this.web_express, 1000);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}