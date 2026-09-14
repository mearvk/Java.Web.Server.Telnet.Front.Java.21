package com.github.kiulian.downloader.model.videos;

import com.github.kiulian.downloader.model.videos.formats.Format;
import java.util.*;
import java.util.regex.*;

/**
 * Parsed video info containing details and available formats.
 */
public class VideoInfo
{
    private final VideoDetails details;
    private final List<Format> formats;

    public VideoInfo(VideoDetails details, List<Format> formats)
    {
        this.details = details;
        this.formats = formats;
    }

    public VideoDetails details()       { return details; }
    public Format bestAudioFormat()     { return findByMime("audio"); }
    public Format bestVideoFormat()     { return findByMime("video"); }

    private Format findByMime(String prefix)
    {
        return formats.stream()
            .filter(f -> f.mimeType() != null && f.mimeType().startsWith(prefix))
            .max(Comparator.comparingLong(Format::bitrate))
            .orElse(null);
    }

    /**
     * Parses innertube player response JSON (minimal extraction).
     */
    public static VideoInfo parse(String json, String videoId)
    {
        String title = extractJsonString(json, "title");
        String author = extractJsonString(json, "author");
        int length = extractJsonInt(json, "lengthSeconds");

        VideoDetails details = new VideoDetails(
            title != null ? title : videoId,
            author != null ? author : "Unknown",
            length
        );

        List<Format> formats = new ArrayList<>();

        // Extract streaming data formats (adaptiveFormats + formats)
        Pattern urlPattern = Pattern.compile("\"url\"\\s*:\\s*\"(https://[^\"]+)\"");
        Pattern mimePattern = Pattern.compile("\"mimeType\"\\s*:\\s*\"([^\"]+)\"");
        Pattern bitratePattern = Pattern.compile("\"bitrate\"\\s*:\\s*(\\d+)");
        Pattern contentLenPattern = Pattern.compile("\"contentLength\"\\s*:\\s*\"(\\d+)\"");

        // Split on format boundaries
        String[] segments = json.split("\\{\"itag\"");
        for (int i = 1; i < segments.length; i++)
        {
            String seg = segments[i];
            String url = matchFirst(urlPattern, seg);
            String mime = matchFirst(mimePattern, seg);
            long bitrate = parseLong(matchFirst(bitratePattern, seg));
            long contentLen = parseLong(matchFirst(contentLenPattern, seg));

            if (url != null)
            {
                url = url.replace("\\u0026", "&");
                String ext = "mp4";
                if (mime != null && mime.contains("webm")) ext = "webm";
                else if (mime != null && mime.contains("mp4")) ext = "mp4";
                else if (mime != null && mime.contains("audio")) ext = "m4a";

                formats.add(new Format(url, mime, bitrate, contentLen, ext));
            }
        }

        return new VideoInfo(details, formats);
    }

    private static String extractJsonString(String json, String key)
    {
        Pattern p = Pattern.compile("\"" + key + "\"\\s*:\\s*\"([^\"]+)\"");
        Matcher m = p.matcher(json);
        return m.find() ? m.group(1) : null;
    }

    private static int extractJsonInt(String json, String key)
    {
        Pattern p = Pattern.compile("\"" + key + "\"\\s*:\\s*\"?(\\d+)\"?");
        Matcher m = p.matcher(json);
        return m.find() ? Integer.parseInt(m.group(1)) : 0;
    }

    private static String matchFirst(Pattern p, String text)
    {
        Matcher m = p.matcher(text);
        return m.find() ? m.group(1) : null;
    }

    private static long parseLong(String s)
    {
        if (s == null) return 0;
        try { return Long.parseLong(s); } catch (NumberFormatException e) { return 0; }
    }
}
