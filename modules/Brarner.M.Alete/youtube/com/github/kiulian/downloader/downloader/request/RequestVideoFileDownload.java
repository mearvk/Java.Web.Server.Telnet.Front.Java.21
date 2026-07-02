package com.github.kiulian.downloader.downloader.request;

import com.github.kiulian.downloader.model.videos.formats.Format;
import java.io.File;

/**
 * Request object for downloading a video file given a format.
 */
public class RequestVideoFileDownload
{
    private final Format format;
    private File outputDir;

    public RequestVideoFileDownload(Format format)
    {
        this.format = format;
    }

    public RequestVideoFileDownload saveTo(File dir)
    {
        this.outputDir = dir;
        return this;
    }

    public Format getFormat()  { return format; }
    public File getOutputDir() { return outputDir; }
}
