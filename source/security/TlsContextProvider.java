package security;

import commons.CommonRails;

import javax.net.ssl.*;
import java.io.FileInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;

/**
 * TlsContextProvider — shared TLS context for NWE service ports.
 *
 * Loads server keystore from psychiatry/secrets/server.p12 (PKCS12).
 * If the keystore is absent, returns null and services fall back to
 * plaintext (existing behavior). This allows opt-in TLS without breaking
 * existing installations.
 *
 * @author Max Rupplin
 * @date June 29 2026
 */
public final class TlsContextProvider {

    private static final Path KEYSTORE_PATH = Path.of("psychiatry/secrets/server.p12");
    private static final String KEYSTORE_TYPE = "PKCS12";
    private static volatile SSLContext CONTEXT;

    private TlsContextProvider() {}

    /** Get the shared SSLContext, or null if TLS is not configured. */
    public static SSLContext get() {
        if (CONTEXT != null) return CONTEXT;
        synchronized (TlsContextProvider.class) {
            if (CONTEXT != null) return CONTEXT;
            CONTEXT = load();
            return CONTEXT;
        }
    }

    /** Returns true if TLS is available (keystore present and loadable). */
    public static boolean isAvailable() {
        return get() != null;
    }

    /** Create an SSLServerSocketFactory for binding secure ports. */
    public static SSLServerSocketFactory serverSocketFactory() {
        SSLContext ctx = get();
        return ctx != null ? ctx.getServerSocketFactory() : null;
    }

    private static SSLContext load() {
        if (!Files.exists(KEYSTORE_PATH)) {
            CommonRails.printSystemComponent(TlsContextProvider.class,
                    TlsContextProvider.class.hashCode(),
                    ". TLS keystore not found at " + KEYSTORE_PATH + " — TLS disabled .");
            return null;
        }
        try {
            // Keystore password read from environment or default
            String pass = System.getenv("NWE_KEYSTORE_PASS");
            if (pass == null) pass = "changeit";
            char[] passChars = pass.toCharArray();

            KeyStore ks = KeyStore.getInstance(KEYSTORE_TYPE);
            try (FileInputStream fis = new FileInputStream(KEYSTORE_PATH.toFile())) {
                ks.load(fis, passChars);
            }

            KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            kmf.init(ks, passChars);

            TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
            tmf.init(ks);

            SSLContext ctx = SSLContext.getInstance("TLSv1.3");
            ctx.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);

            CommonRails.printSystemComponent(TlsContextProvider.class,
                    TlsContextProvider.class.hashCode(),
                    ". TLS context loaded (TLSv1.3) — keystore=" + KEYSTORE_PATH + " .");
            return ctx;
        } catch (Exception e) {
            CommonRails.printSystemComponent(TlsContextProvider.class,
                    TlsContextProvider.class.hashCode(),
                    ". TLS keystore load FAILED: " + e.getMessage() + " — TLS disabled .");
            return null;
        }
    }
}
