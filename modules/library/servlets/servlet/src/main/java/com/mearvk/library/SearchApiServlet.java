package com.mearvk.library;

import jakarta.servlet.*; import jakarta.servlet.http.*;
import java.io.*; import java.sql.*; import java.util.Properties;

public class SearchApiServlet extends HttpServlet {
    @Override protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String q = req.getParameter("q");
        if (q == null || q.trim().isEmpty()) { resp.setStatus(400); resp.getWriter().write("{\"error\":\"q required\"}"); return; }
        try (Connection conn = getConn(req.getServletContext());
             PreparedStatement ps = conn.prepareStatement("SELECT id, title, resource_type, status, created_at FROM library_requests WHERE title LIKE ? ORDER BY created_at DESC LIMIT 50")) {
            ps.setString(1, "%" + q.trim() + "%");
            ResultSet rs = ps.executeQuery(); StringBuilder json = new StringBuilder("{\"results\":["); boolean first = true;
            while (rs.next()) { if (!first) json.append(","); first = false;
                json.append("{\"id\":").append(rs.getInt(1)).append(",\"title\":\"").append(esc(rs.getString(2))).append("\",\"type\":\"").append(rs.getString(3)).append("\",\"status\":\"").append(rs.getString(4)).append("\"}"); }
            json.append("]}"); resp.getWriter().write(json.toString());
        } catch (Exception e) { resp.setStatus(500); resp.getWriter().write("{\"error\":\"" + esc(e.getMessage()) + "\"}"); }
    }
    private static String esc(String s) { return s == null ? "" : s.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n"); }
    private Connection getConn(ServletContext ctx) throws Exception {
        Properties p = new Properties(); try (InputStream is = ctx.getResourceAsStream("/WEB-INF/db.properties")) { if (is != null) p.load(is); }
        Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        return DriverManager.getConnection(p.getProperty("db.url"), p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
    }
}
