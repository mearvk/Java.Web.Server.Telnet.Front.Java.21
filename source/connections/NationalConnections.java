/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package connections;

import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;

public class NationalConnections
{
    protected String hash = "0xDA717018470E213F";

    private final ArrayList<RecordedNationalConnection> recorded_national_connections = new ArrayList<>(1000*1000);

    public NationalConnections()
    {

    }

    public static class RecordedNationalConnection
    {
        public Integer hash_code;

        public Date connection_date;

        public Date inception_date;

        public Socket socket;

        public String remote_address;

        public InetAddress inet_address;

        public String national_identifier;

        public RecordedNationalConnection()
        {
            this.hash_code = this.hashCode();

            this.inception_date = new Date();
        }
    }

    public synchronized void add(final Connection connection)
    {
        Connection x = connection;

        RecordedNationalConnection record = new RecordedNationalConnection();

        record.socket = x.socket;

        record.connection_date = x.inception_date;

        record.inet_address = x.internet_address;

        record.remote_address = x.remote_address;

        // Attempt to capture a national identifier if available on connection
        try
        {
            // placeholder: map remote_address to a national identifier if applicable
            record.national_identifier = x.remote_address;
        }
        catch (Exception ignored)
        {
        }

        this.recorded_national_connections.add(record);
    }

    public synchronized void remove(final Socket socket)
    {
        for(int i=0; i<this.recorded_national_connections.size(); i++)
        {
            if(this.recorded_national_connections.get(i).socket==socket)
            {
                RecordedNationalConnection connection = this.recorded_national_connections.get(i);

                this.recorded_national_connections.remove(connection);
            }
        }
    }

    public synchronized void remove(final RecordedNationalConnection connection)
    {
        this.recorded_national_connections.remove(connection);
    }

    public synchronized Integer size()
    {
        return this.recorded_national_connections.size();
    }
}
