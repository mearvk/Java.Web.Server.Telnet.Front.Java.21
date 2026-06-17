package commons.color;

public final class ColorResolver {

    private ColorResolver() {}

    public static String resolveCategoryColor(String className) {
        if (className == null) return ColorPalette.OID_DEFAULT;
        String low = className.toLowerCase();

        if (low.contains("security") || low.contains("auth") || low.contains("port") || low.equals("main"))
            return ColorPalette.OID_SECURITY;

        if (low.contains("shutdown"))
            return ColorPalette.OID_ENCRYPTION;

        if (low.contains("telnet") || low.contains("proxy") || low.contains("communicator"))
            return ColorPalette.COLOR_TANGERINE;

        if (low.contains("encrypt") || low.contains("cipher") || low.contains("aes") || low.contains("crypto") || low.contains("keypair") || low.contains("rsa") || low.contains("dsa"))
            return ColorPalette.COLOR_LIME_GREEN;

        if (low.contains("bitcoin") || low.contains("wallet") || low.contains("trader"))
            return ColorPalette.OID_BITCOIN;

        if (low.contains("module") || low.contains("loader") || low.contains("installer"))
            return ColorPalette.ANSI_IMPERIAL_GRAY;

        if (low.contains("common") || low.contains("rail") || low.contains("logger"))
            return ColorPalette.OID_LOGGING;

        if (low.contains("config") || low.contains("configuration"))
            return ColorPalette.COLOR_MAROON;

        if (low.contains("message") || low.contains("queue") || low.contains("handler"))
            return ColorPalette.COLOR_BOLD_GREEN;

        if (low.contains("connection") || low.contains("socket") || low.contains("poller"))
            return ColorPalette.OID_CONNECTIONS;

        if (low.contains("nitro") || low.contains("express"))
            return ColorPalette.COLOR_DARK_RED_ORANGE;

        if (low.contains("weather") || low.contains("ascii") || low.contains("auditor") || low.contains("status") || low.contains("binary"))
            return ColorPalette.OID_ENCRYPTION;

        if (low.contains("server"))
            return ColorPalette.COLOR_SILVER_GRAY;

        if (low.contains("liveness") || low.contains("monitor"))
            return ColorPalette.OID_LIVENESS;

        if (low.contains("antivirus") || low.contains("clam") || low.contains("scanner"))
            return ColorPalette.COLOR_DARK_ORANGE;

        if (low.contains("heuristic") || low.contains("classifier"))
            return ColorPalette.COLOR_YELLOW;

        return ColorPalette.OID_DEFAULT;
    }
}
