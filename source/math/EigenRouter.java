package math;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;

/**
 * EigenRouter — Routes national input vectors from BasicAnatomy (EV) through
 * to PerceivedOutput (PO) via a programmable frame-hop pipeline.
 *
 * Architecture:
 *   Input → BasicAnatomy × input → [Frame Pipeline] → PerceivedOutput × result → Output
 *
 * Frame Pipeline:
 *   - Between 4 and 51 frames of ricochet / hot-action space
 *   - Max 4 forward multipliers before pipeline
 *   - Max 51 total hops to total forward distance
 *   - Each frame may link forward 1–4, 6, or skip up to 16 frames
 *   - Paths that are orderly (same w.r.t. All spirits) pass through unchanged
 *   - Paths that achieve their own virtue transform independently
 *   - Colors assigned to results by higher math authority (Max Rupplin)
 *
 * Observation sources: math/observations/ (national values, angular, momentum, rain)
 * Frame programs: math/frames/ (user-programmable hop definitions)
 *
 * Frame file format (.frame):
 *   # Frame N
 *   hop=4          (jump forward 4 frames)
 *   link=next      (link output to next frame input)
 *   transform=scale:1.2   (optional per-frame transform)
 *
 * Color assignment is reserved for higher math geniuses (Max Rupplin).
 */
public class EigenRouter {

    private static final String CONFIG_PATH = "math/eigen-config.xml";
    private static final String FRAMES_DIR = "math/frames";
    private static final int MIN_FRAMES = 4;
    private static final int MAX_FRAMES = 65;
    private static final int MAX_FORWARD_MULTIPLIERS = 4;
    private static final int MAX_SKIP = 16;
    private static final int[] STANDARD_HOPS = {1, 2, 3, 4, 6};
    private static final int PROC_FRAME_START = 2;
    private static final int PROC_FRAME_END = 65;
    private static final int MAX_FRAME_ROWS = 4000;
    private static final int MAX_FRAME_COLS = 12800;
    private static final int MIN_FRAME_DIM = 128;

    private double[][] basicAnatomy;
    private double[][] perceivedOutput;
    private List<Frame> frames = new ArrayList<>();

    public static void main(String... args) throws Exception {
        EigenRouter router = new EigenRouter();
        router.loadMatrices();
        router.loadFrames();

        String obsDir = "math/observations";
        String outDir = "math/results";
        new File(outDir).mkdirs();

        File[] files = new File(obsDir).listFiles((d, n) -> !n.startsWith("."));
        if (files == null || files.length == 0) {
            System.out.println("[EigenRouter] No observations in " + obsDir);
            return;
        }

        for (File f : files) {
            router.route(f.toPath(), Path.of(outDir, f.getName() + ".routed"));
        }
    }

    private void loadMatrices() throws Exception {
        basicAnatomy = parseCDNS(Path.of("math/eigenlocator/BasicAnatomy.CDNS"), "BasicAnatomy");
        perceivedOutput = parseCDNS(Path.of("math/eigenlocator/PerceivedOutput.CDNS"), "PerceivedOutput");
        System.out.println("[EigenRouter] Loaded BasicAnatomy (5x5) and PerceivedOutput (5x5)");
    }

    private void loadFrames() throws IOException {
        File dir = new File(FRAMES_DIR);
        dir.mkdirs();
        File[] frameFiles = dir.listFiles((d, n) -> n.endsWith(".frame"));

        if (frameFiles == null || frameFiles.length == 0) {
            // Default: generate minimal 4-frame pipeline
            System.out.println("[EigenRouter] No .frame files — using default 4-frame pipeline");
            for (int i = 0; i < MIN_FRAMES; i++) {
                frames.add(new Frame(i, 1, "passthrough", null));
            }
        } else {
            Arrays.sort(frameFiles, Comparator.comparing(File::getName));
            for (File f : frameFiles) {
                frames.add(parseFrame(f));
            }
        }

        if (frames.size() < MIN_FRAMES) frames.addAll(Collections.nCopies(MIN_FRAMES - frames.size(),
                new Frame(frames.size(), 1, "passthrough", null)));
        if (frames.size() > MAX_FRAMES) frames = frames.subList(0, MAX_FRAMES);

        System.out.println("[EigenRouter] Pipeline: " + frames.size() + " frames");
    }

