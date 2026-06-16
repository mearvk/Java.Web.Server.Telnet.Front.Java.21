/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package connections;

import server.base.BaseServer;
import server.hardened.experimental.m.NationalAwareHardService;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.Socket;
import java.util.Date;

public class Connection implements AutoCloseable
{
    protected String hash = "0xDA717018470E213F";

    public BaseServer SERVER;

    public NationalAwareHardService NAHS;

    public volatile Socket SOCKET;

    public InputStream inputstream;

    public OutputStream outputstream;

    public String remote_address = null;

    public BufferedReader reader = null;

    public BufferedWriter writer = null;

    public ConnectionPoller thread;

    public Date inception_date;

    public InetAddress internet_address;

    public Boolean IS_TELNET_EXCELSIOR_CONNECTED = Boolean.FALSE;

    public long nationalId = -1;

    public telnet.TelnetLineEditor lineEditor;

    public Connection()
    {
        this.inception_date = new Date();
    }

    public Connection(final BaseServer SERVER)
    {
        if(SERVER==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        this.SERVER = SERVER;
    }

    public Connection(final NationalAwareHardService NAHS)
    {
        if(NAHS==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        this.NAHS = NAHS;
        this.inception_date = new Date();
    }

    @Override
    public void close()
    {
        for(Connection connection : this.SERVER.CURRENT_CONNECTIONS.CURRENT_CONNECTION)
        {
            connection.close();
        }
    }

}