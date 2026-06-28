package com.mearvk.servlet;

import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

/**
 * Art tab API — returns JSON for NC art museums/galleries.
 *
 *   /api/art                         — list all institutions
 *   /api/art?institution=ncma        — details for a specific institution
 *   /api/art?institution=ncma&view=collection — collection items
 */
public class ArtApiServlet extends HttpServlet {

    private Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection("jdbc:mysql://localhost:3306/BrarnerArt", "root", "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        String institution = req.getParameter("institution");
        String view = req.getParameter("view");

        try (Connection conn = getConnection()) {
            String json;
            if (institution == null) {
                json = query(conn, "SELECT id, name, city, type, status, port FROM art_institutions ORDER BY name");
            } else if ("collection".equals(view)) {
                json = query(conn, "SELECT title, artist, medium, year_created, description FROM art_collection WHERE institution_key=? ORDER BY title", institution);
            } else {
                json = query(conn, "SELECT id, name, city, type, address, description, status, port FROM art_institutions WHERE institution_key=?", institution);
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
