package server.nitro.modules;

import server.webexpress.WebExpress;
import commons.CommonRails;
import exceptions.ExceptionHandler;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import encryption.module.dsa.EncryptionModuleDSA;

import java.net.Socket;

/**
 * Standalone DSACompliant server component extracted from NitroWebExpress.Aspect.
 */
public class DSACompliant extends WebExpress {

    public static final Integer DEFAULT_PORT   = 7744;
    public static final String  DEFAULT_THREAD = "WEBEXPRESS_DSA_SERVER";

    protected final MessageOutputHandler DSA_MESSAGE_OUTPUT_HANDLER = new MessageOutputHandler();

    public MessageQueueSorter MESSAGE_QUEUE_SORTER;
    public MessageQueue       MESSAGE_QUEUE;
    public Socket             SOCKET;

    public final EncryptionModuleDSA ENCRYPTION_MODULE =
            new EncryptionModuleDSA();

    public DSACompliant(final String HOST,
                        final Integer PORT,
                        final String THREAD_NAME,
                        final Boolean TELNET_PROXY_ENABLED)
    {
        super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

        if (HOST == null || PORT == null || THREAD_NAME == null || TELNET_PROXY_ENABLED == null)
            throw new SecurityException("//bodi/connect");

        this.HOST = HOST;
        this.PORT = PORT;

        this.MESSAGE_QUEUE        = new MessageQueue(this);
        this.MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);

        this.setName(THREAD_NAME);

        CommonRails.printSystemComponent(
                this,
                this.hashCode(),
                ". DSACompliant starting on " + HOST + ":" + PORT + " ."
        );
    }

    public DSACompliant() {
        // Optional empty constructor
    }

    /**
     * Handles outbound DSA messages.
     */
    protected static class MessageOutputHandler {

        public Socket SOCKET;

        public MessageOutputHandler() {
            CommonRails.printSystemComponent(
                    this,
                    this.hashCode(),
                    ". DSACompliant MessageOutputHandler starts ."
            );
        }

        public void send_message(final String MESSAGE) {
            if (MESSAGE == null) throw new SecurityException("//bodi/connect");
            messaging.MessageOutputHandler h =
                    new messaging.MessageOutputHandler(SOCKET, MESSAGE);
            h.run();
        }

        public void send_message(final StringBuffer BUFFER) {
            if (BUFFER == null) throw new SecurityException("//bodi/connect");
            messaging.MessageOutputHandler h =
                    new messaging.MessageOutputHandler(SOCKET, BUFFER);
            h.run();
        }
    }
}
