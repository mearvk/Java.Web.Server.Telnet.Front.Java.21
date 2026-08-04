<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest, java.nio.charset.StandardCharsets" %>
<%!
    static String hashPassword(String password, String salt) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest((salt + password).getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) { return ""; }
    }
    static String generateSalt() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder sb = new StringBuilder(); java.util.Random r = new java.util.Random();
        for (int i = 0; i < 16; i++) sb.append(chars.charAt(r.nextInt(chars.length())));
        return sb.toString();
    }
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String timeAgo(Timestamp ts) {
        if (ts == null) return "";
        long diff = System.currentTimeMillis() - ts.getTime(); long mins = diff / 60000;
        if (mins < 1) return "just now"; if (mins < 60) return mins + "m ago";
        long hrs = mins / 60; if (hrs < 24) return hrs + "h ago";
        long days = hrs / 24; if (days < 30) return days + "d ago";
        return new java.text.SimpleDateFormat("MMM d, yyyy").format(ts);
    }
%>
<%
    // ═══════════════════════════════════════════════════════════════════
    // NitroWebExpress™ — Messaging Page (Generic Template)
    // Drop this file into any module's webapp as messaging.jsp.
    // Only change: MODULE_NAME and nav links.
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
    Boolean sessionAdmin = (Boolean) session.getAttribute("msg_admin");
    if (sessionAdmin == null) sessionAdmin = false;

    String action = request.getParameter("action");
    String errorMsg = null;
    String successMsg = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        dbOk = true;

        if ("login".equals(action) && "POST".equals(request.getMethod())) {
            String u = request.getParameter("username"); String p = request.getParameter("password");
            if (u != null && p != null && !u.isEmpty() && !p.isEmpty()) {
                PreparedStatement ps = conn.prepareStatement("SELECT id, username, display_name, password_hash, salt, is_admin, is_banned FROM msg_users WHERE username = ?");
                ps.setString(1, u.trim()); ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    if (rs.getBoolean("is_banned")) { errorMsg = "Account is suspended."; }
                    else if (hashPassword(p, rs.getString("salt")).equals(rs.getString("password_hash"))) {
                        session.setAttribute("msg_user_id", rs.getInt("id"));
                        session.setAttribute("msg_username", rs.getString("username"));
                        session.setAttribute("msg_display_name", rs.getString("display_name"));
                        session.setAttribute("msg_admin", rs.getBoolean("is_admin"));
                        sessionUserId = rs.getInt("id"); sessionUsername = rs.getString("username"); sessionAdmin = rs.getBoolean("is_admin");
                        successMsg = "Logged in.";
                        PreparedStatement up = conn.prepareStatement("UPDATE msg_users SET last_active = NOW() WHERE id = ?");
                        up.setInt(1, sessionUserId); up.executeUpdate(); up.close();
                    } else { errorMsg = "Invalid password."; }
                } else { errorMsg = "User not found."; }
                rs.close(); ps.close();
            }
        }

        if ("register".equals(action) && "POST".equals(request.getMethod())) {
            String u = request.getParameter("reg_username"); String p = request.getParameter("reg_password");
            String dn = request.getParameter("reg_displayname"); String em = request.getParameter("reg_email");
            if (u != null && p != null && !u.isEmpty() && p.length() >= 4) {
                String salt = generateSalt(); String hash = hashPassword(p, salt);
                try {
                    PreparedStatement ps = conn.prepareStatement("INSERT INTO msg_users (username, display_name, password_hash, salt, email) VALUES (?, ?, ?, ?, ?)", Statement.RETURN_GENERATED_KEYS);
                    ps.setString(1, u.trim()); ps.setString(2, (dn != null && !dn.isEmpty()) ? dn.trim() : u.trim());
                    ps.setString(3, hash); ps.setString(4, salt); ps.setString(5, em); ps.executeUpdate();
                    ResultSet keys = ps.getGeneratedKeys();
                    if (keys.next()) { session.setAttribute("msg_user_id", keys.getInt(1)); session.setAttribute("msg_username", u.trim());
                        session.setAttribute("msg_admin", false); sessionUserId = keys.getInt(1); sessionUsername = u.trim(); sessionAdmin = false; }
                    keys.close(); ps.close(); successMsg = "Account created!";
                } catch (SQLIntegrityConstraintViolationException ex) { errorMsg = "Username taken."; }
            } else { errorMsg = "Username required, password 4+ chars."; }
        }

        if ("logout".equals(action)) {
            session.removeAttribute("msg_user_id"); session.removeAttribute("msg_username");
            session.removeAttribute("msg_display_name"); session.removeAttribute("msg_admin");
            sessionUserId = null; sessionUsername = null; sessionAdmin = false; successMsg = "Logged out.";
        }

        if ("post".equals(action) && "POST".equals(request.getMethod())) {
            String content = request.getParameter("content"); String title = request.getParameter("post_title");
            String postType = request.getParameter("post_type"); String anonName = request.getParameter("anon_name");
            String subgroupParam = request.getParameter("subgroup_id"); String parentParam = request.getParameter("parent_id");
            if (postType == null || postType.isEmpty()) postType = "message";
            if (content != null && !content.trim().isEmpty()) {
                PreparedStatement ps = conn.prepareStatement("INSERT INTO msg_posts (module_name, subgroup_id, user_id, anonymous_name, title, content, post_type, parent_id, ip_address) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
                ps.setString(1, MODULE_NAME);
                ps.setObject(2, (subgroupParam != null && !subgroupParam.isEmpty()) ? Integer.parseInt(subgroupParam) : null);
                ps.setObject(3, sessionUserId);
                ps.setString(4, (sessionUserId == null) ? ((anonName != null && !anonName.isEmpty()) ? anonName.trim() : "Anonymous") : null);
                ps.setString(5, (title != null && !title.trim().isEmpty()) ? title.trim() : null);
                ps.setString(6, content.trim()); ps.setString(7, postType);
                ps.setObject(8, (parentParam != null && !parentParam.isEmpty()) ? Long.parseLong(parentParam) : null);
                ps.setString(9, request.getRemoteAddr()); ps.executeUpdate(); ps.close(); successMsg = "Posted.";
            } else { errorMsg = "Content cannot be empty."; }
        }

        if ("edit".equals(action) && "POST".equals(request.getMethod())) {
            String postId = request.getParameter("post_id"); String content = request.getParameter("edit_content"); String title = request.getParameter("edit_title");
            if (postId != null && content != null && !content.trim().isEmpty()) {
                String where = sessionAdmin ? "" : " AND user_id = ?";
                PreparedStatement ps = conn.prepareStatement("UPDATE msg_posts SET content = ?, title = ?, edit_count = edit_count + 1 WHERE id = ? AND is_deleted = FALSE" + where);
                ps.setString(1, content.trim()); ps.setString(2, (title != null && !title.trim().isEmpty()) ? title.trim() : null);
                ps.setLong(3, Long.parseLong(postId));
                if (!sessionAdmin && sessionUserId != null) ps.setInt(4, sessionUserId);
                int rows = ps.executeUpdate(); ps.close();
                if (rows > 0) successMsg = "Updated."; else errorMsg = "Cannot edit.";
            }
        }

        if ("delete".equals(action)) {
            String postId = request.getParameter("post_id");
            if (postId != null) {
                String where = sessionAdmin ? "" : " AND user_id = ?";
                PreparedStatement ps = conn.prepareStatement("UPDATE msg_posts SET is_deleted = TRUE WHERE id = ?" + where);
                ps.setLong(1, Long.parseLong(postId));
                if (!sessionAdmin && sessionUserId != null) ps.setInt(2, sessionUserId);
                int rows = ps.executeUpdate(); ps.close();
                if (rows > 0) successMsg = "Deleted."; else errorMsg = "Cannot delete.";
            }
        }

        if ("create_group".equals(action) && "POST".equals(request.getMethod()) && sessionUserId != null) {
            String gName = request.getParameter("group_name"); String gDesc = request.getParameter("group_desc");
            if (gName != null && !gName.trim().isEmpty()) {
                String slug = gName.trim().toLowerCase().replaceAll("[^a-z0-9]+", "-").replaceAll("^-|-$", "");
                try {
                    PreparedStatement ps = conn.prepareStatement("INSERT INTO msg_subgroups (group_name, group_slug, description, owner_id, module_name) VALUES (?, ?, ?, ?, ?)", Statement.RETURN_GENERATED_KEYS);
                    ps.setString(1, gName.trim()); ps.setString(2, slug); ps.setString(3, gDesc); ps.setInt(4, sessionUserId); ps.setString(5, MODULE_NAME);
                    ps.executeUpdate(); ResultSet keys = ps.getGeneratedKeys(); int gid = 0;
                    if (keys.next()) gid = keys.getInt(1); keys.close(); ps.close();
                    if (gid > 0) { ps = conn.prepareStatement("INSERT INTO msg_subgroup_members (subgroup_id, user_id, role) VALUES (?, ?, 'owner')");
                        ps.setInt(1, gid); ps.setInt(2, sessionUserId); ps.executeUpdate(); ps.close(); }
                    successMsg = "Group created.";
                } catch (SQLIntegrityConstraintViolationException ex) { errorMsg = "Group name exists."; }
            }
        }

        if ("delete_group".equals(action)) {
            String gid = request.getParameter("group_id");
            if (gid != null) {
                String where = sessionAdmin ? "" : " AND owner_id = ?";
                PreparedStatement ps = conn.prepareStatement("UPDATE msg_subgroups SET is_archived = TRUE WHERE id = ?" + where);
                ps.setInt(1, Integer.parseInt(gid));
                if (!sessionAdmin && sessionUserId != null) ps.setInt(2, sessionUserId);
                ps.executeUpdate(); ps.close(); successMsg = "Group archived.";
            }
        }
    } catch (Exception e) { if (dbOk) errorMsg = "Error: " + e.getMessage(); }

    // Fetch data
    List<Map<String, Object>> posts = new ArrayList<>();
    List<Map<String, Object>> subgroups = new ArrayList<>();
    String viewGroup = request.getParameter("group");

    if (dbOk && conn != null) {
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT sg.*, u.username as owner_name, (SELECT COUNT(*) FROM msg_posts WHERE subgroup_id = sg.id AND is_deleted = FALSE) as post_count FROM msg_subgroups sg LEFT JOIN msg_users u ON sg.owner_id = u.id WHERE sg.module_name = ? AND sg.is_archived = FALSE ORDER BY sg.created_at DESC");
            ps.setString(1, MODULE_NAME); ResultSet rs = ps.executeQuery();
            while (rs.next()) { Map<String, Object> g = new HashMap<>(); g.put("id", rs.getInt("id")); g.put("group_name", rs.getString("group_name")); g.put("owner_id", rs.getInt("owner_id")); g.put("post_count", rs.getInt("post_count")); subgroups.add(g); }
            rs.close(); ps.close();

            String pq; if (viewGroup != null && !viewGroup.isEmpty()) {
                pq = "SELECT p.*, u.username, u.display_name, u.avatar_color FROM msg_posts p LEFT JOIN msg_users u ON p.user_id = u.id WHERE p.module_name = ? AND p.subgroup_id = ? AND p.is_deleted = FALSE AND p.parent_id IS NULL ORDER BY p.is_pinned DESC, p.created_at DESC LIMIT 50";
                ps = conn.prepareStatement(pq); ps.setString(1, MODULE_NAME); ps.setInt(2, Integer.parseInt(viewGroup));
            } else {
                pq = "SELECT p.*, u.username, u.display_name, u.avatar_color FROM msg_posts p LEFT JOIN msg_users u ON p.user_id = u.id WHERE p.module_name = ? AND p.subgroup_id IS NULL AND p.is_deleted = FALSE AND p.parent_id IS NULL ORDER BY p.is_pinned DESC, p.created_at DESC LIMIT 50";
                ps = conn.prepareStatement(pq); ps.setString(1, MODULE_NAME);
            }
            rs = ps.executeQuery();
            while (rs.next()) { Map<String, Object> post = new HashMap<>(); post.put("id", rs.getLong("id")); post.put("title", rs.getString("title")); post.put("content", rs.getString("content")); post.put("post_type", rs.getString("post_type")); post.put("user_id", rs.getObject("user_id")); post.put("username", rs.getString("username")); post.put("display_name", rs.getString("display_name")); post.put("avatar_color", rs.getString("avatar_color")); post.put("anonymous_name", rs.getString("anonymous_name")); post.put("is_pinned", rs.getBoolean("is_pinned")); post.put("edit_count", rs.getInt("edit_count")); post.put("created_at", rs.getTimestamp("created_at")); posts.add(post); }
            rs.close(); ps.close();
        } catch (Exception e) {}
    }
    if (conn != null) try { conn.close(); } catch (Exception e) {}

    // ── Module-specific config (change these per module) ──
    String NAV_BRAND = MODULE_NAME;
    String THEME_ACCENT = "#3b82f6";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <title>Messages — <%= esc(NAV_BRAND) %></title>
    <link rel="stylesheet" href="css/style.css"/>
    <style>
        .msg-page { max-width:900px; margin:0 auto; padding:2rem; }
        .msg-header { margin-bottom:2rem; }
        .msg-header h1 { font-size:1.5rem; font-weight:700; margin-bottom:0.25rem; }
        .msg-header p { font-size:0.85rem; color:#a1a1aa; }
        .msg-tabs { display:flex; gap:0.5rem; margin-bottom:1.5rem; flex-wrap:wrap; }
        .msg-tab { font-size:0.75rem; padding:0.35rem 0.75rem; border-radius:6px; border:1px solid #27272a; color:#a1a1aa; text-decoration:none; transition:all 0.15s; }
        .msg-tab:hover { border-color:<%= THEME_ACCENT %>; color:#fff; text-decoration:none; }
        .msg-tab.active { background:<%= THEME_ACCENT %>; border-color:<%= THEME_ACCENT %>; color:#fff; }
        .auth-row { display:flex; gap:1rem; margin-bottom:1.5rem; flex-wrap:wrap; }
        .auth-mini { background:#111118; border:1px solid #27272a; border-radius:8px; padding:0.75rem; flex:1; min-width:200px; }
        .auth-mini h4 { font-size:0.75rem; font-weight:600; margin-bottom:0.5rem; color:#fff; }
        .auth-mini input { width:100%; background:#1a1a24; border:1px solid #27272a; border-radius:6px; padding:0.4rem 0.6rem; color:#fff; font-size:0.8rem; margin-bottom:0.4rem; }
        .auth-mini input:focus { outline:none; border-color:<%= THEME_ACCENT %>; }
        .compose-box { background:#111118; border:1px solid #27272a; border-radius:10px; padding:1.25rem; margin-bottom:1.5rem; }
        .compose-box textarea { width:100%; min-height:80px; background:#1a1a24; border:1px solid #27272a; border-radius:8px; padding:0.75rem; color:#fff; font-size:0.85rem; font-family:inherit; resize:vertical; }
        .compose-box textarea:focus { outline:none; border-color:<%= THEME_ACCENT %>; }
        .compose-box input[type=text] { background:#1a1a24; border:1px solid #27272a; border-radius:6px; padding:0.4rem 0.6rem; color:#fff; font-size:0.8rem; margin-bottom:0.5rem; }
        .compose-bar { display:flex; align-items:center; gap:0.5rem; margin-top:0.5rem; }
        .type-sel { font-size:0.7rem; padding:0.2rem 0.5rem; border-radius:10px; border:1px solid #27272a; color:#71717a; cursor:pointer; }
        .type-sel.active { background:<%= THEME_ACCENT %>; border-color:<%= THEME_ACCENT %>; color:#fff; }
        .post-item { background:#111118; border:1px solid #27272a; border-radius:10px; padding:1rem; margin-bottom:0.75rem; transition:border-color 0.15s; }
        .post-item:hover { border-color:rgba(59,130,246,0.3); }
        .post-item.pinned { border-left:3px solid <%= THEME_ACCENT %>; }
        .pi-head { display:flex; align-items:center; gap:0.5rem; margin-bottom:0.4rem; }
        .pi-avatar { width:24px; height:24px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:0.6rem; font-weight:700; color:#fff; }
        .pi-name { font-size:0.8rem; font-weight:600; }
        .pi-time { font-size:0.65rem; color:#71717a; margin-left:auto; }
        .pi-badge { font-size:0.55rem; text-transform:uppercase; padding:0.1rem 0.35rem; border-radius:3px; font-weight:600; }
        .pi-badge-message { background:rgba(59,130,246,0.15); color:#60a5fa; }
        .pi-badge-concern { background:rgba(239,68,68,0.15); color:#f87171; }
        .pi-badge-idea { background:rgba(34,197,94,0.15); color:#4ade80; }
        .pi-title { font-size:0.9rem; font-weight:600; margin-bottom:0.3rem; }
        .pi-body { font-size:0.82rem; color:#a1a1aa; white-space:pre-wrap; word-wrap:break-word; line-height:1.5; }
        .pi-foot { display:flex; gap:0.75rem; margin-top:0.5rem; padding-top:0.4rem; border-top:1px solid #27272a; }
        .pi-act { font-size:0.65rem; color:#71717a; cursor:pointer; background:none; border:none; font-family:inherit; }
        .pi-act:hover { color:<%= THEME_ACCENT %>; }
        .flash { padding:0.5rem 0.75rem; border-radius:6px; font-size:0.8rem; margin-bottom:1rem; }
        .flash-e { background:rgba(239,68,68,0.1); border:1px solid rgba(239,68,68,0.3); color:#f87171; }
        .flash-s { background:rgba(34,197,94,0.1); border:1px solid rgba(34,197,94,0.3); color:#4ade80; }
        .new-group { display:flex; gap:0.5rem; align-items:center; margin-bottom:1rem; }
        .new-group input { background:#1a1a24; border:1px solid #27272a; border-radius:6px; padding:0.4rem 0.6rem; color:#fff; font-size:0.75rem; flex:1; }
        .empty { text-align:center; padding:3rem 1rem; color:#71717a; }
    </style>
</head>
<body>
<%-- NOTE: Replace this nav with the module's standard nav --%>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand"><%= esc(NAV_BRAND) %>™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Home</a></li>
        <li><a href="messaging.jsp" class="active">Messages</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <% if (sessionUserId != null) { %>
            <span style="font-size:0.8rem;color:<%= THEME_ACCENT %>;"><%= esc(sessionUsername) %></span>
            <a href="messaging.jsp?action=logout" class="nav-cta" style="background:transparent;border:1px solid #27272a;color:#a1a1aa;">Logout</a>
        <% } %>
    </div>
</div></nav>

<div class="msg-page">
    <div class="msg-header">
        <h1>Messages</h1>
        <p>Share messages, concerns, or ideas. Anonymous posting welcome. Sign in to create subgroups.</p>
    </div>

    <% if (errorMsg != null) { %><div class="flash flash-e"><%= esc(errorMsg) %></div><% } %>
    <% if (successMsg != null) { %><div class="flash flash-s"><%= esc(successMsg) %></div><% } %>

    <%-- Auth row (shown when not logged in) --%>
    <% if (sessionUserId == null) { %>
    <div class="auth-row">
        <div class="auth-mini">
            <h4>Login</h4>
            <form method="post" action="messaging.jsp"><input type="hidden" name="action" value="login"/>
                <input type="text" name="username" placeholder="Username" required/>
                <input type="password" name="password" placeholder="Password" required/>
                <button type="submit" class="btn btn-primary btn-sm" style="width:100%;">Login</button></form>
        </div>
        <div class="auth-mini">
            <h4>Register</h4>
            <form method="post" action="messaging.jsp"><input type="hidden" name="action" value="register"/>
                <input type="text" name="reg_username" placeholder="Username" required/>
                <input type="password" name="reg_password" placeholder="Password (4+)" required minlength="4"/>
                <input type="text" name="reg_displayname" placeholder="Display Name (optional)"/>
                <input type="email" name="reg_email" placeholder="Email (optional)"/>
                <button type="submit" class="btn btn-primary btn-sm" style="width:100%;">Register</button></form>
        </div>
    </div>
    <% } %>

    <%-- Channel tabs --%>
    <div class="msg-tabs">
        <a href="messaging.jsp" class="msg-tab <%= (viewGroup == null || viewGroup.isEmpty()) ? "active" : "" %>">General</a>
        <% for (Map<String, Object> g : subgroups) { %>
        <a href="messaging.jsp?group=<%= g.get("id") %>" class="msg-tab <%= String.valueOf(g.get("id")).equals(viewGroup) ? "active" : "" %>"><%= esc((String)g.get("group_name")) %> (<%= g.get("post_count") %>)</a>
        <% } %>
    </div>

    <%-- Create subgroup (profiled users) --%>
    <% if (sessionUserId != null) { %>
    <form method="post" action="messaging.jsp" class="new-group">
        <input type="hidden" name="action" value="create_group"/>
        <input type="text" name="group_name" placeholder="New subgroup name..."/>
        <input type="text" name="group_desc" placeholder="Description (optional)"/>
        <button type="submit" class="btn btn-primary btn-sm">+ Group</button>
    </form>
    <% } %>

    <%-- Compose --%>
    <div class="compose-box">
        <form method="post" action="messaging.jsp<%= (viewGroup != null && !viewGroup.isEmpty()) ? "?group=" + viewGroup : "" %>">
            <input type="hidden" name="action" value="post"/>
            <% if (viewGroup != null && !viewGroup.isEmpty()) { %><input type="hidden" name="subgroup_id" value="<%= viewGroup %>"/><% } %>
            <div style="display:flex;gap:0.5rem;margin-bottom:0.5rem;flex-wrap:wrap;">
                <input type="text" name="post_title" placeholder="Title (optional)" style="flex:1;min-width:120px;"/>
                <% if (sessionUserId == null) { %><input type="text" name="anon_name" placeholder="Your name (optional)" style="width:150px;"/><% } %>
            </div>
            <textarea name="content" placeholder="Write a message, concern, or idea..." required></textarea>
            <div class="compose-bar">
                <label class="type-sel active" onclick="this.parentNode.querySelectorAll('.type-sel').forEach(function(x){x.classList.remove('active')});this.classList.add('active');"><input type="radio" name="post_type" value="message" checked style="display:none;"/>Message</label>
                <label class="type-sel" onclick="this.parentNode.querySelectorAll('.type-sel').forEach(function(x){x.classList.remove('active')});this.classList.add('active');"><input type="radio" name="post_type" value="concern" style="display:none;"/>Concern</label>
                <label class="type-sel" onclick="this.parentNode.querySelectorAll('.type-sel').forEach(function(x){x.classList.remove('active')});this.classList.add('active');"><input type="radio" name="post_type" value="idea" style="display:none;"/>Idea</label>
                <button type="submit" class="btn btn-primary btn-sm" style="margin-left:auto;">Post</button>
            </div>
        </form>
    </div>

    <%-- Posts --%>
    <% if (posts.isEmpty()) { %>
    <div class="empty"><h3>No messages yet</h3><p>Be the first to post. No account required.</p></div>
    <% } else { for (Map<String, Object> post : posts) {
        String author = post.get("username") != null ? (String) post.get("display_name") : (String) post.get("anonymous_name");
        if (author == null || author.isEmpty()) author = "Anonymous";
        String ac = post.get("avatar_color") != null ? (String) post.get("avatar_color") : "#6b7280";
        String pt = (String) post.get("post_type"); boolean pinned = (Boolean) post.get("is_pinned");
        boolean mine = (sessionUserId != null && sessionUserId.equals(post.get("user_id"))); long pid = (Long) post.get("id");
    %>
    <div class="post-item<%= pinned ? " pinned" : "" %>">
        <div class="pi-head">
            <div class="pi-avatar" style="background:<%= ac %>;"><%= author.substring(0,1).toUpperCase() %></div>
            <span class="pi-name"><%= esc(author) %></span>
            <span class="pi-badge pi-badge-<%= pt %>"><%= pt %></span>
            <span class="pi-time"><%= timeAgo((Timestamp) post.get("created_at")) %></span>
        </div>
        <% if (post.get("title") != null && !((String)post.get("title")).isEmpty()) { %><div class="pi-title"><%= esc((String) post.get("title")) %></div><% } %>
        <div class="pi-body"><%= esc((String) post.get("content")) %></div>
        <div class="pi-foot">
            <% if (mine || sessionAdmin) { %>
            <a href="messaging.jsp?action=delete&post_id=<%= pid %><%= (viewGroup != null ? "&group=" + viewGroup : "") %>" class="pi-act" onclick="return confirm('Delete?');" style="color:#f87171;">Delete</a>
            <% } %>
            <% if ((Integer) post.get("edit_count") > 0) { %><span class="pi-act" style="cursor:default;font-style:italic;">(edited)</span><% } %>
        </div>
    </div>
    <% } } %>

    <%-- Archive group button --%>
    <% if (viewGroup != null && !viewGroup.isEmpty() && (sessionAdmin || sessionUserId != null)) {
        boolean canDel = sessionAdmin;
        if (!canDel) { for (Map<String, Object> g : subgroups) { if (String.valueOf(g.get("id")).equals(viewGroup) && sessionUserId.equals(g.get("owner_id"))) { canDel = true; break; } } }
        if (canDel) { %>
    <div style="margin-top:2rem;text-align:center;">
        <a href="messaging.jsp?action=delete_group&group_id=<%= viewGroup %>" class="btn btn-ghost btn-sm" style="color:#f87171;border-color:#f87171;" onclick="return confirm('Archive this group?');">Archive This Group</a>
    </div>
    <% } } %>
</div>

<footer style="padding:2rem;text-align:center;border-top:1px solid #27272a;color:#71717a;font-size:0.7rem;">NitroWebExpress™ — Messaging — MEARVK LLC 2026</footer>
</body>
</html>
