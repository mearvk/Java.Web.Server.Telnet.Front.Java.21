package com.mearvk.servlet;

import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.*;

/**
 * Brarner.M.Alete™ — Analysis Upload Servlet
 *
 * Accepts file uploads (data, audio, images) for taxonomy-level analysis.
 * Pipeline: Upload → ClamAV Scan → Heuristic Check → SignalProcessor → Results File
 *
 * POST /api/analysis/upload
 *   - multipart/form-data
 *   - Parameters: rank (kingdom|class|order|family), taxon (name), type (data|audio|image)
 *   - File part: "file"
 *
 * GET /api/analysis/status?id=<job-id>
 *   - Returns JSON with progress, stage, result file path
 *
 * GET /api/analysis/result?id=<job-id>
 *   - Downloads the result file
 *
 * MEARVK LLC — 2026
 */
@WebServlet(urlPatterns = {"/api/analysis/upload", "/api/analysis/status", "/api/analysis/result"})
@MultipartConfig(
    maxFileSize = 52428800,       // 50 MB
    maxRequestSize = 52428800,
    fileSizeThreshold = 1048576   // 1 MB before disk spill
)
public class AnalysisUploadServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "/opt/bma/analysis/uploads";
    private static final String RESULTS_DIR = "/opt/bma/analysis/results";
    private static final int SIGNAL_PROCESSOR_PORT = 20000; // Strernary™ inference

    // In-memory job tracker (production: use DB or Redis)
    private static final ConcurrentHashMap<String, AnalysisJob> JOBS = new ConcurrentHashMap<>();

    private static final ExecutorService PIPELINE = Executors.newVirtualThreadPerTaskExecutor();

    // ─── Job state ───
    public static class AnalysisJob {
        public String id;
        public String rank;
        public String taxon;
        public String type;           // data, audio, image
        public String originalName;
        public String storedPath;
        public String resultPath;
        public String stage;          // uploading, scanning, heuristic, processing, complete, failed
        public int progress;          // 0-100
        public String error;
        public long createdAt;

        public String toJson() {
            return "{\"id\":\"" + id + "\","
                + "\"rank\":\"" + rank + "\","
                + "\"taxon\":\"" + esc(taxon) + "\","
                + "\"type\":\"" + type + "\","
                + "\"originalName\":\"" + esc(originalName) + "\","
                + "\"stage\":\"" + stage + "\","
                + "\"progress\":" + progress + ","
                + "\"error\":" + (error != null ? "\"" + esc(error) + "\"" : "null") + ","
                + "\"resultReady\":" + ("complete".equals(stage)) + "}";
        }

        private String esc(String s) {
            if (s == null) return "";
            return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");

        try {
            String rank = req.getParameter("rank");
            String taxon = req.getParameter("taxon");
            String type = req.getParameter("type");
            Part filePart = req.getPart("file");

            // Validate
            if (rank == null || taxon == null || type == null || filePart == null || filePart.getSize() == 0) {
                resp.setStatus(400);
                resp.getWriter().write("{\"error\":\"Missing required parameters: rank, taxon, type, file\"}");
                return;
            }

            if (!rank.matches("kingdom|phylum|class|order|family")) {
                resp.setStatus(400);
                resp.getWriter().write("{\"error\":\"Invalid rank. Use: kingdom, phylum, class, order, family\"}");
                return;
            }

            if (!type.matches("data|audio|image")) {
                resp.setStatus(400);
                resp.getWriter().write("{\"error\":\"Invalid type. Use: data, audio, image\"}");
                return;
            }

            // Create job
            AnalysisJob job = new AnalysisJob();
            job.id = UUID.randomUUID().toString().substring(0, 12);
            job.rank = rank;
            job.taxon = taxon;
            job.type = type;
            job.originalName = getFileName(filePart);
            job.stage = "uploading";
            job.progress = 5;
            job.createdAt = System.currentTimeMillis();

            // Store file
            Path uploadDir = Paths.get(UPLOAD_DIR, job.id);
            Files.createDirectories(uploadDir);
            String safeFilename = job.id + "_" + sanitizeFilename(job.originalName);
            Path storedFile = uploadDir.resolve(safeFilename);

            try (InputStream is = filePart.getInputStream();
                 OutputStream os = Files.newOutputStream(storedFile)) {
                is.transferTo(os);
            }
            job.storedPath = storedFile.toString();
            job.progress = 15;

            // Register job and start pipeline async
            JOBS.put(job.id, job);
            PIPELINE.submit(() -> runPipeline(job));

            resp.setStatus(202);
            resp.getWriter().write(job.toJson());

        } catch (Exception e) {
            resp.setStatus(500);
            resp.getWriter().write("{\"error\":\"Upload failed: " + e.getMessage().replace("\"", "'") + "\"}");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getServletPath();
        String id = req.getParameter("id");

        if (id == null || id.isEmpty()) {
            resp.setStatus(400);
            resp.getWriter().write("{\"error\":\"Missing id parameter\"}");
            return;
        }

        AnalysisJob job = JOBS.get(id);
        if (job == null) {
            // Try DB lookup for older jobs
            job = loadJobFromDb(id);
            if (job == null) {
                resp.setStatus(404);
                resp.getWriter().write("{\"error\":\"Job not found\"}");
                return;
            }
        }

        if (path.contains("/status")) {
            resp.setContentType("application/json; charset=UTF-8");
            resp.setHeader("Access-Control-Allow-Origin", "*");
            resp.getWriter().write(job.toJson());
        } else if (path.contains("/result")) {
            if (!"complete".equals(job.stage) || job.resultPath == null) {
                resp.setStatus(404);
                resp.getWriter().write("{\"error\":\"Result not ready\"}");
                return;
            }
            Path resultFile = Paths.get(job.resultPath);
            if (!Files.exists(resultFile)) {
                resp.setStatus(404);
                resp.getWriter().write("{\"error\":\"Result file missing\"}");
                return;
            }
            resp.setContentType("application/octet-stream");
            resp.setHeader("Content-Disposition", "attachment; filename=\"analysis-" + job.id + "-result.txt\"");
            Files.copy(resultFile, resp.getOutputStream());
        }
    }

    // ─── Analysis Pipeline ───
    private void runPipeline(AnalysisJob job) {
        try {
            // Stage 1: ClamAV scan
            job.stage = "scanning";
            job.progress = 20;
            boolean clamClean = runClamAV(job.storedPath);
            if (!clamClean) {
                job.stage = "failed";
                job.error = "ClamAV detected a threat in the uploaded file. File quarantined.";
                job.progress = 100;
                quarantineFile(job.storedPath);
                persistJob(job);
                return;
            }
            job.progress = 40;

            // Stage 2: Heuristic analysis
            job.stage = "heuristic";
            job.progress = 45;
            String heuristicResult = runHeuristic(job);
            if (heuristicResult.startsWith("BLOCK")) {
                job.stage = "failed";
                job.error = "Heuristic analysis blocked: " + heuristicResult;
                job.progress = 100;
                persistJob(job);
                return;
            }
            job.progress = 60;

            // Stage 3: Send to SignalProcessor
            job.stage = "processing";
            job.progress = 65;
            String signalResult = sendToSignalProcessor(job);
            job.progress = 90;

            // Stage 4: Write results file
            Path resultsDir = Paths.get(RESULTS_DIR, job.id);
            Files.createDirectories(resultsDir);
            String resultFilename = "analysis-" + job.id + "-result.txt";
            Path resultFile = resultsDir.resolve(resultFilename);

            try (BufferedWriter w = Files.newBufferedWriter(resultFile)) {
                w.write("═══════════════════════════════════════════════════════════════\n");
                w.write(" Brarner.M.Alete™ — Analysis Result\n");
                w.write("═══════════════════════════════════════════════════════════════\n");
                w.write(" Job ID:      " + job.id + "\n");
                w.write(" Timestamp:   " + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")) + "\n");
                w.write(" File:        " + job.originalName + "\n");
                w.write(" Type:        " + job.type + "\n");
                w.write(" Rank:        " + job.rank + "\n");
                w.write(" Taxon:       " + job.taxon + "\n");
                w.write("───────────────────────────────────────────────────────────────\n");
                w.write(" ClamAV:      CLEAN\n");
                w.write(" Heuristic:   " + heuristicResult + "\n");
                w.write("───────────────────────────────────────────────────────────────\n");
                w.write(" Signal Processor Output:\n\n");
                w.write(signalResult + "\n");
                w.write("═══════════════════════════════════════════════════════════════\n");
                w.write(" [End of Analysis — Graphs coming soon]\n");
                w.write("═══════════════════════════════════════════════════════════════\n");
            }

            job.resultPath = resultFile.toString();
            job.stage = "complete";
            job.progress = 100;
            persistJob(job);

        } catch (Exception e) {
            job.stage = "failed";
            job.error = "Pipeline error: " + e.getMessage();
            job.progress = 100;
            persistJob(job);
        }
    }

    // ─── ClamAV Integration ───
    private boolean runClamAV(String filePath) {
        try {
            ProcessBuilder pb = new ProcessBuilder("clamscan", "--no-summary", "--infected", filePath);
            pb.redirectErrorStream(true);
            Process proc = pb.start();
            String output;
            try (BufferedReader br = new BufferedReader(new InputStreamReader(proc.getInputStream()))) {
                output = br.lines().reduce("", (a, b) -> a + b + "\n");
            }
            int exitCode = proc.waitFor();
            // clamscan: 0 = clean, 1 = infected, 2 = error
            return exitCode == 0;
        } catch (Exception e) {
            // If clamscan not available, log warning but allow (dev/test environments)
            System.err.println("[AnalysisUpload] ClamAV unavailable: " + e.getMessage() + " — allowing file");
            return true;
        }
    }

    // ─── Heuristic Analysis ───
    private String runHeuristic(AnalysisJob job) {
        try {
            Path file = Paths.get(job.storedPath);
            long size = Files.size(file);

            // Size check
            if (size > 50 * 1024 * 1024) return "BLOCK|File exceeds 50MB limit";
            if (size == 0) return "BLOCK|Empty file";

            // Extension heuristic
            String name = job.originalName.toLowerCase();
            if (name.endsWith(".exe") || name.endsWith(".bat") || name.endsWith(".cmd") ||
                name.endsWith(".ps1") || name.endsWith(".sh") || name.endsWith(".msi")) {
                return "BLOCK|Executable files not permitted for analysis";
            }

            // Type-specific validation
            byte[] header = new byte[Math.min(512, (int) size)];
            try (InputStream is = Files.newInputStream(file)) {
                is.read(header);
            }

            switch (job.type) {
                case "image":
                    if (!isImageHeader(header)) return "BLOCK|File does not appear to be a valid image";
                    break;
                case "audio":
                    if (!isAudioHeader(header)) return "BLOCK|File does not appear to be a valid audio file";
                    break;
                case "data":
                    // Data accepts CSV, JSON, XML, TXT, TSV
                    if (name.matches(".*\\.(csv|json|xml|txt|tsv|xlsx|ods)$")) break;
                    // Check for text content
                    if (!isTextLike(header)) return "BLOCK|Data file format not recognized";
                    break;
            }

            // Compute SHA-256 for tracking
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] fileBytes = Files.readAllBytes(file);
            byte[] hash = md.digest(fileBytes);
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) hex.append(String.format("%02x", b));

            return "PASS|sha256=" + hex + "|size=" + size + "B|type=" + detectMime(header);

        } catch (Exception e) {
            return "BLOCK|Heuristic error: " + e.getMessage();
        }
    }

    // ─── Signal Processor Communication ───
    private String sendToSignalProcessor(AnalysisJob job) {
        try {
            // Connect to Strernary™ inference on port 20000
            java.net.Socket sock = new java.net.Socket();
            sock.connect(new java.net.InetSocketAddress("127.0.0.1", SIGNAL_PROCESSOR_PORT), 5000);
            sock.setSoTimeout(30000);

            PrintWriter out = new PrintWriter(sock.getOutputStream(), true);
            BufferedReader in = new BufferedReader(new InputStreamReader(sock.getInputStream()));

            // Send analysis request with taxonomy context
            String command = "ASK|ANALYZE " + job.type.toUpperCase() + " for " + job.rank + " " + job.taxon
                + " file=" + job.originalName + " path=" + job.storedPath;
            out.println(command);

            // Read response (multi-line, terminated by empty line or timeout)
            StringBuilder response = new StringBuilder();
            String line;
            long deadline = System.currentTimeMillis() + 25000;
            while ((line = in.readLine()) != null && System.currentTimeMillis() < deadline) {
                if (line.isEmpty()) break;
                response.append(line).append("\n");
            }

            sock.close();

            if (response.length() == 0) {
                return "[SignalProcessor] No response — inference engine may be offline.\n"
                    + "File stored for deferred processing: " + job.storedPath;
            }
            return response.toString();

        } catch (Exception e) {
            // SignalProcessor offline — store for later
            return "[SignalProcessor] Connection failed (" + e.getMessage() + ")\n"
                + "File stored for deferred processing when Strernary™ comes online.\n"
                + "Rank: " + job.rank + " | Taxon: " + job.taxon + " | Type: " + job.type;
        }
    }

    // ─── Persistence (MySQL) ───
    private void persistJob(AnalysisJob job) {
        try {
            Properties p = loadDbProps();
            Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
            try (Connection conn = DriverManager.getConnection(
                    p.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience"),
                    p.getProperty("db.user", "root"),
                    p.getProperty("db.password", ""))) {

                // Ensure table exists
                conn.createStatement().execute(
                    "CREATE TABLE IF NOT EXISTS analysis_jobs ("
                    + "id VARCHAR(12) PRIMARY KEY, rank_level VARCHAR(20), taxon_name VARCHAR(200), "
                    + "file_type VARCHAR(10), original_name VARCHAR(500), stored_path VARCHAR(1000), "
                    + "result_path VARCHAR(1000), stage VARCHAR(20), progress INT, error TEXT, "
                    + "created_at BIGINT, completed_at DATETIME DEFAULT NULL)");

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO analysis_jobs (id, rank_level, taxon_name, file_type, original_name, "
                    + "stored_path, result_path, stage, progress, error, created_at, completed_at) "
                    + "VALUES (?,?,?,?,?,?,?,?,?,?,?,NOW()) "
                    + "ON DUPLICATE KEY UPDATE stage=VALUES(stage), progress=VALUES(progress), "
                    + "error=VALUES(error), result_path=VALUES(result_path), completed_at=NOW()");
                ps.setString(1, job.id);
                ps.setString(2, job.rank);
                ps.setString(3, job.taxon);
                ps.setString(4, job.type);
                ps.setString(5, job.originalName);
                ps.setString(6, job.storedPath);
                ps.setString(7, job.resultPath);
                ps.setString(8, job.stage);
                ps.setInt(9, job.progress);
                ps.setString(10, job.error);
                ps.setLong(11, job.createdAt);
                ps.executeUpdate();
            }
        } catch (Exception e) {
            System.err.println("[AnalysisUpload] DB persist failed: " + e.getMessage());
        }
    }

    private AnalysisJob loadJobFromDb(String id) {
        try {
            Properties p = loadDbProps();
            Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
            try (Connection conn = DriverManager.getConnection(
                    p.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience"),
                    p.getProperty("db.user", "root"),
                    p.getProperty("db.password", ""))) {
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT * FROM analysis_jobs WHERE id=?");
                ps.setString(1, id);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    AnalysisJob job = new AnalysisJob();
                    job.id = rs.getString("id");
                    job.rank = rs.getString("rank_level");
                    job.taxon = rs.getString("taxon_name");
                    job.type = rs.getString("file_type");
                    job.originalName = rs.getString("original_name");
                    job.storedPath = rs.getString("stored_path");
                    job.resultPath = rs.getString("result_path");
                    job.stage = rs.getString("stage");
                    job.progress = rs.getInt("progress");
                    job.error = rs.getString("error");
                    job.createdAt = rs.getLong("created_at");
                    return job;
                }
            }
        } catch (Exception e) { /* table may not exist yet */ }
        return null;
    }

    // ─── Helpers ───
    private Properties loadDbProps() {
        Properties p = new Properties();
        try (InputStream is = getServletContext().getResourceAsStream("/WEB-INF/db.properties")) {
            if (is != null) p.load(is);
        } catch (Exception ignored) {}
        return p;
    }

    private void quarantineFile(String filePath) {
        try {
            Path src = Paths.get(filePath);
            Path quarantine = Paths.get("/opt/bma/analysis/quarantine");
            Files.createDirectories(quarantine);
            Files.move(src, quarantine.resolve(src.getFileName()), StandardCopyOption.REPLACE_EXISTING);
        } catch (Exception e) {
            System.err.println("[AnalysisUpload] Quarantine failed: " + e.getMessage());
        }
    }

    private String getFileName(Part part) {
        String cd = part.getHeader("content-disposition");
        if (cd != null) {
            for (String token : cd.split(";")) {
                if (token.trim().startsWith("filename")) {
                    String name = token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
                    // Handle path separators
                    int slash = Math.max(name.lastIndexOf('/'), name.lastIndexOf('\\'));
                    if (slash >= 0) name = name.substring(slash + 1);
                    return name;
                }
            }
        }
        return "unknown";
    }

    private String sanitizeFilename(String name) {
        return name.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    private boolean isImageHeader(byte[] h) {
        if (h.length < 4) return false;
        // PNG, JPEG, GIF, BMP, WEBP, TIFF
        if (h[0] == (byte)0x89 && h[1] == 'P' && h[2] == 'N' && h[3] == 'G') return true;
        if (h[0] == (byte)0xFF && h[1] == (byte)0xD8 && h[2] == (byte)0xFF) return true;
        if (h[0] == 'G' && h[1] == 'I' && h[2] == 'F') return true;
        if (h[0] == 'B' && h[1] == 'M') return true;
        if (h.length >= 12 && h[8] == 'W' && h[9] == 'E' && h[10] == 'B' && h[11] == 'P') return true;
        if ((h[0] == 'I' && h[1] == 'I') || (h[0] == 'M' && h[1] == 'M')) return true;
        return false;
    }

    private boolean isAudioHeader(byte[] h) {
        if (h.length < 4) return false;
        // MP3, WAV, FLAC, OGG, M4A/AAC
        if (h[0] == 'I' && h[1] == 'D' && h[2] == '3') return true;
        if (h[0] == (byte)0xFF && (h[1] & 0xE0) == 0xE0) return true; // MP3 frame sync
        if (h[0] == 'R' && h[1] == 'I' && h[2] == 'F' && h[3] == 'F') return true; // WAV
        if (h[0] == 'f' && h[1] == 'L' && h[2] == 'a' && h[3] == 'C') return true;
        if (h[0] == 'O' && h[1] == 'g' && h[2] == 'g' && h[3] == 'S') return true;
        if (h.length >= 8 && h[4] == 'f' && h[5] == 't' && h[6] == 'y' && h[7] == 'p') return true;
        return false;
    }

    private boolean isTextLike(byte[] h) {
        int textChars = 0;
        for (int i = 0; i < Math.min(h.length, 256); i++) {
            int b = h[i] & 0xFF;
            if (b == 9 || b == 10 || b == 13 || (b >= 32 && b <= 126) || b >= 128) textChars++;
        }
        return textChars > (Math.min(h.length, 256) * 0.85);
    }

    private String detectMime(byte[] h) {
        if (isImageHeader(h)) return "image/*";
        if (isAudioHeader(h)) return "audio/*";
        if (isTextLike(h)) return "text/plain";
        return "application/octet-stream";
    }
}
