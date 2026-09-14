package com.github.kiulian.downloader.downloader.response;

/**
 * Generic response wrapper holding data or error.
 */
public class Response<T>
{
    private final T data;
    private final Throwable error;

    public Response(T data, Throwable error)
    {
        this.data = data;
        this.error = error;
    }

    public T data()           { return data; }
    public Throwable error()  { return error; }
    public boolean ok()       { return error == null && data != null; }
}
