package commons.color;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;
import java.util.HashMap;
import java.util.Map;

public final class ColorResolver {

    private static final String PROGRAMS_XML = "configuration/programs.xml";
    private static final Map<String, String> PROGRAM_COLORS = new HashMap<>();

    static { loadPrograms(); }

    private ColorResolver() {}

    public static String resolveCategoryColor(String className) {
        if (className == null) return ColorPalette.OID_ENCRYPTION;

        String color = PROGRAM_COLORS.get(className);
        if (color != null) return resolveColorConstant(color);

        // Fallback to legacy logic
        String low = className.toLowerCase();
        if (low.equals("main")) return ColorPalette.OID_SECURITY;
        if (low.contains("shutdown")) return ColorPalette.OID_SECURITY;
        if (low.contains("encrypt") || low.contains("cipher") || low.contains("aes") ||
            low.contains("crypto") || low.contains("keypair") || low.contains("rsa") || low.contains("dsa"))
            return ColorPalette.COLOR_CRYPTO_RED;

        return ColorPalette.OID_ENCRYPTION;
    }

    private static String resolveColorConstant(String name) {
        return switch (name) {
            case "COLOR_STANDARD_CYAN" -> ColorPalette.OID_ENCRYPTION;
            case "COLOR_STANDARD_GREEN" -> ColorPalette.COLOR_STANDARD_GREEN;
            case "COLOR_STANDARD_RED" -> ColorPalette.OID_SECURITY;
            case "COLOR_STANDARD_MAGENTA" -> ColorPalette.COLOR_CRYPTO_RED;
            case "COLOR_STANDARD_YELLOW" -> ColorPalette.COLOR_STANDARD_YELLOW;
            case "COLOR_STANDARD_BLUE" -> ColorPalette.COLOR_STANDARD_BLUE;
            case "COLOR_STANDARD_WHITE" -> ColorPalette.OID_DEFAULT;
            default -> ColorPalette.OID_ENCRYPTION;
        };
    }

    private static void loadPrograms() {
        try {
            File file = new File(PROGRAMS_XML);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            doc.getDocumentElement().normalize();

            NodeList programs = doc.getElementsByTagName("Program");
            for (int i = 0; i < programs.getLength(); i++) {
                Element el = (Element) programs.item(i);
                String name = text(el, "name");
                String color = text(el, "color");
                if (name != null && color != null) {
                    PROGRAM_COLORS.put(name, color);
                }
            }
        } catch (Exception ignored) {}
    }

    private static String text(Element el, String tag) {
        NodeList nl = el.getElementsByTagName(tag);
        if (nl.getLength() == 0) return null;
        String v = nl.item(0).getTextContent().trim();
        return v.isEmpty() ? null : v;
    }
}
