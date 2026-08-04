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
    String MODULE_NAME = "brarner.m.alete";

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

    String viewUser = request.getParameter("user");
    Map<String, String> profileData = new LinkedHashMap<>();
    int postCount = 0, groupCount = 0;
    // BMA-specific stats
    int scienceInputs = 0, speciesContrib = 0, postalLookups = 0, artVisits = 0, legalQueries = 0, analysisUploads = 0;
    boolean viewingSelf = false;
    boolean profileFound = false;

    String action = request.getParameter("action");
    String successMsg = null;
    String errorMsg = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        dbOk = true;

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

        int targetUserId = -1;
        if (viewUser != null && !viewUser.trim().isEmpty()) {
            PreparedStatement ps = conn.prepareStatement("SELECT id, username, display_name, email, avatar_color, is_admin, created_at, last_active FROM msg_users WHERE username = ?");
            ps.setString(1, viewUser.trim());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                profileFound = true; targetUserId = rs.getInt("id");
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
            viewingSelf = true; profileFound = true; targetUserId = sessionUserId;
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

        if (targetUserId > 0) {
            PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM msg_posts WHERE user_id = ? AND is_deleted = FALSE");
            ps.setInt(1, targetUserId); ResultSet rs = ps.executeQuery(); if (rs.next()) postCount = rs.getInt(1); rs.close(); ps.close();
            ps = conn.prepareStatement("SELECT COUNT(*) FROM msg_subgroups WHERE owner_id = ? AND is_archived = FALSE");
            ps.setInt(1, targetUserId); rs = ps.executeQuery(); if (rs.next()) groupCount = rs.getInt(1); rs.close(); ps.close();
        }

        // BMA science input stats (from nwe_analytics if available)
        if (targetUserId > 0) {
            try {
                Connection conn2 = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_analytics", "root", "$$Ironman1");
                String hash = "";
                // Try to get user hash for analytics lookup (simplified — count by module activity)
                PreparedStatement ps2 = conn2.prepareStatement("SELECT COALESCE(SUM(CASE WHEN category='Science' THEN input_count ELSE 0 END),0), COALESCE(SUM(CASE WHEN category='Species' THEN input_count ELSE 0 END),0), COALESCE(SUM(CASE WHEN category='PostOffice' THEN input_count ELSE 0 END),0), COALESCE(SUM(CASE WHEN category='Art' THEN input_count ELSE 0 END),0), COALESCE(SUM(CASE WHEN category='Legal' THEN input_count ELSE 0 END),0), COALESCE(SUM(CASE WHEN category='Analysis' THEN input_count ELSE 0 END),0) FROM bma_science_inputs");
                ResultSet rs2 = ps2.executeQuery();
                if (rs2.next()) { scienceInputs = rs2.getInt(1); speciesContrib = rs2.getInt(2); postalLookups = rs2.getInt(3); artVisits = rs2.getInt(4); legalQueries = rs2.getInt(5); analysisUploads = rs2.getInt(6); }
                rs2.close(); ps2.close(); conn2.close();
            } catch (Exception ignored) {}
        }

    } catch (Exception e) { errorMsg = "Database error."; }
    if (conn != null) try { conn.close(); } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Profile — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
        <li><a href="analysis.jsp">Analysis</a></li>
        <li><a href="legal.jsp">Legal</a></li>
        <li><a href="data.jsp">Data</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="profile.jsp" class="active">Profile</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <% if (sessionUserId != null) { %>
            <span class="nav-session-label"><%= esc(sessionUsername) %></span>
            <a href="messaging.jsp?action=logout" class="nav-cta" style="background:transparent;border:1px solid var(--border);color:var(--text-secondary);">Logout</a>
        <% } else { %>
            <a href="messaging.jsp" class="nav-cta">Login</a>
        <% } %>
    </div>
</div></nav>

