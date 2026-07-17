package antivirus;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicLong;

/**
 * InputHeuristicScanner — Real-time heuristic and AV scanning for module inputs.
 *
 * Policy:
 * - Inputs with >1s of major processing gravity: immediate heuristic scan
 * - Files >1MB: immediate ClamAV + heuristic scan (priority queue)
 * - Files ≤1MB: queued for deferred scan on a system-slow steam (careful, safe)
 *
 * The "system-slow steam" is a single-threaded executor that processes the
 * deferred queue at 1 file per 5 seconds, yielding CPU between each scan.
 * This prevents interference with active module operations.
 *
 * Heuristics checked:
 * - Known malicious byte sequences (PE headers in non-exe uploads, ELF in non-binary)
 * - Embedded scripts in image/document uploads (polyglot detection)
 * - Excessive null bytes (padding/obfuscation)
 * - Double extensions (.jpg.exe, .pdf.sh)
 * - Path traversal attempts (../ in filenames)
 * - Abnormal entropy (encrypted/compressed payloads in plain-text fields)
 * - Shell injection patterns in text inputs
 *
 * Integration:
 *   InputHeuristicScanner.scanInput(moduleId, username, ip, inputData, processingTimeMs)
 *   InputHeuristicScanner.scanFile(moduleId, username, ip, filename, fileData)
 *
 * @author Max Rupplin
 * @date July 16 2026
 * MEARVK LLC — NitroWebExpress™
 */
public class InputHeuristicScanner {

    private static final long GRAVITY_THRESHOLD_MS = 1000; // 1 second of major gravity
    private static final long FILE_PRIORITY_SIZE = 1024 * 1024; // 1MB threshold
    private static final long SLOW_STEAM_DELAY_MS = 5000; // 5 seconds between deferred scans
    private static final Path SCAN_LOG = Path.of("logging/heuristic-scan.log");

    // Priority queue for large files (>1MB) — scanned immediately
    private static final BlockingQueue<ScanJob> PRIORITY_QUEUE = new LinkedBlockingQueue<>();
    // Deferred queue for small files (≤1MB) — scanned on slow steam
    private static final BlockingQueue<ScanJob> DEFERRED_QUEUE = new LinkedBlockingQueue<>();

    private static final AtomicLong totalScans = new AtomicLong(0);
    private static final AtomicLong threats = new AtomicLong(0);

    // Known bad signatures (first bytes)
    private static final byte[] PE_HEADER = new byte[]{0x4D, 0x5A}; // MZ (Windows exe)
    private static final byte[] ELF_HEADER = new byte[]{0x7F, 0x45, 0x4C, 0x46}; // ELF
    private static final byte[] SCRIPT_TAG = "<script".getBytes();
    private static final byte[] PHP_TAG = "<?php".getBytes();

    // Shell injection patterns
    private static final String[] SHELL_PATTERNS = {
        "$(", "`", "&&", "||", ";rm ", "; rm", "|/bin/", ">/dev/", "wget ", "curl ",
        "/etc/passwd", "/etc/shadow", "eval(", "exec(", "system(", "Runtime.exec",
        "ProcessBuilder", "chmod ", "chown ", "mkfifo", "nc -", "ncat "
    };

    // Double extension traps
    private static final String[] DANGEROUS_DOUBLE_EXT = {
        ".jpg.exe", ".png.exe", ".pdf.exe", ".doc.exe", ".txt.exe",
        ".jpg.sh", ".png.sh", ".pdf.sh", ".doc.sh",
        ".jpeg.bat", ".png.bat", ".pdf.bat",
        ".jpg.ps1", ".pdf.ps1"
    };

    static {
        // Start priority scanner thread (immediate, for >1MB files and >1s gravity)
        Thread priority = new Thread(InputHeuristicScanner::priorityScanLoop, "HeuristicScanner-Priority");
        priority.setDaemon(true);
        priority.start();

        // Start slow-steam scanner thread (deferred, careful, safe)
        Thread slow = new Thread(InputHeuristicScanner::slowSteamLoop, "HeuristicScanner-SlowSteam");
        slow.setDaemon(true);
        slow.start();

        CommonRails.printSystemComponent(null, 0,
            ". InputHeuristicScanner initialized — priority + slow-steam threads active .");
    }

    // ── Public API ─────────────────────────────────────────────────────────────

