package telnet;

import server.BaseServer;

import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

public class TelnetMessageQueue
{
    protected List<Message> messages;

    protected Integer size;

    protected BaseServer base_server;

    public TelnetMessageQueue(Integer size)
    {
        this.size = size;

        this.messages = Collections.synchronizedList(messages = new ArrayList<>(this.size));
    }

    public TelnetMessageQueue(BaseServer base_server)
    {
        this.base_server = base_server;

        this.messages = Collections.synchronizedList(messages = new ArrayList<>(5000));
    }

    public synchronized void add(Message message)
    {
        this.messages.add(message);
    }

    public synchronized void remove(Message message)
    {
        this.messages.add(message);
    }

    public synchronized void sleep(Message message)
    {
        this.messages.add(message);
    }

    public synchronized Integer size()
    {
        return this.messages.size();
    }

    public synchronized void delete(Message message)
    {
        this.messages = null;
    }

    public static class Message
    {
        public Integer port;

        public String protocol;

        public Socket socket;

        public Date time_stamp;

        public StringBuffer message_buffer = new StringBuffer();

        public InetAddress internet_address;
    }
}