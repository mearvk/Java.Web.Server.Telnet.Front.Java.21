package modules.Defined.source.protocol;

/**
 * HTTPAltHandler — Protocol handler for HTTP Alternate / Tomcat (port 8080).
 * Manages Tomcat webapp frontend at context /defined.
 * Supports Form-based authentication for admins and capitalists.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class HTTPAltHandler extends ProtocolHandler
{
    private String tomcatContext = "/defined";

    public HTTPAltHandler()
    {
        super(8080, "HTTP-ALT", "HTTP Alternate — Tomcat webapp frontend");
    }

    public String getTomcatContext()
    {
        return tomcatContext;
    }

    public void setTomcatContext(String context)
    {
        this.tomcatContext = context;
    }

    @Override
    public void start()
    {
        active = true;
        logConnection("HTTP-ALT handler started (Tomcat context: " + tomcatContext + ")");
    }

    @Override
    public void stop()
    {
        active = false;
        logConnection("HTTP-ALT handler stopped");
    }
}
