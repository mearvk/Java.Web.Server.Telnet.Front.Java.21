/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package server.base;

import commons.CommonRails;
import connections.*;
import connections.MexicoConnections;
import connections.NationalConnections;
import connections.GalacticConnections;
import connections.logic.IPGeoParser;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;

public abstract class BaseServer extends Thread
{
    public Integer hash = 0x008808FF;

    public BaseServer INHERITOR;
    public static final Integer BASE_CONNECTION_TIMEOUT = 43200 * 2 * 2 * 1000;

    public String HOST = "localhost";

    public InetAddress ADDRESS;

    public Integer PORT;

    public ServerSocket SERVER_SOCKET;

    public Boolean RUNNING = true;

    public CurrentConnections current_connections = new CurrentConnections();

    private final RecordedConnections recorded_connections = new RecordedConnections();

    private final InternationalConnections international_connections = new InternationalConnections();

    // regional registries
    private final MexicoConnections mexico_connections = new MexicoConnections();

    private final NationalConnections national_connections = new NationalConnections();

    private final GalacticConnections galactic_connections = new GalacticConnections();

    // IP geolocation parser
    private final IPGeoParser ipGeoParser = new IPGeoParser();

    // directory for connection XML data
    private final Path CONNECTION_DATA_DIR = Path.of("data", "connections");

    public BaseServer()
    {
        System.out.println(this.hash);
    }

    public BaseServer(final String host, Integer PORT)
    {
        if(host==null || PORT ==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        this.HOST = host;

        this.PORT = PORT;

        this.setName("BasicServer");

        try
        {
            this.ADDRESS = InetAddress.getByName(host);
        }
        catch(Exception e)
        {
            throw new IllegalStateException("Unable to resolve server host "+host, e);
        }

        try
        {
            this.SERVER_SOCKET = new ServerSocket(this.PORT, 4096, this.ADDRESS);

            CommonRails.printSystemComponent(this, this.hashCode(),". BaseServer::ServerSocket created on Port "+this.PORT +" .");
        }
        catch(Exception e)
        {
            throw new IllegalStateException("Unable to create server socket on "+host+":"+this.PORT, e);
        }
    }

    public BaseServer(Integer PORT)
    {
        if(PORT ==null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[2]);

        this.PORT = PORT;

        this.setName("BasicServer");

        try
        {
            this.ADDRESS = InetAddress.getByName(HOST);
        }
        catch(Exception e)
        {
            throw new IllegalStateException("Unable to resolve server host "+HOST, e);
        }

        try
        {
            this.SERVER_SOCKET = new ServerSocket(this.PORT, 4096, this.ADDRESS);

            CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress::BaseServer] [Server created on Port ["+this.PORT +"]]");
        }
        catch(Exception e)
        {
            throw new IllegalStateException("Unable to create server socket on "+HOST+":"+this.PORT, e);
        }
    }

    @Override
    public void run()
    {
        try
        {
            while(RUNNING)
            {
                Connection connection;

                connection = new Connection(this);

                connection.socket = this.SERVER_SOCKET.accept();

                connection.socket.setSoTimeout(BaseServer.BASE_CONNECTION_TIMEOUT);

                connection.remote_address = connection.socket.getRemoteSocketAddress().toString();

                connection.internet_address = connection.socket.getInetAddress();

                connection.server = this;

                CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress::BaseServer] [New remote connection established [remote-ephemeral: "+connection.remote_address+" : local: "+this.PORT +"]]");

                // Attempt to geolocate the new connection and route to regional registries
                IPGeoParser.GeoInfo geo = null;
                try
                {
                    geo = this.ipGeoParser.parseConnection(connection);
                }
                catch (Exception e)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "[BaseServer] IPGeoParser failed: " + e.getMessage());
                    geo = null;
                }

                String regionFile = "galactic.xml";

                if (geo != null && geo.countryCode != null)
                {
                    String cc = geo.countryCode.toUpperCase();

                    if ("MX".equals(cc))
                    {
                        this.mexico_connections.add(connection);

                        regionFile = "mexico.xml";
                    }
                    else if ("US".equals(cc))
                    {
                        this.national_connections.add(connection);

                        regionFile = "national.xml";
                    }
                    else
                    {
                        // keep international for other countries
                        regionFile = "international.xml";
                    }
                }
                else
                {
                    this.galactic_connections.add(connection);
                }

                try
                {
                    if (!Files.exists(CONNECTION_DATA_DIR)) Files.createDirectories(CONNECTION_DATA_DIR);

                    Path out = CONNECTION_DATA_DIR.resolve(regionFile);

                    StringBuilder xml = new StringBuilder();

                    xml.append("<connection>\n");

                    xml.append("  <remoteAddress>").append(escapeXml(connection.remote_address)).append("</remoteAddress>\n");

                    xml.append("  <inetAddress>").append(escapeXml(String.valueOf(connection.internet_address))).append("</inetAddress>\n");

                    if (geo != null)
                    {
                        xml.append("  <country>").append(escapeXml(geo.country)).append("</country>\n");
                        xml.append("  <countryCode>").append(escapeXml(geo.countryCode)).append("</countryCode>\n");
                        xml.append("  <region>").append(escapeXml(geo.regionName)).append("</region>\n");
                        xml.append("  <city>").append(escapeXml(geo.city)).append("</city>\n");
                        xml.append("  <isp>").append(escapeXml(geo.isp)).append("</isp>\n");
                        xml.append("  <lat>").append(geo.lat).append("</lat>\n");
                        xml.append("  <lon>").append(geo.lon).append("</lon>\n");
                    }

                    xml.append("  <timestamp>").append(System.currentTimeMillis()).append("</timestamp>\n");

                    xml.append("</connection>\n");

                    Files.writeString(out, xml.toString(), StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
                }
                catch (Exception e)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "[BaseServer] Failed to write connection xml: " + e.getMessage());
                }

                try
                {
                    connection.inputstream = connection.socket.getInputStream();

                    connection.reader = new BufferedReader(new InputStreamReader(connection.inputstream));
                }
                catch(Exception e)
                {
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),"[WebExpress::BaseServer] [Related input reader established ["+this.ADDRESS +":"+this.PORT +"]]");
                }

                try
                {
                    connection.outputstream = connection.socket.getOutputStream();

                    connection.writer = new BufferedWriter(new OutputStreamWriter(connection.outputstream));
                }
                catch(Exception e)
                {
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress::BaseServer] [Related output writer established ["+this.ADDRESS +":"+this.PORT +"]]");
                }

                try
                {
                    connection.thread = new ConnectionPoller(null,this, this.HOST, this.PORT);

                    connection.thread.start();
                }
                catch(Exception e)
                {
                    e.printStackTrace(System.err);

                    return;
                }
                finally
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), "[WebExpress::BaseServer] [Related I/O listener thread established ["+this.ADDRESS +":"+this.PORT +"]]");
                }

                this.current_connections.add(connection);

                this.recorded_connections.add(connection);

                this.international_connections.add(connection);
            }
        }
        catch(Exception se)
        {
            se.printStackTrace(System.err);
        }
    }

    private static String escapeXml(final String s)
    {
        if (s == null) return "";

        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }
}

