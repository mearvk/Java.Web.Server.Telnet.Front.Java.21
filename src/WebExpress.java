import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class WebExpress extends CommonRail
{
    protected Integer listener_port = 49152;

    protected Integer AES2_listener_port = 5512;

    protected ServerSocket server_socket;

    protected ServerSocket AES2_server_socket;

    protected ArrayList<MessageQueue> message_queue = new ArrayList<>(5000);

    protected TelnetCommunicator telnet_communicator = new TelnetCommunicator();

    protected MessageQueueSorter sorter = new MessageQueueSorter();

    public WebExpress()
    {

    }

    public static class TelnetCommunicator
    {
        public TelnetCommunicator()
        {

        }

        protected ProcessBuilder process_builder = new ProcessBuilder();

        protected Process process;

        protected BufferedWriter writer;

        protected BufferedReader reader;
    }

    public static class MessageQueueSorter extends Thread
    {
        public MessageQueueSorter()
        {

        }

        @Override
        public void run()
        {

        }
    }

    public static class MessageQueue
    {
        public MessageQueue()
        {

        }

        protected Socket socket;

        protected Date time_stamp;

        protected StringBuffer message_buffer = new StringBuffer();

        protected InetAddress internet_address;
    }

    public void install()
    {
        try
        {
            this.server_socket = new ServerSocket(this.listener_port);

            this.AES2_server_socket = new ServerSocket(this.AES2_listener_port);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }

    public void listen()
    {
        try
        {
            for(;;)
            {
                Socket socket = this.server_socket.accept();

                MessageQueue message_queue = new MessageQueue();

                message_queue.socket = socket;

                message_queue.internet_address = socket.getInetAddress();

                message_queue.time_stamp = new Date(System.currentTimeMillis());

                BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));

                StringBuffer buffer = new StringBuffer();

                String line = null;

                for(;(line=reader.readLine())!=null;)
                {
                    buffer.append(line);
                }

                message_queue.message_buffer = buffer;

                this.message_queue.add(message_queue);

                Thread.sleep(100);
            }
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }

    public void local()
    {
        try
        {
            this.telnet_communicator.process_builder.command("telnet localhost 80");

            this.telnet_communicator.process = this.telnet_communicator.process_builder.start();

            this.telnet_communicator.reader = new BufferedReader(new InputStreamReader(this.telnet_communicator.process.getInputStream()));

            this.telnet_communicator.writer = new BufferedWriter(new OutputStreamWriter(this.telnet_communicator.process.getOutputStream()));

            this._long("TelnetCommunicator::Close::Hook", this,1000);
        }
        catch (Exception e)
        {
            e.printStackTrace(System.err);
        }
    }
}
