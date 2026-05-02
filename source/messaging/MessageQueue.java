package messaging;

import commons.CommonRails;
import connections.Connection;
import server.BaseServer;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class MessageQueue
{
    protected String hash = "0xDA717018470E213F";

    protected ArrayList<Message> messages;

    protected BaseServer base_server;

    public MessageQueue(BaseServer base_server)
    {
        this.base_server = base_server;

        this.messages = new ArrayList<>(5000);
    }

    public synchronized void clear()
    {
        this.messages = null;

        this.messages = new ArrayList<>(5000);
    }

    public synchronized void send(Message message)
    {
        BufferedWriter writer;

        try
        {
            writer = new BufferedWriter(new OutputStreamWriter(message.socket.getOutputStream()));

            writer.write(message.message_buffer.toString(), 0, message.message_buffer.length());

            writer.flush();

            message.message_buffer = new StringBuffer();

            CommonRails.printSystemComponent(this.hashCode(), "MessageQueue::TelnetQuickSend >> writing initial handshake to Telnet Remote System ["+message.socket+"].");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this.hashCode(), "MessageQueue::TelnetQuickSend >> attempted writing initial handshake to Telnet Remote System ["+message.socket+"].");
        }
    }

    public synchronized void add(Message message)
    {
        CommonRails.printSystemComponent(this.hashCode(),"MessageQueue::add >> receives ["+message.message_buffer.toString()+"].");

        this.messages.add(message);
    }

    public synchronized void remove(Message message)
    {
        this.messages.remove(message);
    }

    public synchronized Integer size()
    {
        return this.messages.size();
    }

    public static class Message
    {
        public Connection connection;

        public Socket socket;

        public Date time_stamp;

        public StringBuffer message_buffer = new StringBuffer();

        public InetAddress internet_address;
    }
}