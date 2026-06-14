package commons.color;

/**
 * Centralized ANSI color palette for all terminal output.
 * No raw escape codes appear anywhere else in the system.
 */
public final class ColorPalette {

    private ColorPalette() {}

    public static final String COLOR_LIME_GREEN     = "\033[38;5;118m";
    public static final String COLOR_TANGERINE      = "\033[38;5;214m";
    public static final String COLOR_STANDARD_RED   = "\033[38;5;160m";
    public static final String COLOR_YELLOW         = "\033[38;5;226m";
    public static final String ANSI_YELLOW          = "\u001B[33m";
    public static final String ANSI_WHITE           = "\033[38;5;15m";
    public static final String ANSI_DEEP_RED        = "\033[38;5;160m";
    public static final String ANSI_SILVER          = "\033[38;5;250m";
    public static final String ANSI_IMPERIAL_GRAY   = "\u001B[38;5;242m";
    public static final String ANSI_RESET           = "\u001B[0m";
    public static final String OID_SECURITY         = "\033[38;5;196m";
    public static final String OID_TELNET           = "\033[38;5;51m";
    public static final String OID_ENCRYPTION       = "\033[38;5;208m";
    public static final String OID_BITCOIN          = "\033[38;5;220m";
    public static final String OID_LOGGING          = "\033[38;5;147m";
    public static final String OID_MESSAGING        = "\033[38;5;118m";
    public static final String OID_CONNECTIONS      = "\033[38;5;75m";
    public static final String OID_SERVER           = "\033[38;5;214m";
    public static final String OID_LIVENESS         = "\033[38;5;46m";
    public static final String OID_DEFAULT          = "\033[38;5;250m";
    public static final String ANSI_NEAR_RESET_DARK = "\033[38;5;253m";

    public static final String WHITE = "\033[38;5;15m";
    public static final String SILVER = "\033[38;5;250m";
    public static final String DEEP_RED = "\033[38;5;160m";
}
