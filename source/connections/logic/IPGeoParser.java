/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package connections.logic;

import commons.CommonRails;
import connections.Connection;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class IPGeoParser
{
    protected String hash = "0xDA717018470E213F";

    protected final String API_URL = "http://ip-api.com/json/";

    public static class GeoInfo
    {
        public String status;

        public String country;

        public String countryCode;

        public String regionName;

        public String city;

        public double lat;

        public double lon;

        public String isp;

        @Override
        public String toString()
        {
            return "GeoInfo{status="+status+", country="+country+", region="+regionName+", city="+city+", lat="+lat+", lon="+lon+", isp="+isp+"}";
        }
    }

    public IPGeoParser()
    {

    }

    public GeoInfo lookup(final String ip) throws IOException
    {
        if (ip == null || ip.isEmpty())
        {
            return null;
        }

        final String query = API_URL + ip;

        CommonRails.printSystemComponent(this, this.hashCode(), ". IPGeoParser::lookup >> querying " + query);

        HttpURLConnection conn = null;

        BufferedReader reader = null;

        try
        {
            conn = (HttpURLConnection) new URL(query).openConnection();

            conn.setConnectTimeout(5000);

            conn.setReadTimeout(5000);

            conn.setRequestMethod("GET");

            conn.setDoInput(true);

            int rc = conn.getResponseCode();

            if (rc != 200)
            {
                CommonRails.printSystemComponent(this, this.hashCode(), ". IPGeoParser::lookup >> non-200 response: " + rc);

                return null;
            }

            reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));

            StringBuilder sb = new StringBuilder();

            String line;

            while ((line = reader.readLine()) != null)
            {
                sb.append(line);
            }

            final String json = sb.toString();

            CommonRails.printSystemComponent(this, this.hashCode(), ". IPGeoParser::lookup >> json: " + (json.length()>200 ? json.substring(0,200)+"..." : json));

            return parseJson(json);
        }
        finally
        {
            try { if (reader != null) reader.close(); } catch (Exception ignored) { }

            if (conn != null) conn.disconnect();
        }
    }

    public GeoInfo parseJson(final String json)
    {
        if (json == null || json.isEmpty()) return null;

        GeoInfo info = new GeoInfo();

        info.status = extractString(json, "status");

        if (info.status == null || !"success".equalsIgnoreCase(info.status))
        {
            return info;
        }

        info.country = extractString(json, "country");

        info.countryCode = extractString(json, "countryCode");

        info.regionName = extractString(json, "regionName");

        info.city = extractString(json, "city");

        info.isp = extractString(json, "isp");

        info.lat = extractDouble(json, "lat");

        info.lon = extractDouble(json, "lon");

        return info;
    }

    protected String extractString(final String json, final String key)
    {
        final Pattern p = Pattern.compile("\"" + key + "\"\s*:\s*\"([^\"]*)\"");

        final Matcher m = p.matcher(json);

        if (m.find())
        {
            return m.group(1);
        }

        return null;
    }

    protected double extractDouble(final String json, final String key)
    {
        final Pattern p = Pattern.compile("\"" + key + "\"\s*:\s*([-0-9\\.]+)");

        final Matcher m = p.matcher(json);

        if (m.find())
        {
            try
            {
                return Double.parseDouble(m.group(1));
            }
            catch (Exception e)
            {
                return 0.0;
            }
        }

        return 0.0;
    }

    public GeoInfo parseConnection(final Connection connection)
    {
        if (connection == null) return null;

        String remote = connection.remote_address;

        if (remote == null) return null;

        // remote may be in form host:port
        String ip = remote;

        if (remote.contains(":"))
        {
            ip = remote.split(":" , 2)[0];
        }

        try
        {
            return lookup(ip);
        }
        catch (IOException e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(), ". IPGeoParser::parseConnection >> lookup failed: " + e.getMessage());

            return null;
        }
    }
}
