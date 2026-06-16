package commons.color;

public final class ColorResolver {

    private ColorResolver() {}

    public static String resolveCategoryColor(String className) {
        if (className == null) return ColorPalette.OID_DEFAULT;
        String low = className.toLowerCase();

        if (low.contains("security") || low.contains("auth") || low.contains("port"))
            return ColorPalette.OID_SECURITY;

        if (low.contains("telnet") || low.contains("proxy") || low.contains("communicator"))
            return ColorPalette.OID_TELNET;

        if (low.contains("encrypt") || low.contains("cipher") || low.contains("aes"))
            return ColorPalette.OID_ENCRYPTION;

        if (low.contains("bitcoin") || low.contains("wallet") || low.contains("trader"))
            return ColorPalette.OID_BITCOIN;

        if (low.contains("common") || low.contains("rail") || low.contains("logger"))
            return ColorPalette.OID_LOGGING;

        if (low.contains("message") || low.contains("queue") || low.contains("handler"))
            return ColorPalette.OID_MESSAGING;

        if (low.contains("connection") || low.contains("socket") || low.contains("poller"))
            return ColorPalette.OID_CONNECTIONS;

        if (low.contains("server") || low.contains("express") || low.contains("nitro"))
            return ColorPalette.OID_SERVER;

        if (low.contains("liveness") || low.contains("monitor"))
            return ColorPalette.OID_LIVENESS;

        if (low.contains("heuristic") || low.contains("classifier"))
            return ColorPalette.COLOR_YELLOW;

        return ColorPalette.OID_DEFAULT;
    }
}
