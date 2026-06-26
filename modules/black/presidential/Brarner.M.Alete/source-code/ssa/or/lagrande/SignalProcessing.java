package ssa.or.lagrande;

import com.github.psambit9791.jdsp.transform.FastFourier;
import java.io.*;
import java.net.*;
import java.sql.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

/**
 * Signal Processing for SSA Office: LA GRANDE OR
 * <p>Office Code: 936</p>
 * <p>Address: 2205 COVE AVE, LA GRANDE, OR 97850</p>
 * <p>Phone: (888) 810-7611 | Fax: (833) 950-2916</p>
 */
public class SignalProcessing
{
    private static String dataSource, dataOutput, socketHost, localInputPath, dbUrl, dbUser, dbPass, outputDir;
    private static int socketPort;

    static { loadConfig("source-code/ssa/or/lagrande/config.xml"); }

    private static void loadConfig(String path) {
        try {
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new File(path));
            doc.getDocumentElement().normalize();
            dataSource = getTag(doc, "data-source"); dataOutput = getTag(doc, "data-output");
            socketHost = getTag(doc, "socket-host"); socketPort = Integer.parseInt(getTag(doc, "socket-port"));
            localInputPath = getTag(doc, "local-input-path"); dbUrl = getTag(doc, "db-url");
            dbUser = getTag(doc, "db-user"); dbPass = getTag(doc, "db-pass"); outputDir = getTag(doc, "output-dir");
        } catch (Exception e) {
            dataSource = "local"; dataOutput = "both"; socketHost = "localhost";
            socketPort = 10318; localInputPath = "."; dbUrl = "jdbc:mysql://localhost:3306/Science";
            dbUser = "root"; dbPass = ""; outputDir = "output/ssa/or/lagrande";
        }
    }

    private static String getTag(Document doc, String tag) {
        NodeList nl = doc.getElementsByTagName(tag);
        return nl.getLength() > 0 ? nl.item(0).getTextContent().trim() : "";
    }

    private static double[] readData() throws Exception {
        if ("socket".equals(dataSource)) {
            try (Socket sock = new Socket(socketHost, socketPort);
                 DataInputStream dis = new DataInputStream(sock.getInputStream())) {
                int len = dis.readInt(); double[] data = new double[len];
                for (int i = 0; i < len; i++) data[i] = dis.readDouble(); return data;
            }
        } else {
            BufferedReader br = new BufferedReader(new FileReader(localInputPath));
            return br.lines().mapToDouble(Double::parseDouble).toArray();
        }
    }

    private static void writeToFile(String filename, String content) throws Exception {
        File f = new File(outputDir, filename + ".rdns"); f.getParentFile().mkdirs();
        try (FileWriter fw = new FileWriter(f)) { fw.write(content); }
    }

    private static void writeToDatabase(String table, String expName, String data) throws Exception {
        try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO experiments (experiment_name, experiment_data) VALUES (?, ?)")) {
            ps.setString(1, expName); ps.setString(2, data); ps.executeUpdate();
        }
    }

    private static void output(String filename, String expName, String content) throws Exception {
        if ("file".equals(dataOutput) || "both".equals(dataOutput)) writeToFile(filename, content);
        if ("database".equals(dataOutput) || "both".equals(dataOutput)) writeToDatabase("experiments", expName, content);
    }

    public static class Audio {
        public static void process() throws Exception {
            double[] raw = readData(); FastFourier fft = new FastFourier(raw); fft.transform();
            double[] mag = fft.getMagnitude(true); StringBuilder sb = new StringBuilder();
            for (double v : mag) sb.append(v).append("\n");
            output("ssa_or/lagrande_audio", "ssa.or.lagrande.audio.fft", sb.toString());
        }
    }

    public static class Data {
        public static void process() throws Exception {
            double[] raw = readData(); double sum = 0; for (double v : raw) sum += v;
            double mean = sum / raw.length; double var = 0;
            for (double v : raw) var += (v - mean) * (v - mean); var /= raw.length;
            output("ssa_or/lagrande_data", "ssa.or.lagrande.data.stats", "mean=" + mean + "\nvariance=" + var + "\nn=" + raw.length + "\n");
        }
    }

    public static class Graphics {
        public static void process() throws Exception {
            double[] raw = readData(); FastFourier fft = new FastFourier(raw); fft.transform();
            double[] mag = fft.getMagnitude(true); StringBuilder sb = new StringBuilder("x,y\n");
            for (int i = 0; i < mag.length; i++) sb.append(i).append(",").append(mag[i]).append("\n");
            output("ssa_or/lagrande_graphics", "ssa.or.lagrande.graphics.spectrum", sb.toString());
        }
    }
}