    private void route(Path input, Path output) throws Exception {
        System.out.println("[EigenRouter] Routing: " + input.getFileName());
        List<String> lines = Files.readAllLines(input);
        StringBuilder out = new StringBuilder();
        out.append("# EigenRouter: BasicAnatomy → [").append(frames.size())
           .append(" frames] → PerceivedOutput\n");
        out.append("# Source: ").append(input.getFileName()).append("\n");
        out.append("# Color: [reserved — assigned by Max Rupplin]\n\n");

        for (String line : lines) {
            String trimmed = line.trim();
            if (trimmed.isEmpty() || trimmed.startsWith("#")) continue;

            double[] vec = parseVector(trimmed);
            if (vec.length != 5) continue;

            // Stage 1: BasicAnatomy × input (up to MAX_FORWARD_MULTIPLIERS passes)
            double[] current = vec;
            int multiplierPasses = Math.min(MAX_FORWARD_MULTIPLIERS, countOrderlyPaths(vec));
            for (int m = 0; m < multiplierPasses; m++) {
                current = multiply(basicAnatomy, current);
            }

            // Stage 2: Frame pipeline (ricochet / hot-action)
            int frameIdx = 0;
            int totalHops = 0;
            while (frameIdx < frames.size() && totalHops < MAX_FRAMES) {
                Frame frame = frames.get(frameIdx);
                current = frame.apply(current);
                int hop = Math.min(frame.hop, MAX_SKIP);
                frameIdx += hop;
                totalHops += hop;
            }

            // Stage 3: PerceivedOutput × result
            double[] result = multiply(perceivedOutput, current);

            out.append(formatVector(result)).append("\n");
        }

        Files.writeString(output, out.toString());
        System.out.println("[EigenRouter] Output: " + output);
    }

    /**
     * Count paths that are orderly (same w.r.t. All spirits) —
     * symmetric or repeating elements suggest orderly routing.
     */
    private int countOrderlyPaths(double[] vec) {
        int orderly = 0;
        for (int i = 0; i < vec.length - 1; i++) {
            if (vec[i] == vec[i + 1]) orderly++;
        }
        return Math.max(1, Math.min(orderly + 1, MAX_FORWARD_MULTIPLIERS));
    }

    private double[] multiply(double[][] matrix, double[] vec) {
        double[] result = new double[matrix.length];
        for (int i = 0; i < matrix.length; i++)
            for (int j = 0; j < vec.length; j++)
                result[i] += matrix[i][j] * vec[j];
        return result;
    }

    private double[][] parseCDNS(Path file, String name) throws IOException {
        List<double[]> rows = new ArrayList<>();
        boolean inside = false;
        for (String line : Files.readAllLines(file)) {
            String t = line.trim();
            if (t.equals("[EV:" + name + "]")) { inside = true; continue; }
            if (t.equals("[/EV:" + name + "]")) break;
            if (inside && !t.isEmpty() && !t.startsWith("#")) {
                String[] parts = t.split("\\s+");
                double[] row = new double[parts.length];
                for (int i = 0; i < parts.length; i++) row[i] = Double.parseDouble(parts[i]);
                rows.add(row);
            }
        }
        return rows.toArray(new double[0][]);
    }

