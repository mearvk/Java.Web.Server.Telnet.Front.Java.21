package heuristics;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * ModuleHeuristics — scores and validates a candidate module before submission
 * to ModuleInstallationService or ModuleLoaderDaemon.
 *
 * Call evaluate(path) to get a Result with a 0–100 score and a list of
 * findings.  A score >= PASS_THRESHOLD (70) is considered suitable for install.
 * Callers may also call the individual check methods directly.
 *
 * Supported types: .jar  .zip  .java  .exe  .bat  .sh  .py
 * Executable modules (.exe, .bat, .sh, .py) are always run as non-root.
 * The C companion (linux/c/heuristics/ModuleHeuristics.c) handles binary/native
 * module inspection before they are wrapped and submitted from C-side tooling.
 */
public class ModuleHeuristics
{
    public static final int PASS_THRESHOLD = 70;

    // ── Public API ────────────────────────────────────────────────────────────

    public static Result evaluate(final Path PATH) throws IOException
    {
        byte[] data = Files.readAllBytes(PATH);
        String name = PATH.getFileName().toString().toLowerCase();
        List<String> findings = new ArrayList<>();
        int score = 0;

        // ── 1. File type recognised (+20) ─────────────────────────────────────
        String type = detectType(data, name);
        if (type != null)
        {
            score += 20;
            findings.add("OK   file type recognised: " + type);
        }
        else
        {
            findings.add("FAIL unrecognised file type — must be .jar, .zip, .java, .exe, .bat, .sh, or .py");
            return new Result(0, findings); // no point continuing
        }

        // ── 2. Non-empty (+10) ────────────────────────────────────────────────
        if (data.length > 0)
        {
            score += 10;
            findings.add("OK   non-empty: " + data.length + " bytes");
        }
        else
        {
            findings.add("FAIL file is empty");
        }

        // ── 3. Size reasonable — under 50 MB (+10) ────────────────────────────
        if (data.length <= 50 * 1024 * 1024)
        {
            score += 10;
            findings.add("OK   size within 50 MB limit");
        }
        else
        {
            findings.add("WARN size exceeds 50 MB — server may reject");
        }

        // ── 4. Type-specific content checks ───────────────────────────────────
        switch (type)
        {
            case "jar"  -> score += checkJar(data, findings);
            case "zip"  -> score += checkZip(data, findings);
            case "java" -> score += checkJavaSource(data, findings);
            case "exe"  -> score += checkExecutable(name, findings);
            case "bat"  -> score += checkScript(data, name, findings);
            case "sh"   -> score += checkScript(data, name, findings);
            case "py"   -> score += checkScript(data, name, findings);
        }

        // ── 5. Name is sane (+5) ──────────────────────────────────────────────
        String baseName = PATH.getFileName().toString().replaceAll("\\.[^.]+$", "");
        if (baseName.matches("[a-zA-Z0-9._-]+"))
        {
            score += 5;
            findings.add("OK   module name is safe: " + baseName);
        }
        else
        {
            findings.add("WARN module name contains special characters — will be sanitised on install");
        }

        return new Result(Math.min(score, 100), findings);
    }

    /** Quick pass/fail check without the full report. */
    public static boolean isSuitable(final Path PATH) throws IOException
    {
        return evaluate(PATH).score >= PASS_THRESHOLD;
    }

    // ── Type-specific checks ──────────────────────────────────────────────────

    /** Returns bonus score for a .jar. */
    private static int checkJar(final byte[] DATA, final List<String> FINDINGS)
    {
        int bonus = 0;
        boolean hasManifest = false;
        boolean hasClassFile = false;

        try (ZipInputStream zis = new ZipInputStream(new java.io.ByteArrayInputStream(DATA)))
        {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null)
            {
                String en = entry.getName();
                if (en.equals("META-INF/MANIFEST.MF")) hasManifest = true;
                if (en.endsWith(".class"))              hasClassFile = true;
                zis.closeEntry();
            }
        }
        catch (IOException e)
        {
            FINDINGS.add("FAIL jar is not a valid zip archive: " + e.getMessage());
            return 0;
        }

        if (hasManifest) { bonus += 15; FINDINGS.add("OK   MANIFEST.MF present"); }
        else               FINDINGS.add("WARN no META-INF/MANIFEST.MF found");

        if (hasClassFile) { bonus += 25; FINDINGS.add("OK   .class files present"); }
        else                FINDINGS.add("WARN no .class files found in jar");

