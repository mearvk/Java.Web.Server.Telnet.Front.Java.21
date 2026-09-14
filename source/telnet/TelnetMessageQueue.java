package telnet;

import server.base.BaseServer;

import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

public class TelnetMessageQueue
{
    protected List<Message> MESSAGES;

    protected Integer SIZE;

    protected BaseServer BASE_SERVER;

    public TelnetMessageQueue(final Integer SIZE)
    {
        this.SIZE = SIZE;

        this.MESSAGES = Collections.synchronizedList(MESSAGES = new ArrayList<>(this.SIZE));
    }

    public TelnetMessageQueue(final BaseServer BASE_SERVER)
    {
        this.BASE_SERVER = BASE_SERVER;

        this.MESSAGES = Collections.synchronizedList(MESSAGES = new ArrayList<>(5000));
    }

    public synchronized void add(final Message MESSAGE)
    {
        this.MESSAGES.add(MESSAGE);

        this.notifyAll();
    }

    public synchronized void remove(final Message MESSAGE)
    {
        this.MESSAGES.remove(MESSAGE);
    }

    public synchronized void sleep(final Message MESSAGE)
    {
        this.MESSAGES.add(MESSAGE);

        this.notifyAll();
    }

    public synchronized Integer size()
    {
        return this.MESSAGES.size();
    }

    public synchronized void delete(final Message MESSAGE)
    {
        this.MESSAGES = null;
    }

    public static class Message
    {
        public Integer PORT;

        public String protocol;

        public Socket SOCKET;

        public Date TIMESTAMP;

        public StringBuffer MESSAGE_BUFFER = new StringBuffer();

        public InetAddress internet_address;
    }
}