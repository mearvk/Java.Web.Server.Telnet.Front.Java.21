package com.mearvk.servlet;

import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

/**
 * Science tab API — returns JSON for science fines, experiments, and research data.
 *
 *   /api/science                             — list categories (fines)
 *   /api/science?category=frontermus         — entries in a category
 *   /api/science?view=experiments            — all experiment results
 *   /api/science?view=experiments&office=durham — experiments from a specific office
 */
public class ScienceApiServlet extends HttpServlet {

    private Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection("jdbc:mysql://localhost:3306/BrarnerScience", "root", "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        String category = req.getParameter("category");
        String view = req.getParameter("view");
        String office = req.getParameter("office");

        try (Connection conn = getConnection()) {
            String json;
            if ("experiments".equals(view)) {
                if (office != null) {
                    json = query(conn, "SELECT experiment_name, experiment_data, created_at FROM experiments WHERE experiment_name LIKE ? ORDER BY created_at DESC LIMIT 100", "%" + office + "%");
                } else {
                    json = query(conn, "SELECT experiment_name, experiment_data, created_at FROM experiments ORDER BY created_at DESC LIMIT 100");
                }
            } else if (category != null) {
                json = query(conn, "SELECT id, title, description, classification, created_at FROM science_entries WHERE category=? ORDER BY title", category);
            } else {
                json = query(conn, "SELECT category, COUNT(*) AS entry_count, MAX(created_at) AS last_updated FROM science_entries GROUP BY category ORDER BY category");
            }
            resp.getWriter().write(json);
        } catch (Exception e) {
            resp.setStatus(500);
            resp.getWriter().write("[{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}]");
        }
    }

    private String query(Connection conn, String sql, String... params) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setString(i + 1, params[i]);
            ResultSet rs = ps.executeQuery();
            ResultSetMetaData md = rs.getMetaData();
            int cols = md.getColumnCount();
            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) sb.append(",");
                first = false;
                sb.append("{");
                for (int c = 1; c <= cols; c++) {
                    if (c > 1) sb.append(",");
                    String col = md.getColumnLabel(c);
                    String val = rs.getString(c);
                    sb.append("\"").append(col).append("\":");
                    if (val == null) sb.append("null");
                    else if (md.getColumnType(c) == Types.INTEGER || md.getColumnType(c) == Types.BIGINT) sb.append(val);
                    else sb.append("\"").append(val.replace("\\","\\\\").replace("\"","\\\"")).append("\"");
                }
                sb.append("}");
            }
            return sb.append("]").toString();
        }
    }
}
