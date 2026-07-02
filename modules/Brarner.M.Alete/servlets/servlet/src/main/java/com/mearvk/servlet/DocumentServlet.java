package com.mearvk.servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;
import javax.naming.*;
import javax.sql.DataSource;

/**
 * Handles POST document submission and retrieval for admin users.
 * POST: accepts document submission from any source.
 * GET: retrieves documents as JSON for authenticated admins.
 */
public class DocumentServlet extends HttpServlet
{
    private DataSource ds;

    @Override
    public void init() throws ServletException {
        try {
            ds = (DataSource) new InitialContext().lookup("java:comp/env/jdbc/BrarnerDB");
        } catch (NamingException e) { throw new ServletException(e); }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String source = req.getParameter("source");
        String docType = req.getParameter("type");
        String content = req.getReader().lines().reduce("", (a, b) -> a + b);

        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO documents (source, doc_type, content, submitted_at) VALUES (?, ?, ?, NOW())")) {
            ps.setString(1, source);
            ps.setString(2, docType);
            ps.setString(3, content);
            ps.executeUpdate();
            resp.setStatus(201);
            resp.getWriter().write("{\"status\":\"accepted\"}");
        } catch (SQLException e) { throw new ServletException(e); }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendError(401);
            return;
        }

        resp.setContentType("application/json");
        try (Connection conn = ds.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT id, source, doc_type, submitted_at FROM documents ORDER BY submitted_at DESC LIMIT 100")) {
            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) sb.append(",");
                sb.append("{\"id\":").append(rs.getInt("id"))
                  .append(",\"source\":\"").append(rs.getString("source"))
                  .append("\",\"type\":\"").append(rs.getString("doc_type"))
                  .append("\",\"submitted\":\"").append(rs.getTimestamp("submitted_at"))
                  .append("\"}");
                first = false;
            }
            sb.append("]");
            resp.getWriter().write(sb.toString());
        } catch (SQLException e) { throw new ServletException(e); }
    }
}
