package com.github.kiulian.downloader.model.videos;

/**
 * Video metadata details: title, author, duration.
 */
public class VideoDetails
{
    private String title;
    private String author;
    private int lengthSeconds;

    public VideoDetails(String title, String author, int lengthSeconds)
    {
        this.title = title;
        this.author = author;
        this.lengthSeconds = lengthSeconds;
    }

    public String title()       { return title; }
    public String author()      { return author; }
    public int lengthSeconds()  { return lengthSeconds; }
}
