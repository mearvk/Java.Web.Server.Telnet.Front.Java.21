/**
 * AudioSampler — D44 plugin that connects to audio streams,
 * samples data inline, and analyzes the signal.
 * Results stored in analyze.results.xml.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package calendar.d44;

import javax.sound.sampled.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.time.Instant;

public class AudioSampler
{
    private final int sampleRate;
    private final int sampleSizeBits;
    private final int channels;
    private final int bufferSize;
    private final String resultsFile;

    /**
     * Constructs AudioSampler with the given audio parameters.
     *
     * @param sampleRate sample rate in Hz (e.g. 44100)
     * @param sampleSizeBits bits per sample (e.g. 16)
     * @param channels mono=1, stereo=2
     * @param bufferSize read buffer size in bytes
     * @param resultsFile path to analyze.results.xml
     * @javaowner Max Rupplin
     */
    public AudioSampler(int sampleRate, int sampleSizeBits, int channels, int bufferSize, String resultsFile)
    {
        this.sampleRate = sampleRate;
        this.sampleSizeBits = sampleSizeBits;
        this.channels = channels;
        this.bufferSize = bufferSize;
        this.resultsFile = resultsFile;
    }

    /**
     * Default constructor using d44-config.xml defaults.
     *
     * @javaowner Max Rupplin
     */
    public AudioSampler()
    {
        this(44100, 16, 2, 4096, "source/calendar/d44/analyze.results.xml");
    }

    /**
     * Connects to an audio stream URL, samples data, and analyzes.
     *
     * @param streamUrl URL of the audio stream
     * @param durationMs how long to sample in milliseconds
     * @return analysis result
     * @javaowner Max Rupplin
     */
    public AnalysisResult sampleStream(String streamUrl, long durationMs)
    {
        try
        {
            URLConnection conn = new URL(streamUrl).openConnection();
            conn.setConnectTimeout(10000);
            conn.setReadTimeout((int) durationMs + 5000);

            InputStream rawStream = conn.getInputStream();
            AudioFormat format = new AudioFormat(sampleRate, sampleSizeBits, channels, true, false);

            byte[] buffer = new byte[bufferSize];
            long totalBytes = 0;
            double peakAmplitude = 0;
            double rmsSum = 0;
            int sampleCount = 0;
            long startTime = System.currentTimeMillis();

            while (System.currentTimeMillis() - startTime < durationMs)
            {
                int read = rawStream.read(buffer, 0, buffer.length);
                if (read <= 0) break;
                totalBytes += read;

                // Analyze samples (16-bit signed little-endian)
                for (int i = 0; i + 1 < read; i += 2)
                {
                    short sample = (short) ((buffer[i] & 0xFF) | (buffer[i + 1] << 8));
                    double amplitude = Math.abs(sample) / 32768.0;
                    if (amplitude > peakAmplitude) peakAmplitude = amplitude;
                    rmsSum += amplitude * amplitude;
                    sampleCount++;
                }
            }

            rawStream.close();

            double rms = sampleCount > 0 ? Math.sqrt(rmsSum / sampleCount) : 0;
            double durationActual = (System.currentTimeMillis() - startTime) / 1000.0;

            AnalysisResult result = new AnalysisResult(streamUrl, totalBytes, sampleCount,
                peakAmplitude, rms, durationActual, Instant.now().toString());

            writeResults(result);
            return result;
        }
        catch (Exception e)
        {
            System.err.println("[AudioSampler] Stream sample failed: " + e.getMessage());
            return null;
        }
    }

    /**
     * Samples from the local microphone/line-in.
     *
     * @param durationMs how long to sample
     * @return analysis result
     * @javaowner Max Rupplin
     */
    public AnalysisResult sampleLocal(long durationMs)
    {
        try
        {
            AudioFormat format = new AudioFormat(sampleRate, sampleSizeBits, channels, true, false);
            DataLine.Info info = new DataLine.Info(TargetDataLine.class, format);
            TargetDataLine line = (TargetDataLine) AudioSystem.getLine(info);
            line.open(format, bufferSize);
            line.start();

            byte[] buffer = new byte[bufferSize];
            long totalBytes = 0;
            double peakAmplitude = 0;
            double rmsSum = 0;
            int sampleCount = 0;
            long startTime = System.currentTimeMillis();

            while (System.currentTimeMillis() - startTime < durationMs)
            {
                int read = line.read(buffer, 0, buffer.length);
                if (read <= 0) break;
                totalBytes += read;

                for (int i = 0; i + 1 < read; i += 2)
                {
                    short sample = (short) ((buffer[i] & 0xFF) | (buffer[i + 1] << 8));
                    double amplitude = Math.abs(sample) / 32768.0;
                    if (amplitude > peakAmplitude) peakAmplitude = amplitude;
                    rmsSum += amplitude * amplitude;
                    sampleCount++;
                }
            }

            line.stop();
            line.close();

            double rms = sampleCount > 0 ? Math.sqrt(rmsSum / sampleCount) : 0;
            double durationActual = (System.currentTimeMillis() - startTime) / 1000.0;

            AnalysisResult result = new AnalysisResult("local://microphone", totalBytes, sampleCount,
                peakAmplitude, rms, durationActual, Instant.now().toString());

            writeResults(result);
            return result;
        }
        catch (Exception e)
        {
            System.err.println("[AudioSampler] Local sample failed: " + e.getMessage());
            return null;
        }
    }

    /**
     * Writes analysis results to analyze.results.xml.
     *
     * @javaowner Max Rupplin
     */
    private void writeResults(AnalysisResult result)
    {
        try
        {
            File file = new File(resultsFile);
            boolean append = file.exists() && file.length() > 0;

            // If new file, write XML header
            if (!append)
            {
                try (FileWriter fw = new FileWriter(file))
                {
                    fw.write("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
                    fw.write("<analyze-results>\n");
                    fw.write(result.toXml());
                    fw.write("</analyze-results>\n");
                }
            }
            else
            {
                // Insert before closing tag
                RandomAccessFile raf = new RandomAccessFile(file, "rw");
                long pos = raf.length() - "</analyze-results>\n".length();
                if (pos < 0) pos = raf.length();
                raf.seek(pos);
                raf.writeBytes(result.toXml());
                raf.writeBytes("</analyze-results>\n");
                raf.close();
            }
        }
        catch (IOException e)
        {
            System.err.println("[AudioSampler] Write results failed: " + e.getMessage());
        }
    }

    /**
     * Analysis result record.
     *
     * @javaowner Max Rupplin
     */
    public static class AnalysisResult
    {
        public final String source;
        public final long totalBytes;
        public final int sampleCount;
        public final double peakAmplitude;
        public final double rms;
        public final double durationSeconds;
        public final String timestamp;

        public AnalysisResult(String source, long totalBytes, int sampleCount,
                              double peakAmplitude, double rms, double durationSeconds, String timestamp)
        {
            this.source = source;
            this.totalBytes = totalBytes;
            this.sampleCount = sampleCount;
            this.peakAmplitude = peakAmplitude;
            this.rms = rms;
            this.durationSeconds = durationSeconds;
            this.timestamp = timestamp;
        }

        /** @javaowner Max Rupplin */
        public String toXml()
        {
            return String.format(
                "    <result>\n" +
                "        <source>%s</source>\n" +
                "        <total-bytes>%d</total-bytes>\n" +
                "        <sample-count>%d</sample-count>\n" +
                "        <peak-amplitude>%.6f</peak-amplitude>\n" +
                "        <rms>%.6f</rms>\n" +
                "        <duration-seconds>%.3f</duration-seconds>\n" +
                "        <timestamp>%s</timestamp>\n" +
                "    </result>\n",
                source, totalBytes, sampleCount, peakAmplitude, rms, durationSeconds, timestamp);
        }
    }
}
