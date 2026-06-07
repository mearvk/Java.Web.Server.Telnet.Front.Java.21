/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package messaging;

import commons.CommonRails;
import connections.Connection;
import exceptions.ExceptionHandler;
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

    protected BaseServer BASE_SERVER;

    public MessageQueue(final BaseServer BASE_SERVER)
    {
        this.BASE_SERVER = BASE_SERVER;

        this.MESSAGES = new ArrayList<>(5000);
    }

    public synchronized void clear()
    {
        this.MESSAGES = null;

        this.MESSAGES = new ArrayList<>(5000);
    }

    public synchronized void send(final Message MESSAGE)
    {
        BufferedWriter writer;

        if (MESSAGE == null || MESSAGE.SOCKET == null || MESSAGE.MESSAGE_BUFFER == null)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), "MessageQueue::TelnetQuickSend >> null MESSAGE, socket, or buffer; skipping send.");

            return;
        }

        try
        {
            writer = new BufferedWriter(new OutputStreamWriter(MESSAGE.SOCKET.getOutputStream()));

            writer.write(MESSAGE.MESSAGE_BUFFER.toString(), 0, MESSAGE.MESSAGE_BUFFER.length());

            writer.flush();

            MESSAGE.MESSAGE_BUFFER = new StringBuffer();

            CommonRails.printSystemComponent(this, this.hashCode(), "MessageQueue TelnetQuickSend >> writing initial handshake to Telnet Remote System ["+MESSAGE.SOCKET +"].");
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            CommonRails.printSystemComponent(this, this.hashCode(), "MessageQueue TelnetQuickSend >> attempted writing initial handshake to Telnet Remote System ["+MESSAGE.SOCKET +"].");
        }
    }

    public synchronized void add(final Message MESSAGE)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),"MessageQueue add >> receives ["+MESSAGE.MESSAGE_BUFFER.toString()+"].");

        this.MESSAGES.add(MESSAGE);
        this.notifyAll();
    }

    public synchronized void remove(final Message MESSAGE)
    {
        this.MESSAGES.remove(MESSAGE);
    }

    public synchronized Integer size()
    {
        return this.MESSAGES.size();
    }

    public static class Message
    {
        public Connection CONNECTION;

        public Socket SOCKET;

        public Date TIME_STAMP;

        public StringBuffer MESSAGE_BUFFER = new StringBuffer();

        public InetAddress INTERNET_ADDRESS;
    }
}