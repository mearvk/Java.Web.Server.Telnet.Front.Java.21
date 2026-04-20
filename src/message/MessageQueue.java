package message;

import server.BaseServer;

import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

public class MessageQueue
{
    protected List<Message> messages;

    protected BaseServer base_server;

    public MessageQueue(BaseServer base_server)
    {
        this.base_server = base_server;

        this.messages = Collections.synchronizedList(messages = new ArrayList<>(5000));
    }

    public synchronized void add(Message message)
    {
        this.messages.add(message);
    }

    public static class Message
    {
        public Socket socket;

        public Date time_stamp;

        public StringBuffer message_buffer = new StringBuffer();

        public InetAddress internet_address;
    }
}