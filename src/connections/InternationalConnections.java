package connections;

import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class InternationalConnections
{
    protected String hash = "0xDA717018470E213F";

    private final ArrayList<RecordedInternationalConnection> recorded_international_connections = new ArrayList<>(1000*1000);

    public InternationalConnections()
    {

    }

    public static class RecordedInternationalConnection
    {
        public Integer hash_code;

        public Date connection_date;

        public Date inception_date;

        public Socket socket;

        public String remote_address;

        public InetAddress inet_address;

        public InetAddress internet_address;

        public RecordedInternationalConnection()
        {
            this.hash_code = this.hashCode();

            this.inception_date = new Date();
        }
    }

    public synchronized void add(final Connection connection)
    {
        Connection x = connection;

        RecordedInternationalConnection record = new RecordedInternationalConnection();

        record.socket = x.socket;

        record.connection_date = x.inception_date;

        record.internet_address = x.internet_address;

        record.remote_address = x.remote_address;

        this.recorded_international_connections.add(record);
    }

    public synchronized void remove(final Socket socket)
    {
        for(int i=0; i<this.recorded_international_connections.size(); i++)
        {
            if(this.recorded_international_connections.get(i).socket==socket)
            {
                RecordedInternationalConnection connection = this.recorded_international_connections.get(i);

                this.recorded_international_connections.remove(connection);
            }
        }
    }

    public synchronized void remove(RecordedInternationalConnection connection)
    {
        this.recorded_international_connections.remove(connection);
    }

    public synchronized Integer size()
    {
        return this.recorded_international_connections.size();
    }
}