    /**
     * Scan a text/command input. If processing took >1s (major gravity), scan immediately.
     *
     * @param moduleId       Module identifier (CHAT, UNCW, SPECTRUM_TANDEM, etc.)
     * @param username       Username of the input source
     * @param ip             Source IP
     * @param inputData      The raw input string
     * @param processingTimeMs How long the input took to process (ms)
     * @return ScanResult — CLEAN, SUSPICIOUS, or BLOCKED
     */
    public static ScanResult scanInput(String moduleId, String username, String ip,
                                        String inputData, long processingTimeMs) {
        totalScans.incrementAndGet();

        // Immediate heuristic check on all text inputs
        ScanResult result = heuristicCheckText(inputData);

        if (result != ScanResult.CLEAN) {
            threats.incrementAndGet();
            logThreat(moduleId, username, ip, "TEXT_INPUT", result, inputData.substring(0, Math.min(200, inputData.length())));
            return result;
        }

        // If processing took >1s of major gravity, run deep analysis
        if (processingTimeMs > GRAVITY_THRESHOLD_MS) {
            result = deepAnalyzeText(inputData);
            if (result != ScanResult.CLEAN) {
                threats.incrementAndGet();
                logThreat(moduleId, username, ip, "GRAVITY_TEXT(" + processingTimeMs + "ms)", result, inputData.substring(0, Math.min(200, inputData.length())));
            }
            return result;
        }

        return ScanResult.CLEAN;
    }

    /**
     * Scan a file upload. Files >1MB go to priority queue (immediate).
     * Files ≤1MB go to deferred queue (slow steam, careful).
     *
     * @param moduleId  Module identifier
     * @param username  Username
     * @param ip        Source IP
     * @param filename  Original filename
     * @param fileData  Raw file bytes
     * @return ScanResult for immediate checks; deferred files return PENDING
     */
    public static ScanResult scanFile(String moduleId, String username, String ip,
                                       String filename, byte[] fileData) {
        totalScans.incrementAndGet();

        // Immediate heuristic checks on all files regardless of size
        ScanResult quickResult = heuristicCheckFile(filename, fileData);
        if (quickResult == ScanResult.BLOCKED) {
            threats.incrementAndGet();
            logThreat(moduleId, username, ip, "FILE:" + filename + "(" + fileData.length + "B)", quickResult, "Blocked by heuristic");
            return ScanResult.BLOCKED;
        }

        ScanJob job = new ScanJob(moduleId, username, ip, filename, fileData, Instant.now());

        if (fileData.length > FILE_PRIORITY_SIZE) {
            // >1MB: priority queue — immediate deep scan
            PRIORITY_QUEUE.offer(job);
            return quickResult; // Return heuristic result immediately; deep scan async
        } else {
            // ≤1MB: deferred queue — slow steam, careful and safe
            DEFERRED_QUEUE.offer(job);
            return quickResult != ScanResult.CLEAN ? quickResult : ScanResult.PENDING;
        }
    }

    /**
     * Get scan statistics.
     */
    public static String getStats() {
        return "HEURISTIC_STATS|scans=" + totalScans.get() + "|threats=" + threats.get() +
            "|priority_queue=" + PRIORITY_QUEUE.size() + "|deferred_queue=" + DEFERRED_QUEUE.size();
    }

    // ── Heuristic Checks ───────────────────────────────────────────────────────

    private static ScanResult heuristicCheckText(String input) {
        if (input == null || input.isEmpty()) return ScanResult.CLEAN;

        // Path traversal
        if (input.contains("../") || input.contains("..\\")) return ScanResult.SUSPICIOUS;

        // Shell injection patterns
        for (String pattern : SHELL_PATTERNS) {
            if (input.contains(pattern)) return ScanResult.BLOCKED;
        }

        // Null byte injection
        if (input.contains("\0")) return ScanResult.BLOCKED;

        // Excessive length for a single command (>64KB suggests buffer overflow attempt)
        if (input.length() > 65536) return ScanResult.SUSPICIOUS;

        return ScanResult.CLEAN;
    }

