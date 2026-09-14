package com.github.kiulian.downloader.downloader.request;

/**
 * Request object for fetching video info by video ID.
 */
public class RequestVideoInfo
{
    private final String videoId;

    public RequestVideoInfo(String videoId)
    {
        this.videoId = videoId;
    }

    public String getVideoId() { return videoId; }
}
