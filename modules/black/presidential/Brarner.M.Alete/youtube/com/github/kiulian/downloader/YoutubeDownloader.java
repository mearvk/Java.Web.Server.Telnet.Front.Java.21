package com.github.kiulian.downloader;

import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.downloader.response.Response;
import com.github.kiulian.downloader.model.videos.VideoInfo;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;

/**
 * Local replacement for com.github.kiulian.downloader.YoutubeDownloader.
 * Fetches YouTube video metadata and streams via innertube API.
 */
public class YoutubeDownloader
{
    private static final String INNERTUBE_API = "https://www.youtube.com/youtubei/v1/player?prettyPrint=false";
    private static final String USER_AGENT = "com.google.android.youtube/19.09.37 (Linux; U; Android 11) gzip";

    public YoutubeDownloader() {}

    public Response<VideoInfo> getVideoInfo(RequestVideoInfo request)
    {
        try
        {
            String videoId = request.getVideoId();
            String body = "{\"context\":{\"client\":{\"clientName\":\"ANDROID_VR\",\"clientVersion\":\"1.57.29\",\"androidSdkVersion\":30}},\"videoId\":\"" + videoId + "\"}";

            HttpURLConnection conn = (HttpURLConnection) new URL(INNERTUBE_API).openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("User-Agent", USER_AGENT);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);
            conn.getOutputStream().write(body.getBytes());

            int code = conn.getResponseCode();
            if (code != 200)
                return new Response<>(null, new IOException("HTTP " + code));

            String json = new String(conn.getInputStream().readAllBytes());
            VideoInfo info = VideoInfo.parse(json, videoId);
            return new Response<>(info, null);
        }
        catch (Exception e)
        {
            return new Response<>(null, e);
        }
    }

    public Response<File> downloadVideoFile(RequestVideoFileDownload request)
    {
        try
        {
            String url = request.getFormat().url();
            File outputDir = request.getOutputDir();
            if (outputDir == null) outputDir = new File("videos");
            outputDir.mkdirs();

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestProperty("User-Agent", USER_AGENT);

            String ext = request.getFormat().extension();
            String filename = "video_" + System.currentTimeMillis() + "." + ext;
            File outFile = new File(outputDir, filename);

            try (InputStream in = conn.getInputStream();
                 FileOutputStream out = new FileOutputStream(outFile))
            {
                in.transferTo(out);
            }

            return new Response<>(outFile, null);
        }
        catch (Exception e)
        {
            return new Response<>(null, e);
        }
    }
}
