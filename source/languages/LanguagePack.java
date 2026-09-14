package languages;

import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * LanguagePack — loads translation property files from languages/ at startup.
 *
 * Supported codes: en ja cn ru th es fr de it
 * Files:           languages/<code>.properties  (UTF-8, unicode-escaped)
 *
 * Per-IP language preference is stored in PREFS (ConcurrentHashMap).
 * Any port handler can call:
 *   LanguagePack.setLang(ip, code)   — switch language
 *   LanguagePack.t(ip, key)          — translate a key for that IP
 *   LanguagePack.revert(ip)          — reset to English
 *
 * "lang en" revert is always available regardless of current language.
 */
public final class LanguagePack
{
    public static final Set<String> SUPPORTED = Set.of("en","ja","cn","ru","th","es","fr","de","it");
    private static final String     DEFAULT   = "en";
    private static final Path       PACK_DIR  = Paths.get("languages");

    /** code → loaded Properties */
    private static final Map<String, Properties> PACKS = new ConcurrentHashMap<>();
    /** ip → language code */
    private static final Map<String, String>     PREFS = new ConcurrentHashMap<>();

    static { loadAll(); }

    private LanguagePack() {}

    // ── Public API ────────────────────────────────────────────────────────────

    /** Translate key for the language preferred by this IP. */
    public static String t(final String ip, final String key)
    {
        String code = PREFS.getOrDefault(ip, DEFAULT);
        Properties p = PACKS.getOrDefault(code, PACKS.get(DEFAULT));
        if (p == null) return key;
        return p.getProperty(key, PACKS.getOrDefault(DEFAULT, p).getProperty(key, key));
    }

    /** Set language preference for an IP. Returns false if code is unsupported. */
    public static boolean setLang(final String ip, final String code)
    {
        if (!SUPPORTED.contains(code)) return false;
        PREFS.put(ip, code);
        return true;
    }

    /** Revert IP to English. */
    public static void revert(final String ip) { PREFS.put(ip, DEFAULT); }

    /** Current language code for an IP. */
    public static String langOf(final String ip) { return PREFS.getOrDefault(ip, DEFAULT); }

    /**
     * Handle a "lang <code>" command from any port handler.
     * Returns a confirmation line already translated into the new language,
     * or an error line in English if the code is unknown.
     */
    public static String handleLangCommand(final String ip, final String code)
    {
        String c = code.trim().toLowerCase();
        if ("en".equals(c)) { revert(ip); return "[lang] Reverted to English."; }
        if (!setLang(ip, c))
            return "[lang] Unknown code: " + c + ". Supported: " + SUPPORTED;
        return "[lang] Language set to [" + c + "]. " + t(ip, "label.lang_revert");
    }

    // ── Pack loading ──────────────────────────────────────────────────────────

    private static void loadAll()
    {
        for (String code : SUPPORTED)
        {
            Path f = PACK_DIR.resolve(code + ".properties");
            Properties p = new Properties();
            if (Files.exists(f))
            {
                try (InputStreamReader r = new InputStreamReader(new FileInputStream(f.toFile()), StandardCharsets.UTF_8))
                {
                    p.load(r);
                }
                catch (Exception e)
                {
                    System.err.println("[LanguagePack] Failed to load " + f + ": " + e.getMessage());
                }
            }
            else
            {
                System.err.println("[LanguagePack] Missing pack: " + f + " — falling back to English for code=" + code);
            }
            PACKS.put(code, p);
        }
    }
}
