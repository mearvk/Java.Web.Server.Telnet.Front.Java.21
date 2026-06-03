package bitcoin.messaging;

import bitcoin.base.BitcoinBase;
import bitcoin.module.TraderModule;

import commons.CommonRails;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class MessageOrderer extends Thread
{
    protected String hash = "0xDA717018470E213F";

    public ArrayList<BitcoinMessage> bitcoin_messages = new ArrayList<BitcoinMessage>(5000);

    public TraderModule bitcoin;

    public BitcoinBase base;

    public MessageOrderer(TraderModule bitcoin)
    {
        this.bitcoin = bitcoin;
    }

    public MessageOrderer(BitcoinBase base)
    {
        this.base = base;
    }

    @Override
    public void run()
    {
        while(true)
        {
            BitcoinMessage msg = null;

            synchronized (this.bitcoin_messages)
            {
                while (this.bitcoin_messages.isEmpty())
                {
                    try
                    {
                        this.bitcoin_messages.wait();
                    }
                    catch (InterruptedException ie)
                    {
                        Thread.currentThread().interrupt();

                        return;
                    }
                }

                msg = this.bitcoin_messages.remove(0);
            }

            try
            {
                processMessage(msg);
            }
            catch (Exception e)
            {
                CommonRails.printSystemComponent(this, this.hashCode(), ". MessageOrderer::run >> exception processing message: " + e.getMessage());
            }
        }
    }

    public synchronized void add(BitcoinMessage bitcoin_message)
    {
        if (bitcoin_message == null)
        {
            return;
        }

        synchronized (this.bitcoin_messages)
        {
            this.bitcoin_messages.add(bitcoin_message);

            this.bitcoin_messages.notifyAll();
        }
    }

    public synchronized void remove(BitcoinMessage bitcoin_message)
    {
        synchronized (this.bitcoin_messages)
        {
            this.bitcoin_messages.remove(bitcoin_message);
        }
    }

    public synchronized void clear(BitcoinMessage bitcoin_message)
    {
        synchronized (this.bitcoin_messages)
        {
            this.bitcoin_messages.clear();
        }
    }

    public synchronized int size()
    {
        synchronized (this.bitcoin_messages)
        {
            return this.bitcoin_messages.size();
        }
    }

    protected void processMessage(BitcoinMessage msg)
    {
        if (msg == null)
        {
            return;
        }

        CommonRails.printSystemComponent(this, this.hashCode(), ". MessageOrderer::processMessage >> processing message from " + msg.inet_address + " socket=" + msg.socket);

        try
        {
            if (msg.socket != null && CommonRails.SocketUtils.isSocketConnected(msg.socket))
            {
                BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(msg.socket.getOutputStream()));

                String out = msg.message_buffer == null ? "" : msg.message_buffer.toString();

                writer.write(out);

                writer.flush();
            }
            else
            {
                CommonRails.printSystemComponent(this, this.hashCode(), ". MessageOrderer::processMessage >> socket not available, storing/logging message.");
            }
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". MessageOrderer::processMessage >> error sending message: " + e.getMessage());

            try
            {
                if (msg.socket != null)
                {
                    msg.socket.close();
                }
            }
            catch (Exception ignored)
            {
            }
        }
    }

    public static class BitcoinMessage
    {
        protected Date date;

        protected Socket socket;

        protected InetAddress inet_address;

        protected StringBuffer message_buffer = new StringBuffer();

        public BitcoinMessage()
        {

        }
    }
}
