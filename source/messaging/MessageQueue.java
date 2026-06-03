/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package messaging;

import commons.CommonRails;
import connections.Connection;
import server.base.BaseServer;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class MessageQueue
{
    protected String hash = "0xDA717018470E213F";

    public ArrayList<Message> MESSAGES;

    protected BaseServer base_server;

    public MessageQueue(BaseServer base_server)
    {
        this.base_server = base_server;

        this.MESSAGES = new ArrayList<>(5000);
    }

    public synchronized void clear()
    {
        this.MESSAGES = null;

        this.MESSAGES = new ArrayList<>(5000);
    }

    public synchronized void send(Message message)
    {
        BufferedWriter writer;

        if (message == null || message.socket == null || message.MESSAGE_BUFFER == null)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "MessageQueue::TelnetQuickSend >> null message, socket, or buffer; skipping send.");

            return;
        }

        try
        {
            writer = new BufferedWriter(new OutputStreamWriter(message.socket.getOutputStream()));

            writer.write(message.MESSAGE_BUFFER.toString(), 0, message.MESSAGE_BUFFER.length());

            writer.flush();

            message.MESSAGE_BUFFER = new StringBuffer();

            CommonRails.printSystemComponent(this, this.hashCode(), "MessageQueue TelnetQuickSend >> writing initial handshake to Telnet Remote System ["+message.socket+"].");
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "MessageQueue TelnetQuickSend >> attempted writing initial handshake to Telnet Remote System ["+message.socket+"].");
        }
    }

    public synchronized void add(Message message)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),"MessageQueue add >> receives ["+message.MESSAGE_BUFFER.toString()+"].");

        this.MESSAGES.add(message);
        this.notifyAll();
    }

    public synchronized void remove(Message message)
    {
        this.MESSAGES.remove(message);
    }

    public synchronized Integer size()
    {
        return this.MESSAGES.size();
    }

    public static class Message
    {
        public Connection connection;

        public Socket socket;

        public Date time_stamp;

        public StringBuffer MESSAGE_BUFFER = new StringBuffer();

        public InetAddress internet_address;
    }
}