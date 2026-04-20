import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.Writer;
import java.util.Date;

public class TelnetCommunicationProxy
{
    protected WebExpress web_express;

    protected ProcessBuilder process_builder = new ProcessBuilder();

    protected Process process;

    protected BufferedWriter writer;

    protected BufferedReader reader;

    protected TelnetProxyCommunicator telnet_proxy_communicator;

    public TelnetCommunicationProxy(WebExpress web_express)
    {
        System.out.println("[Object ID: "+this.hashCode()+"] WebExpress::Telnet::Communicator >> starts ["+new Date()+"].");

        this.web_express = web_express;

        this.process_builder = this.web_express.telnet_installer.process_builder;

        this.process = this.web_express.telnet_installer.process;

        this.writer = this.web_express.telnet_installer.writer;

        this.reader = this.web_express.telnet_installer.reader;

        this.telnet_proxy_communicator = this.web_express.telnet_communication_proxy.telnet_proxy_communicator;
    }

    public static class TelnetProxyCommunicator extends Thread
    {
        protected TelnetCommunicationProxy telnet_communication_proxy;

        public TelnetProxyCommunicator(TelnetCommunicationProxy telnet_communication_proxy)
        {
            this.telnet_communication_proxy = telnet_communication_proxy;
        }

        @Override
        public void run()
        {
            StringBuffer buffer = new StringBuffer();

            for(;;)
            {
                try
                {
                    String input_line = this.telnet_communication_proxy.reader.readLine();

                    if(input_line==null)
                    {
                        continue;
                    }
                    else
                    {
                        for(;((input_line=this.telnet_communication_proxy.reader.readLine())!=null);)
                        {
                            if(input_line==null)
                            {
                                break;
                            }
                            else
                            {
                                buffer.append(input_line);
                            }
                        }
                    }
                }
                catch (Exception e)
                {
                    System.out.println("[Object ID: "+this.hashCode()+"] TelnetProxyCommunicator::SocketListener::Input >> exception ["+e.getMessage()+"]");
                }

                try
                {
                    Writer writer = this.telnet_communication_proxy.writer;

                    for(;;)
                    {
                        writer.write(buffer.toString());

                        writer.flush();
                    }
                }
                catch (Exception e)
                {
                    System.out.println("[Object ID: "+this.hashCode()+"] TelnetProxyCommunicator::SocketListener::Input >> exception ["+e.getMessage()+"]");
                }
            }
        }
    }

    protected stochastic _process_builder;

    protected stochastic _process;

    protected stochastic _writer;

    protected stochastic _reader;
}