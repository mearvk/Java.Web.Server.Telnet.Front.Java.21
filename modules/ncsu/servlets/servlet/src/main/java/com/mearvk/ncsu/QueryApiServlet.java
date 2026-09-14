package com.mearvk.ncsu;

import jakarta.servlet.*; import jakarta.servlet.http.*;
import java.io.*; import java.sql.*; import java.util.Properties;

/**
 * QueryApiServlet — REST endpoint for NC State query submission.
 * POST /api/query with parameters: college, text
 */
public class QueryApiServlet extends HttpServlet {
    @Override protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String college = req.getParameter("college"), text = req.getParameter("text");
        if (college == null || text == null || text.trim().isEmpty()) { resp.setStatus(400); resp.getWriter().write("{\"error\":\"college and text required\"}"); return; }
        try (Connection conn = getConn(req.getServletContext());
             PreparedStatement ps = conn.prepareStatement("INSERT INTO college_queries (college, query_text) VALUES (?, ?)", Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, college); ps.setString(2, text.trim()); ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys(); long id = keys.next() ? keys.getLong(1) : -1;
            resp.getWriter().write("{\"ok\":true,\"id\":" + id + "}");
        } catch (Exception e) { resp.setStatus(500); resp.getWriter().write("{\"error\":\"" + e.getMessage().replace("\"","'") + "\"}"); }
    }
    private Connection getConn(ServletContext ctx) throws Exception {
        Properties p = new Properties(); try (InputStream is = ctx.getResourceAsStream("/WEB-INF/db.properties")) { if (is != null) p.load(is); }
        Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        return DriverManager.getConnection(p.getProperty("db.url"), p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
    }
}
