package math;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;

/**
 * EigenMultiplier — Reads national observation vectors from math/observations/
 * and multiplies them through Eigenvector matrices defined in .CDNS files.
 *
 * Usage: java math.EigenMultiplier [observation-file]
 *   If no file specified, processes all files in observations directory.
 *
 * Observation file format (one vector per line, space-separated):
 *   1.0 2.0 3.0 4.0 5.0
 *
 * Output: resultant vector after matrix multiplication (Ax = y)
 */
public class EigenMultiplier {

    private static final String CONFIG_PATH = "math/eigen-config.xml";

    private String eigenlocatorDir;
    private String observationsDir;
    private String outputDir;
    private final Map<String, double[][]> matrices = new LinkedHashMap<>();

    public static void main(String... args) throws Exception {
        EigenMultiplier em = new EigenMultiplier();
        em.loadConfig();
        em.loadMatrices();

        if (args.length > 0) {
            em.processObservation(Path.of(em.observationsDir, args[0]));
        } else {
            em.processAllObservations();
        }
    }

    private void loadConfig() throws Exception {
        Document doc = DocumentBuilderFactory.newInstance()
                .newDocumentBuilder().parse(new File(CONFIG_PATH));
        doc.getDocumentElement().normalize();

        eigenlocatorDir = doc.getElementsByTagName("eigenlocator-dir").item(0).getTextContent();
        observationsDir = doc.getElementsByTagName("observations-dir").item(0).getTextContent();
        outputDir = doc.getElementsByTagName("output-dir").item(0).getTextContent();

        new File(outputDir).mkdirs();
    }

    private void loadMatrices() throws Exception {
        File dir = new File(eigenlocatorDir);
        for (File f : dir.listFiles((d, n) -> n.endsWith(".CDNS"))) {
            parseCDNS(f);
        }
        System.out.println("[EigenMultiplier] Loaded " + matrices.size() + " matrix(es)");
    }

    private void parseCDNS(File file) throws IOException {
        List<String> lines = Files.readAllLines(file.toPath());
        String name = null;
        List<double[]> rows = new ArrayList<>();

        for (String line : lines) {
            String trimmed = line.trim();
            if (trimmed.startsWith("[EV:") && !trimmed.startsWith("[/EV:")) {
                name = trimmed.substring(4, trimmed.length() - 1);
                rows.clear();
            } else if (trimmed.startsWith("[/EV:")) {
                if (name != null && !rows.isEmpty()) {
                    matrices.put(name, rows.toArray(new double[0][]));
                }
                name = null;
            } else if (name != null && !trimmed.isEmpty() && !trimmed.startsWith("#")) {
                String[] parts = trimmed.split("\\s+");
                double[] row = new double[parts.length];
                for (int i = 0; i < parts.length; i++) row[i] = Double.parseDouble(parts[i]);
                rows.add(row);
            }
        }
    }

    private void processAllObservations() throws Exception {
        File dir = new File(observationsDir);
        File[] files = dir.listFiles((d, n) -> !n.startsWith("."));
        if (files == null || files.length == 0) {
            System.out.println("[EigenMultiplier] No observation files in " + observationsDir);
            return;
        }
        for (File f : files) {
            processObservation(f.toPath());
        }
    }

    private void processObservation(Path obsPath) throws Exception {
        if (!Files.exists(obsPath)) {
            System.err.println("[EigenMultiplier] Not found: " + obsPath);
            return;
        }

        System.out.println("[EigenMultiplier] Processing: " + obsPath.getFileName());
        List<String> lines = Files.readAllLines(obsPath);
        StringBuilder output = new StringBuilder();
        output.append("# Results for: ").append(obsPath.getFileName()).append("\n");

        for (Map.Entry<String, double[][]> entry : matrices.entrySet()) {
            String matName = entry.getKey();
            double[][] matrix = entry.getValue();
            output.append("# Matrix: ").append(matName).append("\n");

            for (String line : lines) {
                String trimmed = line.trim();
                if (trimmed.isEmpty() || trimmed.startsWith("#")) continue;

                double[] vec = parseVector(trimmed);
                if (vec.length != matrix[0].length) {
                    output.append("# ERROR: vector length ").append(vec.length)
                          .append(" != matrix cols ").append(matrix[0].length).append("\n");
                    continue;
                }

                double[] result = multiply(matrix, vec);
                output.append(formatVector(result)).append("\n");
            }
        }

        Path outPath = Path.of(outputDir, obsPath.getFileName().toString() + ".result");
        Files.writeString(outPath, output.toString());
        System.out.println("[EigenMultiplier] Output: " + outPath);
    }

    private double[] multiply(double[][] matrix, double[] vec) {
        double[] result = new double[matrix.length];
        for (int i = 0; i < matrix.length; i++) {
            for (int j = 0; j < vec.length; j++) {
                result[i] += matrix[i][j] * vec[j];
            }
        }
        return result;
    }

    private double[] parseVector(String line) {
        String[] parts = line.trim().split("\\s+");
        double[] v = new double[parts.length];
        for (int i = 0; i < parts.length; i++) v[i] = Double.parseDouble(parts[i]);
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
}
