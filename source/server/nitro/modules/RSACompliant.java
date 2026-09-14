package server.nitro.modules;

import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import commons.CommonRails;
import commons.formatting.LineFormatter;
import commons.printing.StartsCanonical;
import server.webexpress.WebExpress;

public class RSACompliant extends WebExpress {

    public static final Integer DEFAULT_PORT   = 7743;
    public static final String  DEFAULT_THREAD = "WEBEXPRESS_RSA_SERVER";

    protected final MessageOutputHandler RSA_MESSAGE_OUTPUT_HANDLER = new MessageOutputHandler();

    public MessageQueueSorter MESSAGE_QUEUE_SORTER;
    public MessageQueue       MESSAGE_QUEUE;
    public java.net.Socket    SOCKET;

    public final encryption.module.rsa.EncryptionModuleRSA ENCRYPTION_MODULE =
            new encryption.module.rsa.EncryptionModuleRSA();

    public RSACompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED) {
        super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

        this.HOST  = HOST;
        this.PORT  = PORT;
        this.MESSAGE_QUEUE        = new MessageQueue(this);
        this.MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);
        this.setName(THREAD_NAME);

        CommonRails.printSystemComponent(this, this.hashCode(),
                ". RSACompliant starting on " + HOST + ":" + PORT + " .");
    }

    public RSACompliant() {}

    protected static class MessageOutputHandler {
        public java.net.Socket SOCKET;

        public MessageOutputHandler() {
            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". RSACompliant MessageOutputHandler " + LineFormatter.starts() + " .");
        }

        public void send_message(final String MESSAGE) {
            messaging.MessageOutputHandler h = new messaging.MessageOutputHandler(SOCKET, MESSAGE);
            h.run();
        }

        public void send_message(final StringBuffer BUFFER) {
            messaging.MessageOutputHandler h = new messaging.MessageOutputHandler(SOCKET, BUFFER);
            h.run();
        }
    }
}
