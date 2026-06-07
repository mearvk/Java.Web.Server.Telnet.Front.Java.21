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

public class MexicoConnections
{
    protected String hash = "0xDA717018470E213F";

    private final ArrayList<RecordedMexicoConnection> recorded_mexico_connections = new ArrayList<>(1000*1000);

    public MexicoConnections()
    {

    }

    public static class RecordedMexicoConnection
    {
        public Integer hash_code;

        public Date connection_date;

        public Date inception_date;

        public Socket socket;

        public String remote_address;

        public InetAddress inet_address;

        public String mexican_state;

        public RecordedMexicoConnection()
        {
            this.hash_code = this.hashCode();

            this.inception_date = new Date();
        }
    }

    public synchronized void add(final Connection connection)
    {
        Connection x = connection;

        RecordedMexicoConnection record = new RecordedMexicoConnection();

        record.socket = x.socket;

        record.connection_date = x.inception_date;

        record.inet_address = x.internet_address;

        record.remote_address = x.remote_address;

        // Attempt to derive Mexican state from remote_address if possible (placeholder)
        try
        {
            record.mexican_state = x.remote_address;
        }
        catch (Exception ignored)
        {
        }

        this.recorded_mexico_connections.add(record);
    }

    public synchronized void remove(final Socket socket)
    {
        for(int i=0; i<this.recorded_mexico_connections.size(); i++)
        {
            if(this.recorded_mexico_connections.get(i).socket==socket)
            {
                RecordedMexicoConnection connection = this.recorded_mexico_connections.get(i);

                this.recorded_mexico_connections.remove(connection);
            }
        }
    }

    public synchronized void remove(final RecordedMexicoConnection connection)
    {
        this.recorded_mexico_connections.remove(connection);
    }

    public synchronized Integer size()
    {
        return this.recorded_mexico_connections.size();
    }
}