<section class="hero" style="padding:3rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Account</span>
        <h1>Profile</h1>
        <p>Your activity across BMA science categories. View and edit your profile.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner" style="max-width:800px;">

        <% if (successMsg != null) { %><div style="padding:0.6rem 1rem;border-radius:8px;font-size:0.8rem;margin-bottom:1rem;background:rgba(34,197,94,0.1);border:1px solid rgba(34,197,94,0.3);color:#4ade80;"><%= esc(successMsg) %></div><% } %>
        <% if (errorMsg != null) { %><div style="padding:0.6rem 1rem;border-radius:8px;font-size:0.8rem;margin-bottom:1rem;background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#f87171;"><%= esc(errorMsg) %></div><% } %>

        <!-- Search -->
        <form method="get" action="profile.jsp" style="display:flex;gap:0.5rem;margin-bottom:2rem;">
            <input type="text" name="user" placeholder="Look up user by username..." value="<%= viewUser != null ? esc(viewUser) : "" %>" style="flex:1;background:var(--bg-card);border:1px solid var(--border);border-radius:var(--radius);padding:0.5rem 0.75rem;color:var(--text-primary);font-size:0.85rem;"/>
            <button type="submit" class="btn btn-primary btn-sm">View</button>
        </form>

        <% if (!dbOk) { %>
        <p style="color:var(--accent);">Database offline.</p>

        <% } else if (!profileFound && sessionUserId == null && (viewUser == null || viewUser.isEmpty())) { %>
        <div style="text-align:center;padding:3rem;color:var(--text-secondary);">
            <h3 style="margin-bottom:0.5rem;">Not logged in</h3>
            <p>Log in via <a href="messaging.jsp">Messages</a> to view your profile.</p>
        </div>

        <% } else if (!profileFound && viewUser != null) { %>
        <div style="text-align:center;padding:2rem;color:var(--text-secondary);">
            <p>User "<strong><%= esc(viewUser) %></strong>" not found.</p>
        </div>

        <% } else if (profileFound) { %>

        <!-- Profile Card -->
        <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:var(--radius-lg);padding:2rem;text-align:center;margin-bottom:1.5rem;">
            <div style="width:80px;height:80px;border-radius:50%;background:var(--accent);display:flex;align-items:center;justify-content:center;font-size:2rem;font-weight:700;color:#fff;margin:0 auto 1rem;">
                <%= profileData.containsKey("Username") ? profileData.get("Username").substring(0,1).toUpperCase() : "?" %>
            </div>
            <div style="font-size:1.25rem;font-weight:700;margin-bottom:0.2rem;"><%= profileData.getOrDefault("Display Name", "—") %></div>
            <div style="font-size:0.8rem;color:var(--text-secondary);margin-bottom:1.25rem;">@<%= profileData.getOrDefault("Username", "—") %> · <%= profileData.getOrDefault("Role", "Member") %></div>

            <!-- BMA Activity Stats -->
            <div style="display:grid;grid-template-columns:repeat(4, 1fr);gap:0.75rem;max-width:500px;margin:0 auto;">
                <div style="text-align:center;"><div style="font-size:1.25rem;font-weight:700;color:var(--accent);"><%= postCount %></div><div style="font-size:0.6rem;color:var(--text-muted);text-transform:uppercase;">Posts</div></div>
                <div style="text-align:center;"><div style="font-size:1.25rem;font-weight:700;color:#3b82f6;"><%= scienceInputs %></div><div style="font-size:0.6rem;color:var(--text-muted);text-transform:uppercase;">Science</div></div>
                <div style="text-align:center;"><div style="font-size:1.25rem;font-weight:700;color:#22c55e;"><%= speciesContrib %></div><div style="font-size:0.6rem;color:var(--text-muted);text-transform:uppercase;">Species</div></div>
                <div style="text-align:center;"><div style="font-size:1.25rem;font-weight:700;color:#a855f7;"><%= groupCount %></div><div style="font-size:0.6rem;color:var(--text-muted);text-transform:uppercase;">Groups</div></div>
            </div>
        </div>

        <!-- Profile Information Table -->
        <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:var(--radius-lg);padding:1.25rem;margin-bottom:1.5rem;">
            <h3 style="font-size:0.75rem;font-weight:600;text-transform:uppercase;letter-spacing:0.04em;color:var(--text-muted);margin-bottom:0.75rem;">Profile Information</h3>
            <% for (Map.Entry<String, String> entry : profileData.entrySet()) { %>
            <div style="display:flex;justify-content:space-between;padding:0.4rem 0;border-bottom:1px solid var(--border);">
                <span style="font-size:0.8rem;color:var(--text-muted);"><%= esc(entry.getKey()) %></span>
                <span style="font-size:0.8rem;color:var(--text-primary);font-weight:500;"><%= entry.getValue() %></span>
            </div>
            <% } %>
        </div>

        <!-- BMA Science Category Breakdown -->
        <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:var(--radius-lg);padding:1.25rem;margin-bottom:1.5rem;">
            <h3 style="font-size:0.75rem;font-weight:600;text-transform:uppercase;letter-spacing:0.04em;color:var(--text-muted);margin-bottom:0.75rem;">Science Category Activity</h3>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:0.4rem;">
                <div style="display:flex;justify-content:space-between;padding:0.4rem 0;border-bottom:1px solid var(--border);"><span style="font-size:0.8rem;color:#3b82f6;">Science Inputs</span><span style="font-size:0.8rem;font-weight:600;"><%= scienceInputs %></span></div>
                <div style="display:flex;justify-content:space-between;padding:0.4rem 0;border-bottom:1px solid var(--border);"><span style="font-size:0.8rem;color:#22c55e;">Species Contributions</span><span style="font-size:0.8rem;font-weight:600;"><%= speciesContrib %></span></div>
                <div style="display:flex;justify-content:space-between;padding:0.4rem 0;border-bottom:1px solid var(--border);"><span style="font-size:0.8rem;color:#ef4444;">Postal Lookups</span><span style="font-size:0.8rem;font-weight:600;"><%= postalLookups %></span></div>
                <div style="display:flex;justify-content:space-between;padding:0.4rem 0;border-bottom:1px solid var(--border);"><span style="font-size:0.8rem;color:#a855f7;">Art Visits</span><span style="font-size:0.8rem;font-weight:600;"><%= artVisits %></span></div>
                <div style="display:flex;justify-content:space-between;padding:0.4rem 0;border-bottom:1px solid var(--border);"><span style="font-size:0.8rem;color:#06b6d4;">Legal Queries</span><span style="font-size:0.8rem;font-weight:600;"><%= legalQueries %></span></div>
                <div style="display:flex;justify-content:space-between;padding:0.4rem 0;"><span style="font-size:0.8rem;color:#ec4899;">Analysis Uploads</span><span style="font-size:0.8rem;font-weight:600;"><%= analysisUploads %></span></div>
            </div>
        </div>

        <!-- Edit (self only) -->
        <% if (viewingSelf) { %>
        <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:var(--radius-lg);padding:1.25rem;">
            <h3 style="font-size:0.75rem;font-weight:600;text-transform:uppercase;letter-spacing:0.04em;color:var(--text-muted);margin-bottom:0.75rem;">Edit Profile</h3>
            <form method="post" action="profile.jsp">
                <input type="hidden" name="action" value="update"/>
                <label style="font-size:0.7rem;color:var(--text-muted);display:block;margin-bottom:0.2rem;">Display Name</label>
                <input type="text" name="display_name" value="<%= esc(sessionDisplayName) %>" style="width:100%;background:var(--bg-section);border:1px solid var(--border);border-radius:var(--radius);padding:0.5rem 0.75rem;color:var(--text-primary);font-size:0.85rem;margin-bottom:0.75rem;"/>
                <label style="font-size:0.7rem;color:var(--text-muted);display:block;margin-bottom:0.2rem;">Email</label>
                <input type="email" name="email" value="<%= profileData.getOrDefault("Email", "") %>" placeholder="Email (optional)" style="width:100%;background:var(--bg-section);border:1px solid var(--border);border-radius:var(--radius);padding:0.5rem 0.75rem;color:var(--text-primary);font-size:0.85rem;margin-bottom:0.75rem;"/>
                <button type="submit" class="btn btn-primary btn-sm">Save Changes</button>
            </form>
        </div>
        <% } %>

        <% } %>
    </div>
</section>

<footer class="footer"><div class="footer-bottom" style="border:none;padding:0;">
    <span>&#169; 2026 MEARVK LLC — Brarner.M.Alete™ — Profile</span>
</div></footer>
</body>
</html>