    private Frame parseFrame(File f) throws IOException {
        int idx = 0; int hop = 1; String transform = "passthrough"; String link = null;
        int rows = 0; int cols = 0; String matrixFile = null;
        for (String line : Files.readAllLines(f.toPath())) {
            String t = line.trim();
            if (t.startsWith("index=")) idx = Integer.parseInt(t.substring(6));
            else if (t.startsWith("hop=")) hop = clampHop(Integer.parseInt(t.substring(4)));
            else if (t.startsWith("transform=")) transform = t.substring(10);
            else if (t.startsWith("link=")) link = t.substring(5);
            else if (t.startsWith("rows=")) rows = Math.min(Integer.parseInt(t.substring(5)), MAX_FRAME_ROWS);
            else if (t.startsWith("cols=")) cols = Math.min(Integer.parseInt(t.substring(5)), MAX_FRAME_COLS);
            else if (t.startsWith("matrix=")) matrixFile = t.substring(7);
        }
        if (rows > 0 && rows < MIN_FRAME_DIM) rows = MIN_FRAME_DIM;
        if (cols > 0 && cols < MIN_FRAME_DIM) cols = MIN_FRAME_DIM;
        Frame frame = new Frame(idx, hop, transform, link, rows, cols);
        if (matrixFile != null) {
            Path mp = Path.of(FRAMES_DIR, matrixFile);
            if (Files.exists(mp)) frame.procMatrix = loadProcMatrix(mp, rows, cols);
        }
        return frame;
    }

    private double[][] loadProcMatrix(Path path, int maxRows, int maxCols) throws IOException {
        List<double[]> rows = new ArrayList<>();
        for (String line : Files.readAllLines(path)) {
            String t = line.trim();
            if (t.isEmpty() || t.startsWith("#")) continue;
            if (rows.size() >= maxRows) break;
            String[] parts = t.split("\\s+");
            int len = Math.min(parts.length, maxCols);
            double[] row = new double[len];
            for (int i = 0; i < len; i++) row[i] = Double.parseDouble(parts[i]);
            rows.add(row);
        }
        return rows.toArray(new double[0][]);
    }

    private int clampHop(int hop) {
        if (hop >= 1 && hop <= 4) return hop;
        if (hop == 6) return 6;
        if (hop > 6 && hop <= MAX_SKIP) return hop;
        return 1;
    }

    private double[] parseVector(String line) {
        String[] p = line.split("\\s+");
        double[] v = new double[p.length];
        for (int i = 0; i < p.length; i++) v[i] = Double.parseDouble(p[i]);
        return v;
    }

    private String formatVector(double[] v) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < v.length; i++) {
            if (i > 0) sb.append("  ");
            sb.append(String.format("%.4f", v[i]));
        }
        return sb.toString();
    }

    /** A single frame in the ricochet/hot-action pipeline. */
    static class Frame {
        final int index;
        final int hop;         // 1-4, 6, or up to 16
        final String transform; // passthrough, scale:N, rotate:N, etc.
        final String link;      // null, "next", or frame index to link to
        final int rows;         // procedure frame rows (128–4000), specified at user build
        final int cols;         // procedure frame cols (128–12800), specified at user build
        double[][] procMatrix;  // user-built procedure matrix (null if passthrough)

        Frame(int index, int hop, String transform, String link) {
            this(index, hop, transform, link, 0, 0);
        }

        Frame(int index, int hop, String transform, String link, int rows, int cols) {
            this.index = index;
            this.hop = hop;
            this.transform = transform;
            this.link = link;
            this.rows = rows;
            this.cols = cols;
        }

        double[] apply(double[] vec) {
            // Procedure frames (2–65): if user-built matrix exists, multiply through it
            if (procMatrix != null && index >= PROC_FRAME_START && index <= PROC_FRAME_END) {
                // Pad or truncate input vector to match procMatrix cols
                double[] input = new double[procMatrix[0].length];
                System.arraycopy(vec, 0, input, 0, Math.min(vec.length, input.length));
                double[] result = new double[procMatrix.length];
                for (int i = 0; i < procMatrix.length; i++)
                    for (int j = 0; j < input.length; j++)
                        result[i] += procMatrix[i][j] * input[j];
                return result;
            }
            if (transform == null || transform.equals("passthrough")) return vec;
            if (transform.startsWith("scale:")) {
                double factor = Double.parseDouble(transform.substring(6));
                double[] r = new double[vec.length];
                for (int i = 0; i < vec.length; i++) r[i] = vec[i] * factor;
                return r;
            }
            // Extensible: additional transforms defined by higher math authority
            return vec;
        }
    }
}
