import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.util.Date;

public class TelnetCommunicationProxy
{
    protected WebExpress web_express;

    protected ProcessBuilder process_builder = new ProcessBuilder();

    protected Process process;

    protected BufferedWriter writer;

    protected BufferedReader reader;

    public TelnetCommunicationProxy(WebExpress web_express)
    {
        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::Telnet::Communicator >> starts ["+new Date()+"].");

        this.web_express = web_express;

        this.process_builder = this.web_express.telnet_installer.process_builder;

        this.process = this.web_express.telnet_installer.process;

        this.writer = this.web_express.telnet_installer.writer;

        this.reader = this.web_express.telnet_installer.reader;
    }

    protected stochastic _process_builder;

    protected stochastic _process;

    protected stochastic _writer;

    protected stochastic _reader;
}