package commons.color;

public final class ColorResolver {

    private ColorResolver() {}

    public static String resolveCategoryColor(String className) {
        if (className == null) return ColorPalette.OID_ENCRYPTION;
        String low = className.toLowerCase();

        if (low.equals("main"))
            return ColorPalette.OID_SECURITY;

        if (low.contains("shutdown"))
            return ColorPalette.OID_SECURITY;

        if (low.contains("encrypt") || low.contains("cipher") || low.contains("aes") ||
            low.contains("crypto") || low.contains("keypair") || low.contains("rsa") || low.contains("dsa"))
            return ColorPalette.COLOR_CRYPTO_RED;

        return ColorPalette.OID_ENCRYPTION;
    }
}
