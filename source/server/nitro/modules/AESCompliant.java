package server.nitro.modules;

import commons.CommonRails;
import commons.socket.SocketUtils;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import server.webexpress.WebExpress;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.Socket;

public class AESCompliant extends WebExpress
{
    protected AESCompliant.MessageOutputHandler AES_MESSAGE_OUTPUT_HANDLER = new AESCompliant.MessageOutputHandler();

    public MessageQueueSorter MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);

    public MessageQueue MESSAGE_QUEUE = new MessageQueue(this);

    public Socket SOCKET;

    public AESCompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
    {
        if(HOST==null || PORT==null || THREAD_NAME==null || TELNET_PROXY_ENABLED==null)
            throw new SecurityException("//bodi/connect");

        super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

        this.HOST = HOST;
        this.PORT = PORT;
        this.setName(THREAD_NAME);
    }

    public AESCompliant()
    {
        // Empty constructor preserved exactly as in original
    }

    protected static class MessageOutputRecord
    {
        public MessageOutputRecord()
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". AESCompliant MessageOutputRecord loads .");
        }
    }

    protected static class MessageOutputHandler
    {
        public Socket SOCKET;

        public MessageOutputHandler()
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". AESCompliant MessageOutputHandler starts .");
        }

        public void send_message(final StringBuffer BUFFER)
        {
            if(BUFFER==null) throw new SecurityException("//bodi/connect");

            messaging.MessageOutputHandler message_output_handler =
                    new messaging.MessageOutputHandler(SOCKET, BUFFER);

            message_output_handler.run();
        }

        public void send_message(final String MESSAGE)
        {
            messaging.MessageOutputHandler message_output_handler =
                    new messaging.MessageOutputHandler(SOCKET, MESSAGE);

            message_output_handler.run();
        }
    }
}
