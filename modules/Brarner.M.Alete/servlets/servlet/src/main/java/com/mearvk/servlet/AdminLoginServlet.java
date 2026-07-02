package com.mearvk.servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;
import javax.naming.*;
import javax.sql.DataSource;

/**
 * Admin login servlet — authenticates against the users table.
 * On success, stores session and redirects to dashboard.
 */
public class AdminLoginServlet extends HttpServlet
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
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT id, role FROM users WHERE username = ? AND password_hash = SHA2(?, 256) AND active = 1")) {
            ps.setString(1, username);
            ps.setString(2, password);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                HttpSession session = req.getSession(true);
                session.setAttribute("userId", rs.getInt("id"));
                session.setAttribute("username", username);
                session.setAttribute("role", rs.getString("role"));
                resp.sendRedirect(req.getContextPath() + "/admin/dashboard.xhtml");
            } else {
                resp.sendRedirect(req.getContextPath() + "/admin/login.xhtml?error=1");
            }
        } catch (SQLException e) { throw new ServletException(e); }
    }
}
