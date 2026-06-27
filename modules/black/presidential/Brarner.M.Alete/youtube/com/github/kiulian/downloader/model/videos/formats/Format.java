package com.github.kiulian.downloader.model.videos.formats;

/**
 * Represents a single downloadable media format (audio or video).
 */
public class Format
{
    private final String url;
    private final String mimeType;
    private final long bitrate;
    private final long contentLength;
    private final String extension;

    public Format(String url, String mimeType, long bitrate, long contentLength, String extension)
    {
        this.url = url;
        this.mimeType = mimeType;
        this.bitrate = bitrate;
        this.contentLength = contentLength;
        this.extension = extension;
    }

    public String url()           { return url; }
    public String mimeType()      { return mimeType; }
    public long bitrate()         { return bitrate; }
    public long contentLength()   { return contentLength; }
    public String extension()     { return extension; }
}
