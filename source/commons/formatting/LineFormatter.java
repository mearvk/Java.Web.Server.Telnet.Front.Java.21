package commons.formatting;

import commons.color.ColorPalette;

import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import java.io.File;

/**
 * Normalizes and colorizes log lines.
 * Enforces CamelCase™ naming. Strips UPPER_SNAKE_CASE and ALL_CAPS keywords.
 */
public final class LineFormatter {

    private LineFormatter() {}

    private static final Pattern SNAKE_CASE = Pattern.compile("\\b([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+)\\b");
    private static final Pattern ALL_CAPS_WORD = Pattern.compile("\\b([A-Z]{2,})\\b");

    private static String STARTS_CANONICAL = "starts";
    private static String[] STARTS_ALTERNATIVES = {"starting", "started", "is starting", "now starting"};

    static { loadStartsConfig(); }

    /** Returns the canonical lifecycle verb from print-method.xml. */
    public static String starts() { return STARTS_CANONICAL; }

    // Acronyms/abbreviations that stay uppercase
    private static final Set<String> PRESERVE_UPPER = Set.of(
        "MYSQL", "JDBC", "SYSTEMCTL", "NWECONFIG", "CONFIG", "SQL", "TCP", "UDP",
        "HTTP", "HTTPS", "SSH", "SSL", "TLS", "AES", "RSA", "DSA", "DSS", "IP",
        "USA", "EDT", "EST", "UTC", "XML", "JSON", "JAR", "SHA", "MD5", "ACK",
        "FATAL", "FAILED", "OK", "ID", "NWE", "JAVA"
    );

    // CamelCase + ™ module/service replacements (longest match first)
    private static final String[][] MODULES = {
        {"telnetproxylivenessmonitor", "TelnetProxyLivenessMonitor™"},
        {"telnetcommunicationproxy", "TelnetCommunicationProxy™"},
        {"messageoutputhandler", "MessageOutputHandler™"},
        {"messagequeuesorter", "MessageQueueSorter™"},
        {"messagequeuehandler", "MessageQueueHandler™"},
        {"telnetoutputbuilder", "TelnetOutputBuilder™"},
        {"telnetinputbuilder", "TelnetInputBuilder™"},
        {"telnetmessagequeue", "TelnetMessageQueue™"},
        {"telnetlineeditor", "TelnetLineEditor™"},
        {"telnetinstaller", "TelnetInstaller™"},
        {"nitrowebexpress", "NitroWebExpress™"},
        {"connectionstatus", "ConnectionStatus™"},
        {"moduleinstallation", "ModuleInstallation™"},
        {"moduleloaderdaemon", "ModuleLoaderDaemon™"},
        {"heuristicclassifier", "HeuristicClassifier™"},
        {"bitcoinwalletindexer", "BitcoinWalletIndexer™"},
        {"bitcoincompliant", "BitcoinCompliant™"},
        {"asciicreator", "AsciiCreator™"},
        {"aescompliant", "AesCompliant™"},
        {"rsacompliant", "RsaCompliant™"},
        {"dsacompliant", "DsaCompliant™"},
        {"binaryhttp", "BinaryHttp™"},
        {"webexpress", "WebExpress™"},
        {"serversocket", "ServerSocket™"},
        {"communicator", "Communicator™"},
        {"antivirus", "Antivirus™"},
        {"weather", "Weather™"},
    };

    public static String normalize(String line) {
        if (line == null || line.isEmpty()) return line;

        String result = line;

        // 1. Convert UPPER_SNAKE_CASE to CamelCase
        result = convertSnakeCase(result);

        // 2. Convert remaining ALL_CAPS words to CamelCase (unless preserved)
        result = convertAllCaps(result);

        // 3. Apply known module CamelCase™ replacements
        for (String[] m : MODULES) {
            result = result.replaceAll("(?i)\\b" + Pattern.quote(m[0]) + "\\b", m[1]);
        }

        // 4. Normalize lifecycle verbs to canonical form (longest match first; skip if alt is substring of canonical)
        java.util.Arrays.sort(STARTS_ALTERNATIVES, (a, b) -> b.length() - a.length());
        for (String alt : STARTS_ALTERNATIVES) {
            if (STARTS_CANONICAL.toLowerCase().contains(alt.toLowerCase())) continue;
            result = result.replaceAll("(?i)\\b" + Pattern.quote(alt) + "\\b", STARTS_CANONICAL);
        }

        // 5. Color trademark symbol in red
        result = result.replace("™", ColorPalette.COLOR_STANDARD_RED + "™" + ColorPalette.OID_DEFAULT);

        return result;
    }

    /**
     * Converts UPPER_SNAKE_CASE tokens to CamelCase.
     * e.g. MODULE_LOADER_DAEMON → ModuleLoaderDaemon
     */
    private static String convertSnakeCase(String input) {
        Matcher m = SNAKE_CASE.matcher(input);
        StringBuilder sb = new StringBuilder();
        while (m.find()) {
            String token = m.group(1);
            m.appendReplacement(sb, toCamelCase(token));
        }
        m.appendTail(sb);
        return sb.toString();
    }

    /**
     * Converts remaining ALL_CAPS words (2+ chars) to InitialCap unless preserved.
     * e.g. TELNET → Telnet, PROXY → Proxy
     */
    private static String convertAllCaps(String input) {
        Matcher m = ALL_CAPS_WORD.matcher(input);
        StringBuilder sb = new StringBuilder();
        while (m.find()) {
            String word = m.group(1);
            if (PRESERVE_UPPER.contains(word)) {
                m.appendReplacement(sb, word);
            } else {
                m.appendReplacement(sb, word.charAt(0) + word.substring(1).toLowerCase());
            }
        }
        m.appendTail(sb);
        return sb.toString();
    }

    private static String toCamelCase(String snake) {
        String[] parts = snake.split("_");
        StringBuilder sb = new StringBuilder();
        for (String part : parts) {
            if (!part.isEmpty()) {
                sb.append(part.charAt(0)).append(part.substring(1).toLowerCase());
            }
        }
        return sb.toString();
    }

    private static void loadStartsConfig() {
        try {
            File file = new File("configuration/print-method.xml");
            if (!file.exists()) return;
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            doc.getDocumentElement().normalize();
            NodeList nl = doc.getElementsByTagName("starts");
            if (nl.getLength() == 0) return;
            Element el = (Element) nl.item(0);
            NodeList cn = el.getElementsByTagName("canonical");
            if (cn.getLength() > 0) {
                String v = cn.item(0).getTextContent().trim();
                if (!v.isEmpty()) STARTS_CANONICAL = v;
            }
            NodeList an = el.getElementsByTagName("alternatives");
            if (an.getLength() > 0) {
                String v = an.item(0).getTextContent().trim();
                if (!v.isEmpty()) STARTS_ALTERNATIVES = v.split(",");
            }
        } catch (Exception ignored) {}
    }
}
