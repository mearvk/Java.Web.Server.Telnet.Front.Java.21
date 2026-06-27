package video.analysis;

import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.downloader.response.Response;
import com.github.kiulian.downloader.model.videos.VideoDetails;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.Format;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * YouTubeFilter - Downloads YouTube video content and stores it as analyzable .data files.
 *
 * Output: /source-code/data/NAME.DATE.data
 *
 * The .data file contains video metadata and raw byte content suitable for
 * signal processing analysis by the platform's SignalProcessing instances.
 */
public class YouTubeFilter
{
    private static final String DATA_OUTPUT_DIR = "source-code/data";
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    private final YoutubeDownloader downloader;
    private final Path outputDir;

    public YouTubeFilter()
    {
        this.downloader = new YoutubeDownloader();
        this.outputDir = Paths.get(DATA_OUTPUT_DIR);

        try { Files.createDirectories(outputDir); }
        catch (IOException e) { throw new RuntimeException("Cannot create output directory: " + outputDir, e); }
    }

    /**
     * Downloads and filters a YouTube video into an analyzable .data file.
     *
     * @param videoUrl full YouTube URL or video ID
     * @return Path to the generated .data file
     */
    public Path filter(String videoUrl) throws Exception
    {
        String videoId = extractVideoId(videoUrl);

        // Fetch video info
        Response<VideoInfo> response = downloader.getVideoInfo(new RequestVideoInfo(videoId));
        if (!response.ok()) throw new Exception("Failed to get video info for: " + videoId);

        VideoInfo videoInfo = response.data();
        VideoDetails details = videoInfo.details();

        // Determine best available format (prefer audio for signal analysis)
        Format selectedFormat = videoInfo.bestAudioFormat();
        if (selectedFormat == null) selectedFormat = videoInfo.bestVideoFormat();
        if (selectedFormat == null) throw new Exception("No downloadable format found for: " + videoId);

        // Download to temp file
        Path tempDir = Files.createTempDirectory("ytfilter");
        RequestVideoFileDownload downloadRequest = new RequestVideoFileDownload(selectedFormat)
                .saveTo(tempDir.toFile());

        Response<File> downloadResponse = downloader.downloadVideoFile(downloadRequest);
        if (!downloadResponse.ok()) throw new Exception("Download failed for: " + videoId);

        File downloadedFile = downloadResponse.data();

        // Build output filename: NAME.DATE.data
        String safeName = sanitizeName(details.title());
        String date = LocalDate.now().format(DATE_FORMAT);
        String outputFilename = safeName + "." + date + ".data";
        Path outputPath = outputDir.resolve(outputFilename);

        // Write analyzable .data file (header + raw bytes)
        try (DataOutputStream dos = new DataOutputStream(new FileOutputStream(outputPath.toFile())))
        {
            // Header section
            dos.writeBytes("# YouTube Analysis Data File\n");
            dos.writeBytes("# Title: " + details.title() + "\n");
            dos.writeBytes("# Author: " + details.author() + "\n");
            dos.writeBytes("# VideoID: " + videoId + "\n");
            dos.writeBytes("# Duration: " + details.lengthSeconds() + "s\n");
            dos.writeBytes("# Format: " + selectedFormat.mimeType() + "\n");
            dos.writeBytes("# Bitrate: " + selectedFormat.bitrate() + "\n");
            dos.writeBytes("# ContentLength: " + selectedFormat.contentLength() + "\n");
            dos.writeBytes("# Date: " + date + "\n");
            dos.writeBytes("# END_HEADER\n");

            // Raw content bytes for signal processing
            byte[] content = Files.readAllBytes(downloadedFile.toPath());
            dos.writeInt(content.length);
            dos.write(content);
        }

        // Cleanup temp
        Files.deleteIfExists(downloadedFile.toPath());
        Files.deleteIfExists(tempDir);

        System.out.println("Filtered: " + outputPath);
        return outputPath;
    }

    private String extractVideoId(String url)
    {
        if (url.contains("v="))
            return url.substring(url.indexOf("v=") + 2).split("[&?]")[0];
        if (url.contains("youtu.be/"))
            return url.substring(url.indexOf("youtu.be/") + 9).split("[?]")[0];
        // Assume raw video ID
        return url.trim();
    }

    private String sanitizeName(String title)
    {
        if (title == null || title.isEmpty()) return "untitled";
        return title.replaceAll("[^a-zA-Z0-9._-]", "_")
                    .replaceAll("_+", "_")
                    .substring(0, Math.min(title.length(), 80));
    }

    /**
     * CLI usage: java video.analysis.YouTubeFilter <youtube-url> [youtube-url2] ...
     */
    public static void main(String[] args)
    {
        if (args.length == 0)
        {
            System.out.println("Usage: java video.analysis.YouTubeFilter <youtube-url> [...]");
            System.exit(1);
        }

        YouTubeFilter filter = new YouTubeFilter();

        for (String url : args)
        {
            try
            {
                Path result = filter.filter(url);
                System.out.println("Output: " + result);
            }
            catch (Exception e)
            {
                System.err.println("Error processing " + url + ": " + e.getMessage());
            }
        }
    }
}
