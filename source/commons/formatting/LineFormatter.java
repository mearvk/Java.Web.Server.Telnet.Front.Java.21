package commons.formatting;

import commons.color.ColorPalette;

import java.util.regex.Pattern;

/**
 * Normalizes and colorizes log lines.
 */
public final class LineFormatter {

    private LineFormatter() {}

    private static final Pattern JAVA_WORD = Pattern.compile("(?i)\\bJAVA\\b");

    public static String normalize(String line) {
        if (line == null || line.isEmpty()) return line;

        String result = line;

        // Uppercase first token
        result = uppercaseFirstToken(result);

        // Uppercase specific keywords
        String[] keywords = {
                "telnet", "proxy", "installer", "communicator",
                "webexpress", "messagequeuesorter", "messagequeuehandler", "serversocket"
        };

        for (String kw : keywords) {
            result = result.replaceAll("(?i)\\b" + Pattern.quote(kw) + "\\b", kw.toUpperCase());
        }

        // Color JAVA
        result = JAVA_WORD.matcher(result)
                .replaceAll(ColorPalette.OID_DEFAULT + "JAVA" + ColorPalette.OID_DEFAULT);

        // Color trademark symbol
        result = result.replace("™", ColorPalette.OID_DEFAULT + "™" + ColorPalette.OID_DEFAULT);

        // Color NitroExpress and National Finance
        result = result.replaceAll("(?i)\\bNitroExpress\\b",
                ColorPalette.OID_DEFAULT + "NitroExpress" + ColorPalette.OID_DEFAULT);

        result = result.replaceAll("(?i)National Finance",
                ColorPalette.OID_DEFAULT + "National Finance" + ColorPalette.OID_DEFAULT);

        return result;
    }

    private static String uppercaseFirstToken(String line) {
        int i = 0;
        int len = line.length();

        while (i < len && !Character.isLetterOrDigit(line.charAt(i))) i++;

        int start = i;
        while (i < len && (Character.isLetterOrDigit(line.charAt(i)) || line.charAt(i) == '_')) i++;

        if (start < i) {
            String token = line.substring(start, i).toUpperCase();
            return line.substring(0, start) + token + line.substring(i);
        }

        return line;
    }
}
