package com.mearvk.servlet;

import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

/**
 * Postal tab API — returns JSON for NC post office data.
 *
 *   /api/postal                        — list all offices
 *   /api/postal?city=durham            — office details for a city
 *   /api/postal?city=durham&view=experiments — experiment data for that office
 */
public class PostalApiServlet extends HttpServlet {

    private Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection("jdbc:mysql://localhost:3306/BrarnerPostal", "root", "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");
        String city = req.getParameter("city");
        String view = req.getParameter("view");

        try (Connection conn = getConnection()) {
            String json;
            if (city == null) {
                json = query(conn, "SELECT office_name, city, zip_code, county, status FROM postal_offices ORDER BY city");
            } else if ("experiments".equals(view)) {
                json = query(conn, "SELECT experiment_name, experiment_data, created_at FROM experiments WHERE office_city=? ORDER BY created_at DESC LIMIT 50", city);
            } else {
                json = query(conn, "SELECT office_name, city, zip_code, county, status, port FROM postal_offices WHERE city=?", city);
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
