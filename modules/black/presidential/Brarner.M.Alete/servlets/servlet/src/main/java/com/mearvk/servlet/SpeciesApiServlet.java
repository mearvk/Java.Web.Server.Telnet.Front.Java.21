package com.mearvk.servlet;

import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

/**
 * Species taxonomy API — returns JSON children at each hierarchy level.
 *
 *   /api/species?level=class&kingdom=Animalia
 *   /api/species?level=order&class=Mammalia
 *   /api/species?level=family&order=Primates&class=Mammalia
 *   /api/species?level=species&family=Hominidae
 */
public class SpeciesApiServlet extends HttpServlet {

    private Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection("jdbc:mysql://localhost:3306/BrarnerScience", "root", "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        String level = req.getParameter("level");
        if (level == null) { resp.getWriter().write("[]"); return; }

        try (Connection conn = getConnection()) {
            String json = switch (level) {
                case "class"   -> query(conn, "SELECT DISTINCT class_name AS name, COUNT(DISTINCT order_name) AS orders, COUNT(DISTINCT family_name) AS families FROM animalia WHERE kingdom=? AND class_name IS NOT NULL AND class_name!='' GROUP BY class_name ORDER BY class_name", req.getParameter("kingdom") != null ? req.getParameter("kingdom") : "Animalia");
                case "order"   -> query(conn, "SELECT DISTINCT order_name AS name, COUNT(DISTINCT family_name) AS families FROM animalia WHERE class_name=? AND order_name IS NOT NULL AND order_name!='' GROUP BY order_name ORDER BY order_name", req.getParameter("class"));
                case "family"  -> query(conn, "SELECT DISTINCT family_name AS name FROM animalia WHERE order_name=? AND family_name IS NOT NULL AND family_name!='' ORDER BY family_name", req.getParameter("order"));
                case "species" -> query(conn, "SELECT species_name AS name, common_name AS label, description FROM species WHERE family_name=? ORDER BY species_name", req.getParameter("family"));
                default -> "[]";
            };
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
