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
import java.net.InetAddress;
import java.net.Socket;
import java.util.Date;

public class Connection
{
    protected String hash = "0xDA717018470E213F";

    public BaseServer server;

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

    public Connection()
    {
        this.inception_date = new Date();
    }

    public Connection(BaseServer server)
    {
        if(server==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        this.server = server;
    }
}