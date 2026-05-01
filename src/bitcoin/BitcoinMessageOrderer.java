package bitcoin;

import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class BitcoinMessageOrderer extends Thread
{
    protected String hash = "0xDA717018470E213F";

    public ArrayList<BitcoinMessage> bitcoin_messages = new ArrayList<BitcoinMessage>(5000);

    public BitcoinBase bitcoin;

    public BitcoinMessageOrderer(BitcoinBase bitcoin)
    {
        this.bitcoin = bitcoin;
    }

    @Override
    public void run()
    {
        while(true)
        {

        }
    }

    public synchronized void add(BitcoinMessage bitcoin_message)
    {
        this.bitcoin_messages.add(bitcoin_message);
    }

    public synchronized void remove(BitcoinMessage bitcoin_message)
    {
        this.bitcoin_messages.remove(bitcoin_message);
    }

    public synchronized void clear(BitcoinMessage bitcoin_message)
    {
        this.bitcoin_messages.clear();
    }

    public static class BitcoinMessage
    {
        protected Date date;

        protected Socket socket;

        protected InetAddress inet_address;

        protected StringBuffer message_buffer;

        public BitcoinMessage()
        {

        }
    }
}
