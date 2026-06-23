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

public class GalacticConnections
{
    protected String hash = "0xDA717018470E213F";

    private final ArrayList<RecordedGalacticConnection> recorded_international_connections = new ArrayList<>(1000*1000);

    public GalacticConnections()
    {

    }

    public static class RecordedGalacticConnection
    {
        public Integer hash_code;

        public Date connection_date;

        public Date inception_date;

        public Socket SOCKET;

        public String remote_address;

        public InetAddress inet_address;

        public InetAddress internet_address;

        public RecordedGalacticConnection()
        {
            this.hash_code = this.hashCode();

            this.inception_date = new Date();
        }
    }

    public synchronized void add(final Connection CONNECTION)
    {
        Connection x = CONNECTION;

        RecordedGalacticConnection record = new RecordedGalacticConnection();

        record.SOCKET = x.SOCKET;

        record.connection_date = x.inception_date;

        record.internet_address = x.internet_address;

        record.remote_address = x.remote_address;

        this.recorded_international_connections.add(record);
    }

    public synchronized void remove(final Socket SOCKET)
    {
        for(int i=0; i<this.recorded_international_connections.size(); i++)
        {
            if(this.recorded_international_connections.get(i).SOCKET==SOCKET)
            {
                RecordedGalacticConnection connection = this.recorded_international_connections.get(i);

                this.recorded_international_connections.remove(connection);
            }
        }
    }

    public synchronized void remove(final RecordedGalacticConnection CONNECTION)
    {
        this.recorded_international_connections.remove(CONNECTION);
    }

    public synchronized Integer size()
    {
        return this.recorded_international_connections.size();
    }
}
