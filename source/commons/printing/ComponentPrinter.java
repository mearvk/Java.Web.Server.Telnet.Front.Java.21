package commons.printing;

import commons.color.ColorResolver;
import commons.color.ColorPalette;
import commons.formatting.LineFormatter;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

public final class ComponentPrinter {

    private static final String CONFIG_FILE = "configuration/print-method.xml";

    // Defaults (overridden from XML if present)
    private static String PREFIX = "-- : ";
    private static String OID_LABEL = "Object ID";
    private static String OID_FORMAT = "%010d";
    private static String DATE_LABEL = "Date";
    private static String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss z";
    private static String DATE_TIMEZONE = "America/New_York";
    private static String CURRENT_LABEL = "Current";
    private static String CURRENT_PREFIX = "@";
    private static int PAD_WIDTH = 39;
    private static String DECORATOR_START = ".";
    private static String DECORATOR_END = ".";
    private static int FADE_STEPS = 20;
    private static int FADE_DELAY_MS = 20;
    private static int POST_FADE_DELAY_MS = 200;
    private static boolean COLORED_OUTPUT = true;
    private static boolean RESET_AFTER_LINE = true;
    private static boolean PARENT_CLASS_PREFIX = false;
    private static boolean PARENT_CLASS_TRADEMARK = false;
    private static String PARENT_CLASS_SEPARATOR = " ";

    static { loadConfig(); }

    private ComponentPrinter() {}

    public static void print(Object owner, int hash, String line) {
        print(owner, hash, line, null);
    }

    public static void print(Object owner, int hash, String line, String color) {
        String simple = owner instanceof Class<?> c ? c.getSimpleName() : owner.getClass().getSimpleName();

        // Block 1: Prefix
        String prefix = PREFIX;

        // Block 2: Object ID
        int resolvedHash = configuration.HashCodeRegistry.resolve(owner);
        String hashStr = String.format(OID_FORMAT, resolvedHash);
        String oidColor = (color != null) ? color : ColorResolver.resolveCategoryColor(simple);
        String objectId = "[" + OID_LABEL + ": " + oidColor + hashStr + ColorPalette.OID_DEFAULT + "]";

        // Block 3: Date
        String date = "[" + DATE_LABEL + ": " + timestamp() + "]";

        // Block 4: Current
        String padded = padClassname(simple);

        // Block 5: Message
        String formatted = LineFormatter.normalize(line);
        // Apply configurable decorators (replace leading/trailing '.' with configured chars)
        formatted = formatted.replaceFirst("^\\.", DECORATOR_START);
        formatted = formatted.replaceFirst("\\.$", DECORATOR_END);
        if (PARENT_CLASS_PREFIX) {
            String parentName = PARENT_CLASS_TRADEMARK ? simple + "™" : simple;
            formatted = DECORATOR_START + " " + parentName + PARENT_CLASS_SEPARATOR + formatted.replaceFirst("^\\Q" + DECORATOR_START + "\\E ?", "");
        }

        // Assemble
        String ref = ColorPalette.OID_DEFAULT + prefix + objectId + " " + date + " " + padded + " " + formatted + ColorPalette.OID_DEFAULT;

        FinePrinter.fadePrint(ref, FADE_STEPS, FADE_DELAY_MS, POST_FADE_DELAY_MS, COLORED_OUTPUT);
    }

    private static String timestamp() {
        SimpleDateFormat fmt = new SimpleDateFormat(DATE_FORMAT);
        fmt.setTimeZone(TimeZone.getTimeZone(DATE_TIMEZONE));
        return fmt.format(new Date());
    }

    private static String padClassname(String name) {
        String inner = CURRENT_LABEL + ": " + CURRENT_PREFIX + name;
        int pad = Math.max(0, PAD_WIDTH - inner.length());
        return "[" + inner + " ".repeat(pad) + "]";
    }

    private static void loadConfig() {
        try {
            File file = new File(CONFIG_FILE);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            doc.getDocumentElement().normalize();

            NodeList blocks = doc.getElementsByTagName("block");
            for (int i = 0; i < blocks.getLength(); i++) {
                Element el = (Element) blocks.item(i);
                String name = el.getAttribute("name");
                switch (name) {
                    case "Prefix" -> PREFIX = text(el, "value", PREFIX);
                    case "ObjectId" -> {
                        OID_LABEL = text(el, "label", OID_LABEL);
                        OID_FORMAT = text(el, "format", OID_FORMAT);
                    }
                    case "Date" -> {
                        DATE_LABEL = text(el, "label", DATE_LABEL);
                        DATE_FORMAT = text(el, "format", DATE_FORMAT);
                        DATE_TIMEZONE = text(el, "timezone", DATE_TIMEZONE);
                    }
                    case "Current" -> {
                        CURRENT_LABEL = text(el, "label", CURRENT_LABEL);
                        CURRENT_PREFIX = text(el, "prefix", CURRENT_PREFIX);
                        PAD_WIDTH = Integer.parseInt(text(el, "pad-width", String.valueOf(PAD_WIDTH)));
                    }
                    case "Message" -> {
                        DECORATOR_START = text(el, "decorator-start", DECORATOR_START);
                        DECORATOR_END = text(el, "decorator-end", DECORATOR_END);
                    }
                }
            }

            NodeList grace = doc.getElementsByTagName("grace");
            if (grace.getLength() > 0) {
                Element g = (Element) grace.item(0);
                FADE_STEPS = Integer.parseInt(text(g, "fade-steps", String.valueOf(FADE_STEPS)));
                FADE_DELAY_MS = Integer.parseInt(text(g, "fade-delay-ms", String.valueOf(FADE_DELAY_MS)));
                POST_FADE_DELAY_MS = Integer.parseInt(text(g, "post-fade-delay-ms", String.valueOf(POST_FADE_DELAY_MS)));
            }

            NodeList control = doc.getElementsByTagName("control");
            if (control.getLength() > 0) {
                Element c = (Element) control.item(0);
                COLORED_OUTPUT = Boolean.parseBoolean(text(c, "colored-output", "true"));
                RESET_AFTER_LINE = Boolean.parseBoolean(text(c, "reset-after-line", "true"));
            }

            NodeList pcp = doc.getElementsByTagName("parent-class-prefix");
            if (pcp.getLength() > 0) {
                Element p = (Element) pcp.item(0);
                PARENT_CLASS_PREFIX = Boolean.parseBoolean(text(p, "enabled", "false"));
                PARENT_CLASS_TRADEMARK = Boolean.parseBoolean(text(p, "append-trademark", "false"));
                PARENT_CLASS_SEPARATOR = text(p, "separator", " ");
            }
        } catch (Exception ignored) {}
    }

    private static String text(Element el, String tag, String def) {
        NodeList nl = el.getElementsByTagName(tag);
        if (nl.getLength() == 0) return def;
        String v = nl.item(0).getTextContent().trim();
        return v.isEmpty() ? def : v;
    }
}
