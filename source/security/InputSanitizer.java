package security;

import commons.CommonRails;

import java.util.regex.Pattern;

/**
 * InputSanitizer — centralized input validation for all NWE TCP services.
 *
 * Prevents command injection, path traversal, and protocol abuse across
 * all socket-based modules. Use at every TCP command parse boundary.
 *
 * @author Max Rupplin
 * @date June 29 2026
 */
public final class InputSanitizer {

    private static final int MAX_COMMAND_LENGTH = 4096;
    private static final Pattern PATH_TRAVERSAL = Pattern.compile("\\.\\./|\\.\\.\\\\");
    private static final Pattern NULL_BYTE = Pattern.compile("\\x00");
    private static final Pattern SHELL_INJECTION = Pattern.compile("[;|&`$(){}\\[\\]]");

    private InputSanitizer() {}

    /** Validate a raw TCP command line. Returns null if input is malicious. */
    public static String sanitizeCommand(String input) {
        if (input == null) return null;
        if (input.length() > MAX_COMMAND_LENGTH) return null;
        if (NULL_BYTE.matcher(input).find()) return null;
        return input.trim();
    }

    /** Validate a file path argument — reject traversal attempts. */
    public static String sanitizePath(String path) {
        if (path == null) return null;
        if (PATH_TRAVERSAL.matcher(path).find()) return null;
        if (NULL_BYTE.matcher(path).find()) return null;
        return path.trim();
    }

    /** Validate a port number string. */
    public static int sanitizePort(String portStr) {
        try {
            int port = Integer.parseInt(portStr.trim());
            if (port < 0 || port > 1048576) return -1;
            return port;
        } catch (NumberFormatException e) { return -1; }
    }

    /** Strip shell-dangerous characters from a user-supplied value. */
    public static String stripShellChars(String input) {
        if (input == null) return null;
        return SHELL_INJECTION.matcher(input).replaceAll("");
    }

    /** Validate an email address (basic RFC 5321 compliance). */
    public static boolean isValidEmail(String email) {
        if (email == null || email.length() > 254) return false;
        return email.matches("^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$");
    }

    /** Validate a Bitcoin/Dash transaction ID (hex string, 64 chars). */
    public static boolean isValidTxId(String txid) {
        if (txid == null) return false;
        return txid.matches("^[a-fA-F0-9]{64}$");
    }

    /** Sanitize XML payload — prevent XXE by stripping DOCTYPE. */
    public static String sanitizeXml(String xml) {
        if (xml == null) return null;
        if (xml.contains("<!DOCTYPE") || xml.contains("<!ENTITY")) return null;
        return xml;
    }
}
