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

    private static final File PRINT_METHOD_XML = commons.AppRoot.resolve("configuration/print-method.xml");

    /** Returns the canonical lifecycle verb from print-method.xml. */
    public static String starts() { return STARTS_CANONICAL; }

    // Acronyms/abbreviations that stay uppercase (loaded from print-method.xml preserved-acronyms)
    private static Set<String> PRESERVE_UPPER = Set.of(
        "JDBC", "SQL", "TCP", "UDP",
        "HTTP", "HTTPS", "SSH", "SSL", "TLS", "AES", "RSA", "DSA", "DSS", "IP",
        "USA", "EDT", "EST", "UTC", "XML", "JSON", "JAR", "SHA", "MD5", "ACK",
        "FATAL", "FAILED", "OK", "ID", "NWE", "JAVA"
    );

    // CamelCase + ™ module/service replacements (loaded from print-method.xml, longest first)
    private static String[][] MODULES;
    private static boolean APPEND_TRADEMARK = true;

    // Special spellings: words with exact casing that override normal sanitization
    private static String[][] SPECIAL_SPELLINGS = new String[0][];

    static {
        loadPreservedAcronyms();
        loadStartsConfig();
        loadModulesConfig();
        loadSpecialSpellings();
    }

    public static String normalize(String line) {
        if (line == null || line.isEmpty()) return line;

        String result = line;

        // 1. Convert UPPER_SNAKE_CASE to CamelCase
        result = convertSnakeCase(result);

        // 2. Convert remaining ALL_CAPS words to CamelCase (unless preserved)
        result = convertAllCaps(result);

        // 2b. Apply special spellings (exact casing from XML)
        for (String[] sp : SPECIAL_SPELLINGS) {
            result = Pattern.compile("(?i)\\b" + Pattern.quote(sp[0]) + "\\b").matcher(result).replaceAll(sp[1]);
        }

        // 3. Apply known module CamelCase™ replacement to FIRST occurrence only
        boolean tmApplied = false;
        for (String[] m : MODULES) {
            Matcher modMatcher = Pattern.compile("(?i)\\b" + Pattern.quote(m[0]) + "\\b(?!™)").matcher(result);
            if (modMatcher.find()) {
                if (!tmApplied) {
                    result = modMatcher.replaceFirst(m[1]);
                    tmApplied = true;
                } else {
                    // Subsequent matches get CamelCase but no ™
                    result = modMatcher.replaceAll(m[1].replace("™", ""));
                }
            }
        }
        // If ™ was already applied, strip any additional ™ beyond the first
        if (tmApplied) {
            int firstTm = result.indexOf("™");
            if (firstTm >= 0) {
                String before = result.substring(0, firstTm + 1);
                String after = result.substring(firstTm + 1).replace("™", "");
                result = before + after;
            }
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

    private static void loadPreservedAcronyms() {
        try {
            File file = PRINT_METHOD_XML;
            if (!file.exists()) return;
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            doc.getDocumentElement().normalize();
            NodeList nl = doc.getElementsByTagName("preserved-acronyms");
            if (nl.getLength() == 0) return;
            String raw = nl.item(0).getTextContent().trim();
            if (!raw.isEmpty()) {
                PRESERVE_UPPER = Set.of(raw.split(","));
            }
        } catch (Exception ignored) {}
    }

    private static void loadStartsConfig() {
        try {
            File file = PRINT_METHOD_XML;
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

    private static void loadModulesConfig() {
        try {
            File file = PRINT_METHOD_XML;
            if (!file.exists()) { MODULES = new String[0][]; return; }
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            doc.getDocumentElement().normalize();

            // Check append-trademark toggle
            NodeList at = doc.getElementsByTagName("append-trademark");
            if (at.getLength() > 0) {
                APPEND_TRADEMARK = Boolean.parseBoolean(at.item(0).getTextContent().trim());
            }

            if (!APPEND_TRADEMARK) { MODULES = new String[0][]; return; }

            // Load known-modules list
            NodeList km = doc.getElementsByTagName("known-modules");
            if (km.getLength() == 0) { MODULES = new String[0][]; return; }

            String raw = km.item(0).getTextContent().trim();
            String[] names = raw.split("[,\\s]+");
            java.util.List<String[]> list = new java.util.ArrayList<>();
            for (String name : names) {
                if (name.isEmpty()) continue;
                list.add(new String[]{name.toLowerCase(), name + "™"});
            }
            // Sort longest first to avoid partial matches
            list.sort((a, b) -> b[0].length() - a[0].length());
            MODULES = list.toArray(new String[0][]);
        } catch (Exception e) {
            MODULES = new String[0][];
        }
    }

    private static void loadSpecialSpellings() {
        try {
            File file = PRINT_METHOD_XML;
            if (!file.exists()) return;
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            doc.getDocumentElement().normalize();
            NodeList nl = doc.getElementsByTagName("special-spellings");
            if (nl.getLength() == 0) return;
            String raw = nl.item(0).getTextContent().trim();
            String[] words = raw.split("[,\\s]+");
            java.util.List<String[]> list = new java.util.ArrayList<>();
            for (String w : words) {
                if (!w.isEmpty()) list.add(new String[]{w, w});
            }
            list.sort((a, b) -> b[0].length() - a[0].length());
            SPECIAL_SPELLINGS = list.toArray(new String[0][]);
        } catch (Exception ignored) {}
    }
}
