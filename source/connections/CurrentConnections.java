/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package connections;

import server.base.BaseServer;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.util.ArrayList;

public class CurrentConnections
{
    protected String hash = "0xDA717018470E213F";

    public BaseServer server;

    public volatile Socket socket;

    public InputStream inputstream;

    public OutputStream outputstream;

    public String remote_address = null;

    public BufferedReader reader = null;

    public BufferedWriter writer = null;

    public ConnectionPoller thread;

    public ArrayList<Connection> CURRENT_CONNECTION = new ArrayList<Connection>();

    public void add(Connection connection)
    {
        this.CURRENT_CONNECTION.add(connection);
    }

    public void remove(Socket socket)
    {
        for(int i = 0; i<this.CURRENT_CONNECTION.size(); i++)
        {
            Socket _socket = this.CURRENT_CONNECTION.get(i).SOCKET;

            if(_socket==socket)
            {
                Connection connection = this.CURRENT_CONNECTION.get(i);

                this.CURRENT_CONNECTION.remove(connection);
            }
        }
    }

    public void remove(Connection connection)
    {
        this.CURRENT_CONNECTION.remove(connection);
    }

    public Integer size()
    {
        return this.CURRENT_CONNECTION.size();
    }
}
