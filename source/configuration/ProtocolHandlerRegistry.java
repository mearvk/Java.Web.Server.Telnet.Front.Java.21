package configuration;

import commons.CommonRails;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.net.ssl.SSLSocketFactory;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.util.HashMap;
import java.util.Map;

/**
 * ProtocolHandlerRegistry — loads protocol-handlers.xml, verifies remote
 * servers run the expected protocol, and wraps user messages in the
 * correct protocol framing.
 */
public final class ProtocolHandlerRegistry
{
    private static final String CONFIG_FILE = commons.AppRoot.resolveString("configuration/protocol-handlers.xml");
    private static Map<Integer, ProtocolHandler> HANDLERS;

    public static class ProtocolHandler
    {
        public final int port;
        public final String protocol;
        public final boolean tls;
        public final String probe;
        public final String expect;
        public final String template;

        ProtocolHandler(int port, String protocol, boolean tls, String probe, String expect, String template)
        {
            this.port = port;
            this.protocol = protocol;
            this.tls = tls;
            this.probe = probe;
            this.expect = expect;
            this.template = template;
        }
    }

    private ProtocolHandlerRegistry() {}

    public static ProtocolHandler get(int port)
    {
        if (HANDLERS == null) load();
        return HANDLERS.get(port);
    }

    /**
     * Verify that the remote host:port is running the expected protocol.
     * Connects, sends the probe, checks response starts with expect string.
     */
    public static boolean verify(String host, int port)
    {
        ProtocolHandler h = get(port);
        if (h == null) return true; // unknown port, no verification possible

        try
        {
            Socket sock = h.tls
                ? SSLSocketFactory.getDefault().createSocket(host, port)
                : new Socket(host, port);
            sock.setSoTimeout(3000);

            OutputStream out = sock.getOutputStream();
            InputStream in = sock.getInputStream();

            // Send probe if defined
            if (h.probe != null && !h.probe.isEmpty())
            {
                out.write(unescape(h.probe).getBytes());
                out.flush();
            }

            // Read response
            Thread.sleep(500);
            byte[] buf = new byte[512];
            int n = in.read(buf);
            sock.close();

            if (n <= 0) return false;
            String response = new String(buf, 0, n);
            return response.contains(h.expect);
        }
        catch (Exception e) { return false; }
    }

    /**
     * Wrap a user message using the protocol template for the given port.
     * Replaces {host}, {path}, {message}, {user}, {pass}, {command}, {from}, {to}
     * with provided params.
     */
    public static String wrapMessage(int port, String message, Map<String, String> params)
    {
        ProtocolHandler h = get(port);
        if (h == null || h.template.isEmpty()) return message;

        String result = h.template;
        if (params != null)
            for (Map.Entry<String, String> e : params.entrySet())
                result = result.replace("{" + e.getKey() + "}", e.getValue());
        result = result.replace("{message}", message);
        return unescape(result);
    }

    /**
     * Register a new well-known port handler discovered at runtime.
     * Persists to protocol-handlers.xml.
     */
    public static synchronized void registerDiscovered(int port, String protocol, String expectString)
    {
        if (HANDLERS == null) load();
        if (HANDLERS.containsKey(port)) return;

        ProtocolHandler h = new ProtocolHandler(port, protocol, false, "", expectString, "{message}\r\n");
        HANDLERS.put(port, h);

        // Persist to XML
        try
        {
            File file = new File(CONFIG_FILE);
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            Element root = doc.getDocumentElement();

            Element entry = doc.createElement("handler");
            entry.setAttribute("port", String.valueOf(port));
            entry.setAttribute("protocol", protocol);
            entry.setAttribute("tls", "false");

            Element probeEl = doc.createElement("probe");
            probeEl.setTextContent("");
            entry.appendChild(probeEl);

            Element expectEl = doc.createElement("expect");
            expectEl.setTextContent(expectString);
            entry.appendChild(expectEl);

            Element tmplEl = doc.createElement("template");
            tmplEl.setTextContent("{message}\\r\\n");
            entry.appendChild(tmplEl);

            root.appendChild(entry);

            Transformer tf = TransformerFactory.newInstance().newTransformer();
            tf.setOutputProperty(OutputKeys.INDENT, "yes");
            tf.transform(new DOMSource(doc), new StreamResult(file));

            CommonRails.printSystemComponent(ProtocolHandlerRegistry.class,
                ProtocolHandlerRegistry.class.hashCode(),
                ". ProtocolHandlerRegistry >> discovered and registered port " + port + " (" + protocol + ") .");
        }
        catch (Exception e) { /* best effort */ }
    }

    private static synchronized void load()
    {
        HANDLERS = new HashMap<>();
        try
        {
            File file = new File(CONFIG_FILE);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            doc.getDocumentElement().normalize();
            NodeList nodes = doc.getElementsByTagName("handler");
            for (int i = 0; i < nodes.getLength(); i++)
            {
                Element el = (Element) nodes.item(i);
                int port = Integer.parseInt(el.getAttribute("port"));
                String protocol = el.getAttribute("protocol");
                boolean tls = "true".equals(el.getAttribute("tls"));
                String probe = text(el, "probe");
                String expect = text(el, "expect");
                String template = text(el, "template");
                HANDLERS.put(port, new ProtocolHandler(port, protocol, tls, probe, expect, template));
            }
        }
        catch (Exception ignored) {}
    }

    private static String text(Element el, String tag)
    {
        NodeList nl = el.getElementsByTagName(tag);
        return nl.getLength() > 0 ? nl.item(0).getTextContent().trim() : "";
    }

    private static String unescape(String s)
    {
        return s.replace("\\r", "\r").replace("\\n", "\n");
    }
}
