package com.mearvk.fbi;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;
import java.util.Properties;

/**
 * ReportApiServlet — JSON API for submitting crime reports.
 * POST /api/report — body: {"category":"...", "text":"..."}
 */
public class ReportApiServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String category = req.getParameter("category");
        String text = req.getParameter("text");

        if (category == null || text == null || text.trim().isEmpty()) {
            resp.setStatus(400);
            resp.getWriter().write("{\"error\":\"category and text required\"}");
            return;
        }

        try (Connection conn = getConnection(req.getServletContext());
             PreparedStatement ps = conn.prepareStatement(
                     "INSERT INTO crime_reports (category, report_text, status) VALUES (?, ?, 'pending')",
                     Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, category);
            ps.setString(2, text.trim());
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            long id = keys.next() ? keys.getLong(1) : -1;
            resp.getWriter().write("{\"ok\":true,\"id\":" + id + ",\"status\":\"pending\"}");
        } catch (Exception e) {
            resp.setStatus(500);
            resp.getWriter().write("{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}");
        }
    }

    private Connection getConnection(ServletContext ctx) throws Exception {
        Properties p = new Properties();
        try (InputStream is = ctx.getResourceAsStream("/WEB-INF/db.properties")) {
            if (is != null) p.load(is);
        }
        Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        return DriverManager.getConnection(
                p.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_california_fbi"),
                p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
    }
}