        return bonus;
    }

    /** Returns bonus score for a .zip module bundle. */
    private static int checkZip(final byte[] DATA, final List<String> FINDINGS)
    {
        int bonus = 0;
        int entries = 0;

        try (ZipInputStream zis = new ZipInputStream(new java.io.ByteArrayInputStream(DATA)))
        {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) { entries++; zis.closeEntry(); }
        }
        catch (IOException e)
        {
            FINDINGS.add("FAIL zip is corrupt: " + e.getMessage());
            return 0;
        }

        if (entries > 0) { bonus += 30; FINDINGS.add("OK   zip contains " + entries + " entries"); }
        else               FINDINGS.add("WARN zip is empty");

        return bonus;
    }

    /** Returns bonus score for raw .java source. */
    private static int checkJavaSource(final byte[] DATA, final List<String> FINDINGS)
    {
        int bonus = 0;
        String src = new String(DATA, 0, Math.min(DATA.length, 4096));

        if (src.contains("public class") || src.contains("public interface") || src.contains("public enum"))
        {
            bonus += 20;
            FINDINGS.add("OK   public type declaration found");
        }
        else
        {
            FINDINGS.add("WARN no public class/interface/enum found — may not compile");
        }

        if (src.contains("package "))
        {
            bonus += 10;
            FINDINGS.add("OK   package declaration present");
        }
        else
        {
            FINDINGS.add("INFO no package declaration — will install in default package");
        }

        // Flag dangerous patterns
        if (src.contains("Runtime.getRuntime().exec") || src.contains("ProcessBuilder"))
        {
            FINDINGS.add("WARN source contains process execution — review before installing");
        }
        else
        {
            bonus += 10;
            FINDINGS.add("OK   no obvious process-execution patterns");
        }

        return bonus;
    }

    /** Returns bonus score for a .exe binary (PE format). */
    private static int checkExecutable(final String NAME, final List<String> FINDINGS)
    {
        int bonus = 20;
        FINDINGS.add("OK   PE executable detected: " + NAME);
        FINDINGS.add("INFO will execute as non-root user");
        return bonus;
    }

    /** Returns bonus score for script files (.bat, .sh, .py). */
    private static int checkScript(final byte[] DATA, final String NAME, final List<String> FINDINGS)
    {
        int bonus = 0;
        String src = new String(DATA, 0, Math.min(DATA.length, 4096));

        if (!src.isBlank())
        {
            bonus += 20;
            FINDINGS.add("OK   script has content: " + NAME);
        }
        else
        {
            FINDINGS.add("WARN script is blank");
        }

        // Flag dangerous patterns
        if (src.contains("rm -rf") || src.contains("mkfs") || src.contains("dd if=") || src.contains(":(){"))
        {
            FINDINGS.add("WARN script contains potentially destructive commands — review before installing");
        }
        else
        {
            bonus += 10;
            FINDINGS.add("OK   no obvious destructive patterns");
        }

        FINDINGS.add("INFO will execute as non-root user");
        return bonus;
    }

    // ── Execution helper ──────────────────────────────────────────────────────

    /**
     * Launches a module file as a non-root subprocess.
     * All executable types (.exe via wine, .bat via cmd, .sh via bash, .py via python3)
     * are run under the current non-root user — never elevated.
     *
     * @return the started Process (caller manages lifecycle)
     */
    public static Process executeAsNonRoot(final Path PATH) throws IOException
    {
        String name = PATH.getFileName().toString().toLowerCase();
        String abs  = PATH.toAbsolutePath().toString();

        String[] cmd;
        if (name.endsWith(".exe"))       cmd = new String[]{"wine", abs};
        else if (name.endsWith(".bat"))   cmd = new String[]{"cmd", "/c", abs};
        else if (name.endsWith(".sh"))    cmd = new String[]{"bash", abs};
        else if (name.endsWith(".py"))    cmd = new String[]{"python3", abs};
        else throw new IOException("Unsupported executable type: " + name);

        ProcessBuilder pb = new ProcessBuilder(cmd);
        pb.redirectErrorStream(true);
        // Ensure we never run as root
        if ("root".equals(System.getProperty("user.name")))
        {
            throw new SecurityException("Refusing to execute module as root — switch to a non-root user");
        }
        return pb.start();
    }

    // ── Type detection ────────────────────────────────────────────────────────

    private static String detectType(final byte[] DATA, final String NAME)
    {
        if (DATA.length < 2) return null;

        // ZIP/JAR magic: PK
        if (DATA[0] == 0x50 && DATA[1] == 0x4B)
        {
            String header = new String(DATA, 0, Math.min(DATA.length, 512));
            return header.contains("META-INF") ? "jar" : "zip";
        }

        // PE executable magic: MZ
        if (DATA[0] == 0x4D && DATA[1] == 0x5A && NAME.endsWith(".exe")) return "exe";

        // Script types by extension
        if (NAME.endsWith(".bat")) return "bat";
        if (NAME.endsWith(".sh"))  return "sh";
        if (NAME.endsWith(".py"))  return "py";

        // Java source — check extension and content
        if (NAME.endsWith(".java"))
        {
            String text = new String(DATA, 0, Math.min(DATA.length, 512));
            if (text.contains("class ") || text.contains("interface ") || text.contains("package "))
                return "java";
        }

        return null;
    }

    // ── Result type ───────────────────────────────────────────────────────────

    public static class Result
    {
        public final int          score;    // 0–100
        public final List<String> findings;
        public final boolean      suitable;

        public Result(final int SCORE, final List<String> FINDINGS)
        {
            this.score    = SCORE;
            this.findings = List.copyOf(FINDINGS);
            this.suitable = SCORE >= PASS_THRESHOLD;
        }

        public String summary()
        {
            StringBuilder sb = new StringBuilder();
            sb.append("ModuleHeuristics score: ").append(score).append("/100 — ")
              .append(suitable ? "SUITABLE for install" : "NOT suitable (score < " + PASS_THRESHOLD + ")").append('\n');
            for (String f : findings) sb.append("  ").append(f).append('\n');
            return sb.toString().stripTrailing();
        }
    }
}
