package com.mearvk.ejb;

import jakarta.annotation.PostConstruct;
import jakarta.ejb.*;
import javax.sql.DataSource;
import javax.naming.*;
import java.sql.*;

/**
 * Session bean managing user authentication, contracts, and student finals.
 * Interfaces with the BrarnerDB datasource.
 */
@Stateless
public class DataManagerBean
{
    private DataSource ds;

    @PostConstruct
    private void init() {
        try { ds = (DataSource) new InitialContext().lookup("java:comp/env/jdbc/BrarnerDB"); }
        catch (NamingException e) { throw new RuntimeException(e); }
    }

    public boolean authenticateUser(String username, String passwordHash) throws SQLException {
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT id FROM users WHERE username = ? AND password_hash = ? AND active = 1")) {
            ps.setString(1, username);
            ps.setString(2, passwordHash);
            return ps.executeQuery().next();
        }
    }

    public int createContract(String institution, String description, String terms) throws SQLException {
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO contracts (institution, description, terms, created_at) VALUES (?, ?, ?, NOW())",
                 Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, institution);
            ps.setString(2, description);
            ps.setString(3, terms);
            ps.executeUpdate();
            ResultSet rs = ps.getGeneratedKeys();
            return rs.next() ? rs.getInt(1) : -1;
        }
    }

    public int submitStudentFinal(int userId, String course, String data) throws SQLException {
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO student_finals (user_id, course, final_data, submitted_at) VALUES (?, ?, ?, NOW())",
                 Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, userId);
            ps.setString(2, course);
            ps.setString(3, data);
            ps.executeUpdate();
            ResultSet rs = ps.getGeneratedKeys();
            return rs.next() ? rs.getInt(1) : -1;
        }
    }
}
