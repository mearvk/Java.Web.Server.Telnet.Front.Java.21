package com.mearvk.servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.*;

/**
 * Invalidates admin session and redirects to login.
 */
public class AdminLogoutServlet extends HttpServlet
{
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.invalidate();
        resp.sendRedirect(req.getContextPath() + "/admin/login.xhtml");
    }
}
