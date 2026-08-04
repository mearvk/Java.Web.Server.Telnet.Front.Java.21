<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest, java.nio.charset.StandardCharsets" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String timeAgo(Timestamp ts) {
        if (ts == null) return "—";
        long diff = System.currentTimeMillis() - ts.getTime(); long mins = diff / 60000;
        if (mins < 1) return "just now"; if (mins < 60) return mins + "m ago";
        long hrs = mins / 60; if (hrs < 24) return hrs + "h ago";
        long days = hrs / 24; if (days < 30) return days + "d ago";
        return new java.text.SimpleDateFormat("MMM d, yyyy").format(ts);
    }
%>
<%
    // ═══════════════════════════════════════════════════════════════════
    // NitroWebExpress™ — Profile Page (Generic Template)
    // Works with nwe_messaging user accounts. Drop into any module.
    // ═══════════════════════════════════════════════════════════════════

    String MODULE_NAME = request.getContextPath().replaceAll("^/", "");
    if (MODULE_NAME.isEmpty()) MODULE_NAME = "general";

    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_messaging";
    String dbUser = "root";
    String dbPass = "$$Ironman1";
    Connection conn = null;
    boolean dbOk = false;

    Integer sessionUserId = (Integer) session.getAttribute("msg_user_id");
    String sessionUsername = (String) session.getAttribute("msg_username");
    String sessionDisplayName = (String) session.getAttribute("msg_display_name");
    Boolean sessionAdmin = (Boolean) session.getAttribute("msg_admin");
    if (sessionAdmin == null) sessionAdmin = false;

    // Profile data
    String viewUser = request.getParameter("user");
    Map<String, String> profileData = new LinkedHashMap<>();
    int postCount = 0;
    int groupCount = 0;
    String memberSince = "—";
    String lastActive = "—";
    boolean viewingSelf = false;
    boolean profileFound = false;

    // Action: update display name / email
    String action = request.getParameter("action");
    String successMsg = null;
    String errorMsg = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        dbOk = true;

        // Update profile
        if ("update".equals(action) && "POST".equals(request.getMethod()) && sessionUserId != null) {
            String newDisplay = request.getParameter("display_name");
            String newEmail = request.getParameter("email");
            PreparedStatement ps = conn.prepareStatement("UPDATE msg_users SET display_name = ?, email = ? WHERE id = ?");
            ps.setString(1, (newDisplay != null && !newDisplay.trim().isEmpty()) ? newDisplay.trim() : sessionUsername);
            ps.setString(2, newEmail);
            ps.setInt(3, sessionUserId);
            ps.executeUpdate(); ps.close();
            session.setAttribute("msg_display_name", (newDisplay != null && !newDisplay.trim().isEmpty()) ? newDisplay.trim() : sessionUsername);
            sessionDisplayName = (String) session.getAttribute("msg_display_name");
            successMsg = "Profile updated.";
        }

        // Determine whose profile to show
        int targetUserId = -1;
        if (viewUser != null && !viewUser.trim().isEmpty()) {
            // Viewing someone else
            PreparedStatement ps = conn.prepareStatement("SELECT id, username, display_name, email, avatar_color, is_admin, created_at, last_active FROM msg_users WHERE username = ?");
            ps.setString(1, viewUser.trim());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                profileFound = true;
                targetUserId = rs.getInt("id");
                profileData.put("Username", esc(rs.getString("username")));
                profileData.put("Display Name", esc(rs.getString("display_name")));
                if (sessionAdmin) profileData.put("Email", esc(rs.getString("email") != null ? rs.getString("email") : "—"));
                profileData.put("Role", rs.getBoolean("is_admin") ? "Administrator" : "Member");
                profileData.put("Member Since", rs.getTimestamp("created_at") != null ? new java.text.SimpleDateFormat("MMM d, yyyy").format(rs.getTimestamp("created_at")) : "—");
                profileData.put("Last Active", timeAgo(rs.getTimestamp("last_active")));
                viewingSelf = (sessionUserId != null && sessionUserId == targetUserId);
            }
            rs.close(); ps.close();
        } else if (sessionUserId != null) {
            // Viewing self
            viewingSelf = true;
            profileFound = true;
            targetUserId = sessionUserId;
            PreparedStatement ps = conn.prepareStatement("SELECT username, display_name, email, avatar_color, is_admin, created_at, last_active FROM msg_users WHERE id = ?");
            ps.setInt(1, sessionUserId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                profileData.put("Username", esc(rs.getString("username")));
                profileData.put("Display Name", esc(rs.getString("display_name")));
                profileData.put("Email", esc(rs.getString("email") != null ? rs.getString("email") : "—"));
                profileData.put("Role", rs.getBoolean("is_admin") ? "Administrator" : "Member");
                profileData.put("Member Since", rs.getTimestamp("created_at") != null ? new java.text.SimpleDateFormat("MMM d, yyyy").format(rs.getTimestamp("created_at")) : "—");
                profileData.put("Last Active", timeAgo(rs.getTimestamp("last_active")));
            }
            rs.close(); ps.close();
        }

        // Post count and group count for target user
        if (targetUserId > 0) {
            PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM msg_posts WHERE user_id = ? AND is_deleted = FALSE");
            ps.setInt(1, targetUserId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) postCount = rs.getInt(1);
            rs.close(); ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM msg_subgroups WHERE owner_id = ? AND is_archived = FALSE");
            ps.setInt(1, targetUserId);
            rs = ps.executeQuery();
            if (rs.next()) groupCount = rs.getInt(1);
            rs.close(); ps.close();
        }

    } catch (Exception e) { errorMsg = "Database error: " + e.getMessage(); }
    if (conn != null) try { conn.close(); } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <title>Profile — <%= esc(MODULE_NAME) %></title>
    <link rel="stylesheet" href="css/style.css"/>
    <style>
        .profile-page { max-width:720px; margin:0 auto; padding:2rem; }
        .profile-header { text-align:center; margin-bottom:2rem; }
        .profile-header h1 { font-size:1.5rem; font-weight:700; margin-bottom:0.25rem; }
        .profile-header p { font-size:0.85rem; color:#a1a1aa; }

        .profile-card { background:#111118; border:1px solid #27272a; border-radius:12px; padding:1.5rem; margin-bottom:1.25rem; }
        .profile-card h3 { font-size:0.8rem; font-weight:600; text-transform:uppercase; letter-spacing:0.04em; color:#71717a; margin-bottom:1rem; }

        .profile-avatar { width:72px; height:72px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:1.75rem; font-weight:700; color:#fff; margin:0 auto 1rem; }

        .profile-row { display:flex; justify-content:space-between; align-items:center; padding:0.5rem 0; border-bottom:1px solid #1e1e26; }
        .profile-row:last-child { border-bottom:none; }
        .profile-row .label { font-size:0.8rem; color:#71717a; }
        .profile-row .value { font-size:0.8rem; color:#e4e4e7; font-weight:500; }

        .stat-pills { display:flex; gap:1rem; justify-content:center; margin-bottom:1.5rem; }
        .stat-pill { text-align:center; }
        .stat-pill .num { font-size:1.25rem; font-weight:700; color:#3b82f6; }
        .stat-pill .lbl { font-size:0.65rem; color:#71717a; text-transform:uppercase; letter-spacing:0.04em; }

        .profile-form input { width:100%; background:#1a1a24; border:1px solid #27272a; border-radius:8px; padding:0.5rem 0.75rem; color:#e4e4e7; font-size:0.8rem; margin-bottom:0.5rem; }
        .profile-form input:focus { outline:none; border-color:#3b82f6; }

        .search-box { display:flex; gap:0.5rem; margin-bottom:1.5rem; }
        .search-box input { flex:1; background:#1a1a24; border:1px solid #27272a; border-radius:8px; padding:0.5rem 0.75rem; color:#e4e4e7; font-size:0.8rem; }
        .search-box input:focus { outline:none; border-color:#3b82f6; }

        .flash { padding:0.5rem 0.75rem; border-radius:6px; font-size:0.8rem; margin-bottom:1rem; }
        .flash-s { background:rgba(34,197,94,0.1); border:1px solid rgba(34,197,94,0.3); color:#4ade80; }
        .flash-e { background:rgba(239,68,68,0.1); border:1px solid rgba(239,68,68,0.3); color:#f87171; }

        .empty-profile { text-align:center; padding:3rem; color:#71717a; }
    </style>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand"><%= esc(MODULE_NAME) %>™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Home</a></li>
        <li><a href="profile.jsp" class="active">Profile</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <% if (sessionUserId != null) { %>
            <span style="font-size:0.8rem;color:#3b82f6;"><%= esc(sessionUsername) %></span>
            <a href="messaging.jsp?action=logout" style="font-size:0.75rem;color:#71717a;margin-left:0.5rem;">Logout</a>
        <% } else { %>
            <a href="messaging.jsp" style="font-size:0.75rem;color:#3b82f6;">Login</a>
        <% } %>
    </div>
</div></nav>

<div class="profile-page">
    <div class="profile-header">
        <h1>Profile</h1>
        <p>View and manage your account. Look up other users.</p>
    </div>

    <% if (successMsg != null) { %><div class="flash flash-s"><%= esc(successMsg) %></div><% } %>
    <% if (errorMsg != null) { %><div class="flash flash-e"><%= esc(errorMsg) %></div><% } %>

    <!-- Search for user -->
    <form method="get" action="profile.jsp" class="search-box">
        <input type="text" name="user" placeholder="Look up a user by username..." value="<%= viewUser != null ? esc(viewUser) : "" %>"/>
        <button type="submit" class="btn btn-primary btn-sm" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.5rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">View</button>
    </form>

    <% if (!dbOk) { %>
    <div class="flash flash-e">Messaging database offline. Log in via <a href="messaging.jsp" style="color:#60a5fa;">messaging.jsp</a> to create an account.</div>

    <% } else if (!profileFound && sessionUserId == null && (viewUser == null || viewUser.isEmpty())) { %>
    <div class="empty-profile">
        <h3 style="color:#a1a1aa;margin-bottom:0.5rem;">Not logged in</h3>
        <p>Log in via <a href="messaging.jsp" style="color:#3b82f6;">Messages</a> to view your profile, or search for a user above.</p>
    </div>

    <% } else if (!profileFound && viewUser != null) { %>
    <div class="empty-profile">
        <h3 style="color:#f87171;margin-bottom:0.5rem;">User not found</h3>
        <p>No user with username "<%= esc(viewUser) %>" exists.</p>
    </div>

    <% } else if (profileFound) { %>

    <!-- Avatar + Stats -->
    <div class="profile-card" style="text-align:center;">
        <div class="profile-avatar" style="background:#3b82f6;"><%= profileData.containsKey("Username") ? profileData.get("Username").substring(0,1).toUpperCase() : "?" %></div>
        <div style="font-size:1.1rem;font-weight:700;color:#e4e4e7;margin-bottom:0.2rem;"><%= profileData.getOrDefault("Display Name", "—") %></div>
        <div style="font-size:0.8rem;color:#71717a;margin-bottom:1rem;">@<%= profileData.getOrDefault("Username", "—") %> · <%= profileData.getOrDefault("Role", "Member") %></div>
        <div class="stat-pills">
            <div class="stat-pill"><div class="num"><%= postCount %></div><div class="lbl">Posts</div></div>
            <div class="stat-pill"><div class="num"><%= groupCount %></div><div class="lbl">Groups</div></div>
        </div>
    </div>

    <!-- Profile Info -->
    <div class="profile-card">
        <h3>Profile Information</h3>
        <% for (Map.Entry<String, String> entry : profileData.entrySet()) { %>
        <div class="profile-row">
            <span class="label"><%= esc(entry.getKey()) %></span>
            <span class="value"><%= entry.getValue() %></span>
        </div>
        <% } %>
        <div class="profile-row">
            <span class="label">Posts (all modules)</span>
            <span class="value"><%= postCount %></span>
        </div>
        <div class="profile-row">
            <span class="label">Groups Created</span>
            <span class="value"><%= groupCount %></span>
        </div>
    </div>

    <!-- Edit (self only) -->
    <% if (viewingSelf) { %>
    <div class="profile-card">
        <h3>Edit Profile</h3>
        <form method="post" action="profile.jsp" class="profile-form">
            <input type="hidden" name="action" value="update"/>
            <label style="font-size:0.7rem;color:#71717a;display:block;margin-bottom:0.2rem;">Display Name</label>
            <input type="text" name="display_name" value="<%= esc(sessionDisplayName) %>" placeholder="Display name"/>
            <label style="font-size:0.7rem;color:#71717a;display:block;margin-bottom:0.2rem;margin-top:0.5rem;">Email</label>
            <input type="email" name="email" value="<%= profileData.getOrDefault("Email", "") %>" placeholder="Email (optional)"/>
            <button type="submit" class="btn btn-primary btn-sm" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.5rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;margin-top:0.75rem;">Save Changes</button>
        </form>
    </div>
    <% } %>

    <% } %>
</div>

<footer style="padding:2rem;text-align:center;border-top:1px solid #27272a;color:#71717a;font-size:0.7rem;">NitroWebExpress™ — Profile — MEARVK LLC 2026</footer>
</body>
</html>
