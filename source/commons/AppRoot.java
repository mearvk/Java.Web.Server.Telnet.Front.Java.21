package commons;

import java.io.File;
import java.nio.file.Path;

/**
 * Resolves the application root directory for relative path access.
 * Priority: -Dnwe.root sysprop > JAR parent dir > CWD.
 */
public final class AppRoot
{
    private static final Path ROOT;

    static
    {
        String prop = System.getProperty("nwe.root");
        if (prop != null && !prop.isBlank())
        {
            ROOT = Path.of(prop).toAbsolutePath().normalize();
        }
        else
        {
            // Derive from the location of this class (works for both out/ and JAR)
            try
            {
                var source = AppRoot.class.getProtectionDomain().getCodeSource();
                if (source != null)
                {
                    Path codePath = Path.of(source.getLocation().toURI()).toAbsolutePath().normalize();
                    // If running from out/ or a JAR in the project root, parent is the project root
                    if (codePath.toFile().isDirectory())
                        ROOT = codePath.getParent() != null ? codePath.getParent() : codePath;
                    else
                        ROOT = codePath.getParent() != null ? codePath.getParent() : Path.of(".").toAbsolutePath().normalize();
                }
                else
                {
                    ROOT = Path.of(".").toAbsolutePath().normalize();
                }
            }
            catch (Exception e)
            {
                throw new ExceptionInInitializerError("Cannot resolve NWE application root: " + e.getMessage());
            }
        }
    }

    private AppRoot() {}

    /** Returns the resolved application root as an absolute Path. */
    public static Path path() { return ROOT; }

    /** Resolves a relative path against the application root. */
    public static File resolve(String relativePath) { return ROOT.resolve(relativePath).toFile(); }

    /** Resolves a relative path and returns the absolute string. */
    public static String resolveString(String relativePath) { return ROOT.resolve(relativePath).toString(); }
}
