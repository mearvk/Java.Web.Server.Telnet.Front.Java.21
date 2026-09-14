package com.mearvk.servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.*;

/**
 * Returns system status as JSON — port ranges and active counts.
 */
public class StatusApiServlet extends HttpServlet
{
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.getWriter().write(
            "{\"modules\":[" +
            "{\"name\":\"universities\",\"instances\":53,\"portStart\":8000,\"portEnd\":8052}," +
            "{\"name\":\"postal\",\"instances\":55,\"portStart\":9000,\"portEnd\":9054}," +
            "{\"name\":\"counties\",\"instances\":100,\"portStart\":9100,\"portEnd\":9199}," +
            "{\"name\":\"countries\",\"instances\":195,\"portStart\":11000,\"portEnd\":11194}," +
            "{\"name\":\"ssa\",\"instances\":1182,\"portStart\":9200,\"portEnd\":10381}," +
            "{\"name\":\"chemistry\",\"instances\":5,\"portStart\":20001,\"portEnd\":20005}" +
            "]}"
        );
    }
}
