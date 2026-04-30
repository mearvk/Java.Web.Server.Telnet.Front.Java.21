package messaging;

import commons.CommonRails;
import connections.Connection;
import server.BaseServer;

import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class MessageQueue
{
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