    private static ScanResult heuristicCheckFile(String filename, byte[] data) {
        if (filename == null || data == null || data.length == 0) return ScanResult.CLEAN;

        String lower = filename.toLowerCase();

        // Double extension trap
        for (String dext : DANGEROUS_DOUBLE_EXT) {
            if (lower.endsWith(dext)) return ScanResult.BLOCKED;
        }

        // Path traversal in filename
        if (filename.contains("../") || filename.contains("..\\") || filename.contains("/etc/") || filename.contains("\\windows\\")) {
            return ScanResult.BLOCKED;
        }

        // PE header in non-executable upload
        if (!lower.endsWith(".exe") && !lower.endsWith(".dll") && data.length >= 2) {
            if (data[0] == PE_HEADER[0] && data[1] == PE_HEADER[1]) return ScanResult.BLOCKED;
        }

        // ELF header in non-binary upload
        if (!lower.endsWith(".so") && !lower.endsWith(".bin") && !lower.endsWith(".elf") && data.length >= 4) {
            if (data[0] == ELF_HEADER[0] && data[1] == ELF_HEADER[1] &&
                data[2] == ELF_HEADER[2] && data[3] == ELF_HEADER[3]) return ScanResult.BLOCKED;
        }

        // Embedded script in image/document
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".png") ||
            lower.endsWith(".gif") || lower.endsWith(".pdf") || lower.endsWith(".doc")) {
            if (containsBytes(data, SCRIPT_TAG) || containsBytes(data, PHP_TAG)) {
                return ScanResult.SUSPICIOUS;
            }
        }

        // Excessive null bytes (>30% of file = padding/obfuscation)
        int nullCount = 0;
        int checkLen = Math.min(data.length, 4096); // Check first 4KB
        for (int i = 0; i < checkLen; i++) {
            if (data[i] == 0) nullCount++;
        }
        if (checkLen > 0 && (double) nullCount / checkLen > 0.3) return ScanResult.SUSPICIOUS;

        return ScanResult.CLEAN;
    }

    private static ScanResult deepAnalyzeText(String input) {
        // Entropy analysis — high entropy in text input suggests encoded payload
        double entropy = calculateEntropy(input.getBytes());
        if (entropy > 7.5) return ScanResult.SUSPICIOUS; // Near-random = likely encoded

        // Repeated pattern detection (base64 or hex dump disguised as text)
        if (input.matches(".*[A-Za-z0-9+/=]{200,}.*")) return ScanResult.SUSPICIOUS;

        return ScanResult.CLEAN;
    }

    // ── Background Scan Loops ──────────────────────────────────────────────────

    private static void priorityScanLoop() {
        while (true) {
            try {
                ScanJob job = PRIORITY_QUEUE.take(); // blocks until available
                performDeepScan(job, "PRIORITY");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                ExceptionHandler.dispatch(e);
            }
        }
    }

    private static void slowSteamLoop() {
        while (true) {
            try {
                ScanJob job = DEFERRED_QUEUE.take(); // blocks until available
                // Slow steam: wait between scans to be careful and safe
                Thread.sleep(SLOW_STEAM_DELAY_MS);
                performDeepScan(job, "SLOW_STEAM");
                // Yield CPU between scans
                Thread.yield();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                ExceptionHandler.dispatch(e);
            }
        }
    }

    private static void performDeepScan(ScanJob job, String queue) {
        try {
            // Write to temp file for AV scan
            Path tempFile = Files.createTempFile("nwe-scan-", "-" + sanitizeFilename(job.filename));
            Files.write(tempFile, job.data);

            boolean avClean = true;
            String os = System.getProperty("os.name", "").toLowerCase();

            if (os.contains("win")) {
                // Microsoft Defender — MpCmdRun.exe (Windows only, scriptable CLI)
                avClean = runDefenderScan(tempFile, job, queue);
            } else {
                // ClamAV (Linux/macOS)
                avClean = runClamScan(tempFile, job, queue);
            }

            // Additional entropy analysis for deep scan
            double entropy = calculateEntropy(job.data);
            if (entropy > 7.8 && !isKnownCompressedType(job.filename)) {
                logThreat(job.moduleId, job.username, job.ip,
                    queue + ":HIGH_ENTROPY:" + job.filename,
                    ScanResult.SUSPICIOUS, "Entropy=" + String.format("%.2f", entropy));
            }

            // Cleanup temp file
            Files.deleteIfExists(tempFile);

            if (avClean) {
                logScan(job.moduleId, job.username, queue, job.filename, job.data.length, "CLEAN");
            }
        } catch (Exception e) {
            ExceptionHandler.dispatch(e);
        }
    }

    /**
     * Run Microsoft Defender scan via MpCmdRun.exe (Windows).
     * MpCmdRun.exe is the only free AV with a scriptable CLI.
     * Targeted scan (ScanType 3) on specific file.
     */
    private static boolean runDefenderScan(Path targetFile, ScanJob job, String queue) {
        try {
            String mpcmdrun = "C:\\Program Files\\Windows Defender\\MpCmdRun.exe";
            if (!Files.exists(Path.of(mpcmdrun))) {
                // Try alternate path
                mpcmdrun = System.getenv("ProgramFiles") + "\\Windows Defender\\MpCmdRun.exe";
            }
            if (!Files.exists(Path.of(mpcmdrun))) return true; // Defender not available

            Process p = new ProcessBuilder(mpcmdrun, "-Scan", "-ScanType", "3",
                "-File", targetFile.toString(), "-DisableRemediation", "true")
                .redirectErrorStream(true).start();
            String output = new BufferedReader(new InputStreamReader(p.getInputStream()))
                .lines().collect(java.util.stream.Collectors.joining("\n"));
            int exit = p.waitFor();

            // Exit 0 = clean, Exit 2 = threat found
            if (exit == 2) {
                threats.incrementAndGet();
                logThreat(job.moduleId, job.username, job.ip,
                    queue + ":DEFENDER:" + job.filename + "(" + job.data.length + "B)",
                    ScanResult.BLOCKED, "Microsoft Defender detected: " + output.trim());
                return false;
            }
            return true;
        } catch (Exception e) {
            // Defender not available or error — log and continue
            appendLog("[" + java.time.LocalDateTime.now() + "] Defender scan skipped: " + e.getMessage());
            return true;
        }
    }

    /**
     * Run ClamAV scan via clamscan CLI (Linux/macOS).
     */
    private static boolean runClamScan(Path targetFile, ScanJob job, String queue) {
        try {
            Process p = new ProcessBuilder("clamscan", "--no-summary", targetFile.toString())
                .redirectErrorStream(true).start();
            String output = new BufferedReader(new InputStreamReader(p.getInputStream()))
                .lines().collect(java.util.stream.Collectors.joining("\n"));
            int exit = p.waitFor();
            if (exit != 0) {
                threats.incrementAndGet();
                logThreat(job.moduleId, job.username, job.ip,
                    queue + ":CLAMAV:" + job.filename + "(" + job.data.length + "B)",
                    ScanResult.BLOCKED, "ClamAV detected: " + output.trim());
                return false;
            }
            return true;
        } catch (Exception e) {
            // ClamAV not available — rely on heuristics only
            return true;
        }
    }

    // ── Utilities ──────────────────────────────────────────────────────────────

    private static double calculateEntropy(byte[] data) {
        if (data.length == 0) return 0;
        int[] freq = new int[256];
        for (byte b : data) freq[b & 0xFF]++;
        double entropy = 0;
        double len = data.length;
        for (int f : freq) {
            if (f > 0) {
                double p = f / len;
                entropy -= p * (Math.log(p) / Math.log(2));
            }
        }
        return entropy;
    }

    private static boolean containsBytes(byte[] haystack, byte[] needle) {
        outer:
        for (int i = 0; i <= haystack.length - needle.length; i++) {
            for (int j = 0; j < needle.length; j++) {
                if (haystack[i + j] != needle[j]) continue outer;
            }
            return true;
        }
        return false;
    }

    private static boolean isKnownCompressedType(String filename) {
        String lower = filename.toLowerCase();
        return lower.endsWith(".zip") || lower.endsWith(".gz") || lower.endsWith(".bz2") ||
            lower.endsWith(".xz") || lower.endsWith(".7z") || lower.endsWith(".rar") ||
            lower.endsWith(".tar") || lower.endsWith(".jar") || lower.endsWith(".war") ||
            lower.endsWith(".mp3") || lower.endsWith(".mp4") || lower.endsWith(".ogg") ||
            lower.endsWith(".flac") || lower.endsWith(".aac") || lower.endsWith(".m4a") ||
            lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".png") ||
            lower.endsWith(".webp") || lower.endsWith(".gif");
    }

    private static String sanitizeFilename(String name) {
        if (name == null) return "unknown";
        return name.replaceAll("[^a-zA-Z0-9._-]", "_").substring(0, Math.min(name.length(), 64));
    }

    private static void logThreat(String moduleId, String username, String ip,
                                   String context, ScanResult result, String detail) {
        String entry = "[" + LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) + "] " +
            "THREAT " + result + " | module=" + moduleId + " | user=" + username +
            " | ip=" + ip + " | context=" + context + " | detail=" + detail;
        CommonRails.printSystemComponent(null, 0, ". HEURISTIC " + result + ": " + context + " .");
        appendLog(entry);
    }

    private static void logScan(String moduleId, String username, String queue,
                                 String filename, int size, String result) {
        String entry = "[" + LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) + "] " +
            queue + " SCAN " + result + " | module=" + moduleId + " | user=" + username +
            " | file=" + filename + " | size=" + size;
        appendLog(entry);
    }

    private static void appendLog(String entry) {
        try {
            Files.createDirectories(SCAN_LOG.getParent());
            Files.writeString(SCAN_LOG, entry + "\n", StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (Exception ignored) {}
    }

    // ── Result Enum ────────────────────────────────────────────────────────────

    public enum ScanResult {
        CLEAN,       // No threats detected
        PENDING,     // Queued for deferred scan (small files, slow steam)
        SUSPICIOUS,  // Heuristic flags raised but not definitively malicious
        BLOCKED      // Definitive threat — input rejected
    }

    // ── Scan Job ───────────────────────────────────────────────────────────────

    private record ScanJob(String moduleId, String username, String ip,
                           String filename, byte[] data, Instant submitted) {}
}
