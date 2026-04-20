package connections;

import server.BaseServer;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;

public class Connection
{
    public BaseServer server;

    public volatile Socket socket;

    public InputStream inputstream;

    public OutputStream outputstream;

    public String remote_address = null;

    public BufferedReader reader = null;

    public BufferedWriter writer = null;

    public ConnectionPoller thread;

    public Connection()
    {

    }

    public Connection(BaseServer server)
    {
        if(server==null) throw new SecurityException("//bodi/connect");

        this.server = server;
    }
}