<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest, java.nio.charset.StandardCharsets" %>
<%!
    // Hash password with salt
    static String hashPassword(String password, String salt) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest((salt + password).getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) { return ""; }
    }

    // Generate random salt
    static String generateSalt() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder sb = new StringBuilder();
        java.util.Random r = new java.util.Random();
        for (int i = 0; i < 16; i++) sb.append(chars.charAt(r.nextInt(chars.length())));
        return sb.toString();
    }

    // Escape HTML
    static String esc(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
    }

    // Time ago
    static String timeAgo(Timestamp ts) {
        if (ts == null) return "";
        long diff = System.currentTimeMillis() - ts.getTime();
        long mins = diff / 60000;
        if (mins < 1) return "just now";
        if (mins < 60) return mins + "m ago";
        long hrs = mins / 60;
        if (hrs < 24) return hrs + "h ago";
        long days = hrs / 24;
        if (days < 30) return days + "d ago";
        return new java.text.SimpleDateFormat("MMM d, yyyy").format(ts);
    }
%>
<%
    // ═══════════════════════════════════════════════════════════════════
    // NitroWebExpress™ — Messaging Page (messaging.jsp)
    // Cross-module posting: anonymous or profiled users.
    // Profiled users can create subgroups. Admin has full CRUD.
    // ═══════════════════════════════════════════════════════════════════

    // Module identification (set per-module or detect from context)
    String MODULE_NAME = (String) application.getAttribute("NWE_MODULE_NAME");
    if (MODULE_NAME == null) {
        MODULE_NAME = request.getContextPath().replaceAll("^/", "");
        if (MODULE_NAME.isEmpty()) MODULE_NAME = "general";
    }

    // DB connection
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_messaging";
    String dbUser = "root";
    String dbPass = "$$Ironman1";
    Connection conn = null;
    boolean dbOk = false;

    // Session user
    Integer sessionUserId = (Integer) session.getAttribute("msg_user_id");
    String sessionUsername = (String) session.getAttribute("msg_username");
    Boolean sessionAdmin = (Boolean) session.getAttribute("msg_admin");
    if (sessionAdmin == null) sessionAdmin = false;

    // Action handling
    String action = request.getParameter("action");
    String errorMsg = null;
    String successMsg = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        dbOk = true;

        // === ACTION: Login ===
        if ("login".equals(action) && "POST".equals(request.getMethod())) {
            String u = request.getParameter("username");
            String p = request.getParameter("password");
            if (u != null && p != null && !u.isEmpty() && !p.isEmpty()) {
                PreparedStatement ps = conn.prepareStatement("SELECT id, username, display_name, password_hash, salt, is_admin, is_banned FROM msg_users WHERE username = ?");
                ps.setString(1, u.trim());
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    if (rs.getBoolean("is_banned")) { errorMsg = "Account is suspended."; }
                    else {
                        String storedHash = rs.getString("password_hash");
                        String salt = rs.getString("salt");
                        if (hashPassword(p, salt).equals(storedHash)) {
                            session.setAttribute("msg_user_id", rs.getInt("id"));
                            session.setAttribute("msg_username", rs.getString("username"));
                            session.setAttribute("msg_display_name", rs.getString("display_name"));
                            session.setAttribute("msg_admin", rs.getBoolean("is_admin"));
                            sessionUserId = rs.getInt("id");
                            sessionUsername = rs.getString("username");
                            sessionAdmin = rs.getBoolean("is_admin");
                            successMsg = "Logged in as " + esc(sessionUsername);
                            // Update last_active
                            PreparedStatement up = conn.prepareStatement("UPDATE msg_users SET last_active = NOW() WHERE id = ?");
                            up.setInt(1, sessionUserId); up.executeUpdate(); up.close();
                        } else { errorMsg = "Invalid password."; }
                    }
                } else { errorMsg = "User not found."; }
                rs.close(); ps.close();
            }
        }

        // === ACTION: Register ===
        if ("register".equals(action) && "POST".equals(request.getMethod())) {
            String u = request.getParameter("reg_username");
            String p = request.getParameter("reg_password");
            String dn = request.getParameter("reg_displayname");
            String em = request.getParameter("reg_email");
            if (u != null && p != null && !u.isEmpty() && p.length() >= 4) {
                String salt = generateSalt();
                String hash = hashPassword(p, salt);
                try {
                    PreparedStatement ps = conn.prepareStatement("INSERT INTO msg_users (username, display_name, password_hash, salt, email) VALUES (?, ?, ?, ?, ?)", Statement.RETURN_GENERATED_KEYS);
                    ps.setString(1, u.trim());
                    ps.setString(2, (dn != null && !dn.isEmpty()) ? dn.trim() : u.trim());
                    ps.setString(3, hash);
                    ps.setString(4, salt);
                    ps.setString(5, em);
                    ps.executeUpdate();
                    ResultSet keys = ps.getGeneratedKeys();
                    if (keys.next()) {
                        session.setAttribute("msg_user_id", keys.getInt(1));
                        session.setAttribute("msg_username", u.trim());
                        session.setAttribute("msg_display_name", (dn != null && !dn.isEmpty()) ? dn.trim() : u.trim());
                        session.setAttribute("msg_admin", false);
                        sessionUserId = keys.getInt(1);
                        sessionUsername = u.trim();
                        sessionAdmin = false;
                        successMsg = "Account created. Welcome, " + esc(sessionUsername) + "!";
                    }
                    keys.close(); ps.close();
                } catch (SQLIntegrityConstraintViolationException ex) { errorMsg = "Username already taken."; }
            } else { errorMsg = "Username required, password must be 4+ characters."; }
        }

        // === ACTION: Logout ===
        if ("logout".equals(action)) {
            session.removeAttribute("msg_user_id");
            session.removeAttribute("msg_username");
            session.removeAttribute("msg_display_name");
            session.removeAttribute("msg_admin");
            sessionUserId = null; sessionUsername = null; sessionAdmin = false;
            successMsg = "Logged out.";
        }

        // === ACTION: Post ===
        if ("post".equals(action) && "POST".equals(request.getMethod())) {
            String content = request.getParameter("content");
            String title = request.getParameter("post_title");
            String postType = request.getParameter("post_type");
            String anonName = request.getParameter("anon_name");
            String subgroupParam = request.getParameter("subgroup_id");
            String parentParam = request.getParameter("parent_id");
            if (postType == null || postType.isEmpty()) postType = "message";
            if (content != null && !content.trim().isEmpty()) {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO msg_posts (module_name, subgroup_id, user_id, anonymous_name, title, content, post_type, parent_id, ip_address) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
                ps.setString(1, MODULE_NAME);
                ps.setObject(2, (subgroupParam != null && !subgroupParam.isEmpty()) ? Integer.parseInt(subgroupParam) : null);
                ps.setObject(3, sessionUserId);
                ps.setString(4, (sessionUserId == null) ? ((anonName != null && !anonName.isEmpty()) ? anonName.trim() : "Anonymous") : null);
                ps.setString(5, (title != null && !title.trim().isEmpty()) ? title.trim() : null);
                ps.setString(6, content.trim());
                ps.setString(7, postType);
                ps.setObject(8, (parentParam != null && !parentParam.isEmpty()) ? Long.parseLong(parentParam) : null);
                ps.setString(9, request.getRemoteAddr());
                ps.executeUpdate(); ps.close();
                successMsg = "Posted successfully.";
            } else { errorMsg = "Content cannot be empty."; }
        }

        // === ACTION: Edit Post ===
        if ("edit".equals(action) && "POST".equals(request.getMethod())) {
            String postId = request.getParameter("post_id");
            String content = request.getParameter("edit_content");
            String title = request.getParameter("edit_title");
            if (postId != null && content != null && !content.trim().isEmpty()) {
                // Only allow if admin or post owner
                String where = sessionAdmin ? "" : " AND user_id = ?";
                PreparedStatement ps = conn.prepareStatement("UPDATE msg_posts SET content = ?, title = ?, edit_count = edit_count + 1, updated_at = NOW() WHERE id = ? AND is_deleted = FALSE" + where);
                ps.setString(1, content.trim());
                ps.setString(2, (title != null && !title.trim().isEmpty()) ? title.trim() : null);
                ps.setLong(3, Long.parseLong(postId));
                if (!sessionAdmin && sessionUserId != null) ps.setInt(4, sessionUserId);
                int rows = ps.executeUpdate(); ps.close();
                if (rows > 0) successMsg = "Post updated."; else errorMsg = "Cannot edit this post.";
            }
        }

        // === ACTION: Delete Post ===
        if ("delete".equals(action)) {
            String postId = request.getParameter("post_id");
            if (postId != null) {
                String where = sessionAdmin ? "" : " AND user_id = ?";
                PreparedStatement ps = conn.prepareStatement("UPDATE msg_posts SET is_deleted = TRUE WHERE id = ?" + where);
                ps.setLong(1, Long.parseLong(postId));
                if (!sessionAdmin && sessionUserId != null) ps.setInt(2, sessionUserId);
                int rows = ps.executeUpdate(); ps.close();
                if (rows > 0) successMsg = "Post deleted."; else errorMsg = "Cannot delete this post.";
            }
        }

        // === ACTION: Create Subgroup (profiled users only) ===
        if ("create_group".equals(action) && "POST".equals(request.getMethod()) && sessionUserId != null) {
            String gName = request.getParameter("group_name");
            String gDesc = request.getParameter("group_desc");
            if (gName != null && !gName.trim().isEmpty()) {
                String slug = gName.trim().toLowerCase().replaceAll("[^a-z0-9]+", "-").replaceAll("^-|-$", "");
                try {
                    PreparedStatement ps = conn.prepareStatement("INSERT INTO msg_subgroups (group_name, group_slug, description, owner_id, module_name) VALUES (?, ?, ?, ?, ?)", Statement.RETURN_GENERATED_KEYS);
                    ps.setString(1, gName.trim());
                    ps.setString(2, slug);
                    ps.setString(3, gDesc);
                    ps.setInt(4, sessionUserId);
                    ps.setString(5, MODULE_NAME);
                    ps.executeUpdate();
                    ResultSet keys = ps.getGeneratedKeys();
                    int gid = 0;
                    if (keys.next()) gid = keys.getInt(1);
                    keys.close(); ps.close();
                    // Add owner as member
                    if (gid > 0) {
                        ps = conn.prepareStatement("INSERT INTO msg_subgroup_members (subgroup_id, user_id, role) VALUES (?, ?, 'owner')");
                        ps.setInt(1, gid); ps.setInt(2, sessionUserId); ps.executeUpdate(); ps.close();
                    }
                    successMsg = "Subgroup \"" + esc(gName.trim()) + "\" created.";
                } catch (SQLIntegrityConstraintViolationException ex) { errorMsg = "A group with that name already exists."; }
            } else { errorMsg = "Group name required."; }
        }

        // === ACTION: Delete Subgroup (admin or owner) ===
        if ("delete_group".equals(action)) {
            String gid = request.getParameter("group_id");
            if (gid != null) {
                String where = sessionAdmin ? "" : " AND owner_id = ?";
                PreparedStatement ps = conn.prepareStatement("UPDATE msg_subgroups SET is_archived = TRUE WHERE id = ?" + where);
                ps.setInt(1, Integer.parseInt(gid));
                if (!sessionAdmin && sessionUserId != null) ps.setInt(2, sessionUserId);
                int rows = ps.executeUpdate(); ps.close();
                if (rows > 0) successMsg = "Subgroup archived."; else errorMsg = "Cannot delete this group.";
            }
        }

    } catch (Exception e) {
        if (dbOk) errorMsg = "Database error: " + e.getMessage();
    }

    // === Fetch posts and subgroups for display ===
    List<Map<String, Object>> posts = new ArrayList<>();
    List<Map<String, Object>> subgroups = new ArrayList<>();
    String viewGroup = request.getParameter("group");

    if (dbOk && conn != null) {
        try {
            // Fetch subgroups for this module
            PreparedStatement ps = conn.prepareStatement(
                "SELECT sg.*, u.username as owner_name, (SELECT COUNT(*) FROM msg_posts WHERE subgroup_id = sg.id AND is_deleted = FALSE) as post_count " +
                "FROM msg_subgroups sg LEFT JOIN msg_users u ON sg.owner_id = u.id " +
                "WHERE sg.module_name = ? AND sg.is_archived = FALSE ORDER BY sg.created_at DESC");
            ps.setString(1, MODULE_NAME);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> g = new HashMap<>();
                g.put("id", rs.getInt("id"));
                g.put("group_name", rs.getString("group_name"));
                g.put("group_slug", rs.getString("group_slug"));
                g.put("description", rs.getString("description"));
                g.put("owner_id", rs.getInt("owner_id"));
                g.put("owner_name", rs.getString("owner_name"));
                g.put("post_count", rs.getInt("post_count"));
                g.put("is_public", rs.getBoolean("is_public"));
                g.put("created_at", rs.getTimestamp("created_at"));
                subgroups.add(g);
            }
            rs.close(); ps.close();

            // Fetch posts
            String postQuery;
            if (viewGroup != null && !viewGroup.isEmpty()) {
                postQuery = "SELECT p.*, u.username, u.display_name, u.avatar_color FROM msg_posts p " +
                    "LEFT JOIN msg_users u ON p.user_id = u.id " +
                    "WHERE p.module_name = ? AND p.subgroup_id = ? AND p.is_deleted = FALSE AND p.parent_id IS NULL " +
                    "ORDER BY p.is_pinned DESC, p.created_at DESC LIMIT 50";
                ps = conn.prepareStatement(postQuery);
                ps.setString(1, MODULE_NAME);
                ps.setInt(2, Integer.parseInt(viewGroup));
            } else {
                postQuery = "SELECT p.*, u.username, u.display_name, u.avatar_color FROM msg_posts p " +
                    "LEFT JOIN msg_users u ON p.user_id = u.id " +
                    "WHERE p.module_name = ? AND p.subgroup_id IS NULL AND p.is_deleted = FALSE AND p.parent_id IS NULL " +
                    "ORDER BY p.is_pinned DESC, p.created_at DESC LIMIT 50";
                ps = conn.prepareStatement(postQuery);
                ps.setString(1, MODULE_NAME);
            }
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> post = new HashMap<>();
                post.put("id", rs.getLong("id"));
                post.put("title", rs.getString("title"));
                post.put("content", rs.getString("content"));
                post.put("post_type", rs.getString("post_type"));
                post.put("user_id", rs.getObject("user_id"));
                post.put("username", rs.getString("username"));
                post.put("display_name", rs.getString("display_name"));
                post.put("avatar_color", rs.getString("avatar_color"));
                post.put("anonymous_name", rs.getString("anonymous_name"));
                post.put("is_pinned", rs.getBoolean("is_pinned"));
                post.put("edit_count", rs.getInt("edit_count"));
                post.put("created_at", rs.getTimestamp("created_at"));
                posts.add(post);
            }
            rs.close(); ps.close();
        } catch (Exception e) { /* posts remain empty */ }
    }

    if (conn != null) try { conn.close(); } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Messages — <%= esc(MODULE_NAME) %></title>
    <link rel="stylesheet" href="css/style.css"/>
    <style>
        .msg-layout { max-width:var(--max-width); margin:0 auto; padding:2rem; display:grid; grid-template-columns:260px 1fr; gap:2rem; }
        @media (max-width:768px) { .msg-layout { grid-template-columns:1fr; } }

        /* Sidebar */
        .msg-sidebar { display:flex; flex-direction:column; gap:1rem; }
        .msg-sidebar h3 { font-size:0.8rem; text-transform:uppercase; letter-spacing:0.06em; color:var(--text-muted); font-weight:600; padding:0 0.5rem; }
        .group-list { list-style:none; display:flex; flex-direction:column; gap:0.25rem; }
        .group-item { display:flex; align-items:center; gap:0.5rem; padding:0.5rem 0.75rem; border-radius:var(--radius); color:var(--text-secondary); font-size:0.8rem; text-decoration:none; transition:all 0.15s; }
        .group-item:hover { background:var(--bg-card); color:var(--text-primary); }
        .group-item.active { background:rgba(59,130,246,0.12); color:var(--accent-light); }
        .group-item .group-count { margin-left:auto; font-size:0.7rem; background:var(--bg-card); padding:0.15rem 0.5rem; border-radius:10px; color:var(--text-muted); }
        .group-item .group-dot { width:8px; height:8px; border-radius:50%; background:var(--accent); flex-shrink:0; }

        /* Auth card */
        .auth-card { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1rem; }
        .auth-card h4 { font-size:0.8rem; font-weight:600; margin-bottom:0.75rem; color:var(--text-primary); }
        .auth-card input { width:100%; background:var(--bg-card); border:1px solid var(--border); border-radius:var(--radius); padding:0.45rem 0.75rem; color:var(--text-primary); font-size:0.8rem; margin-bottom:0.5rem; }
        .auth-card input:focus { outline:none; border-color:var(--accent); }
        .auth-card button { width:100%; }
        .auth-tabs { display:flex; gap:0; margin-bottom:0.75rem; border-bottom:1px solid var(--border); }
        .auth-tab { flex:1; padding:0.4rem; font-size:0.75rem; text-align:center; color:var(--text-muted); cursor:pointer; border-bottom:2px solid transparent; background:none; border-top:none; border-left:none; border-right:none; }
        .auth-tab.active { color:var(--accent-light); border-bottom-color:var(--accent); }
        .auth-panel { display:none; }
        .auth-panel.active { display:block; }

        /* Main content */
        .msg-main { display:flex; flex-direction:column; gap:1.5rem; }

        /* Compose */
        .compose-card { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1.25rem; }
        .compose-card h3 { font-size:0.85rem; font-weight:600; margin-bottom:0.75rem; color:var(--text-primary); }
        .compose-row { display:flex; gap:0.5rem; margin-bottom:0.5rem; flex-wrap:wrap; }
        .compose-input { flex:1; min-width:120px; background:var(--bg-card); border:1px solid var(--border); border-radius:var(--radius); padding:0.45rem 0.75rem; color:var(--text-primary); font-size:0.8rem; }
        .compose-input:focus { outline:none; border-color:var(--accent); }
        .compose-textarea { width:100%; min-height:100px; background:var(--bg-card); border:1px solid var(--border); border-radius:var(--radius); padding:0.75rem; color:var(--text-primary); font-size:0.85rem; font-family:inherit; resize:vertical; line-height:1.5; }
        .compose-textarea:focus { outline:none; border-color:var(--accent); }
        .compose-actions { display:flex; align-items:center; gap:0.75rem; margin-top:0.75rem; }
        .type-pills { display:flex; gap:0.35rem; }
        .type-pill { font-size:0.7rem; padding:0.25rem 0.6rem; border-radius:12px; border:1px solid var(--border); color:var(--text-muted); cursor:pointer; transition:all 0.15s; }
        .type-pill:hover { border-color:var(--accent); color:var(--accent-light); }
        .type-pill.active { background:var(--accent); border-color:var(--accent); color:#fff; }

        /* Post cards */
        .post-card { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1.25rem; transition:border-color 0.15s; }
        .post-card:hover { border-color:rgba(59,130,246,0.3); }
        .post-card.pinned { border-left:3px solid var(--accent); }
        .post-header { display:flex; align-items:center; gap:0.6rem; margin-bottom:0.6rem; }
        .post-avatar { width:28px; height:28px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:0.7rem; font-weight:700; color:#fff; flex-shrink:0; }
        .post-meta { display:flex; flex-direction:column; }
        .post-author { font-size:0.8rem; font-weight:600; color:var(--text-primary); }
        .post-time { font-size:0.7rem; color:var(--text-muted); }
        .post-title { font-size:0.95rem; font-weight:600; color:var(--text-primary); margin-bottom:0.4rem; }
        .post-content { font-size:0.85rem; color:var(--text-secondary); line-height:1.6; white-space:pre-wrap; word-wrap:break-word; }
        .post-type-badge { font-size:0.6rem; text-transform:uppercase; letter-spacing:0.05em; padding:0.15rem 0.45rem; border-radius:4px; font-weight:600; margin-left:auto; }
        .post-type-message { background:rgba(59,130,246,0.15); color:#60a5fa; }
        .post-type-concern { background:rgba(239,68,68,0.15); color:#f87171; }
        .post-type-idea { background:rgba(34,197,94,0.15); color:#4ade80; }
        .post-type-reply { background:rgba(168,85,247,0.15); color:#c084fc; }
        .post-footer { display:flex; align-items:center; gap:0.75rem; margin-top:0.75rem; padding-top:0.6rem; border-top:1px solid var(--border); }
        .post-action { font-size:0.7rem; color:var(--text-muted); cursor:pointer; transition:color 0.15s; background:none; border:none; font-family:inherit; padding:0; }
        .post-action:hover { color:var(--accent-light); }
        .post-edited { font-size:0.65rem; color:var(--text-muted); font-style:italic; margin-left:auto; }

        /* Create group card */
        .create-group-card { background:var(--bg-section); border:1px dashed var(--border); border-radius:var(--radius-lg); padding:1rem; }
        .create-group-card h4 { font-size:0.8rem; font-weight:600; margin-bottom:0.5rem; color:var(--text-secondary); }

        /* Messages */
        .flash { padding:0.6rem 1rem; border-radius:var(--radius); font-size:0.8rem; margin-bottom:1rem; }
        .flash-error { background:rgba(239,68,68,0.1); border:1px solid rgba(239,68,68,0.3); color:#f87171; }
        .flash-success { background:rgba(34,197,94,0.1); border:1px solid rgba(34,197,94,0.3); color:#4ade80; }

        /* Empty state */
        .empty-state { text-align:center; padding:3rem 1rem; color:var(--text-muted); }
        .empty-state h3 { font-size:1rem; margin-bottom:0.5rem; color:var(--text-secondary); }
        .empty-state p { font-size:0.85rem; }

        /* Edit overlay */
        .edit-overlay { display:none; position:fixed; inset:0; z-index:400; background:rgba(0,0,0,0.7); align-items:center; justify-content:center; }
        .edit-overlay.active { display:flex; }
        .edit-dialog { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1.5rem; width:560px; max-width:90vw; }
        .edit-dialog h3 { font-size:0.9rem; font-weight:600; margin-bottom:1rem; }
    </style>
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
        <li><a href="messaging.jsp" class="active">Messages</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <% if (sessionUserId != null) { %>
            <span class="nav-session-label"><%= esc(sessionUsername) %><%= sessionAdmin ? " ★" : "" %></span>
            <a href="messaging.jsp?action=logout" class="nav-cta" style="background:transparent;border:1px solid var(--border);color:var(--text-secondary);">Logout</a>
        <% } else { %>
            <a href="guest.jsp" class="nav-cta" style="background:transparent;border:1px solid var(--border);color:var(--text-secondary);">Guest</a>
            <a href="register.jsp" class="nav-cta">Register</a>
        <% } %>
    </div>
</div></nav>

<section class="hero" style="padding:3rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Community</span>
        <h1>Messages</h1>
        <p>Post messages, concerns, or ideas. Anonymous or signed. Create subgroups to organize discussion.</p>
    </div>
</section>

<% if (!dbOk) { %>
<div style="max-width:var(--max-width);margin:2rem auto;padding:0 2rem;">
    <div class="flash flash-error">Messaging database offline. Run <code>bash modules/analytics/servlets/setup-messaging.sh</code></div>
</div>
<% } else { %>

<div class="msg-layout">
    <!-- SIDEBAR -->
    <aside class="msg-sidebar">
        <!-- Auth Card -->
        <% if (sessionUserId == null) { %>
        <div class="auth-card">
            <div class="auth-tabs">
                <button class="auth-tab active" onclick="showAuthTab('login')">Login</button>
                <button class="auth-tab" onclick="showAuthTab('register')">Register</button>
            </div>
            <div id="auth-login" class="auth-panel active">
                <form method="post" action="messaging.jsp">
                    <input type="hidden" name="action" value="login"/>
                    <input type="text" name="username" placeholder="Username" required autocomplete="username"/>
                    <input type="password" name="password" placeholder="Password" required autocomplete="current-password"/>
                    <button type="submit" class="btn btn-primary btn-sm" style="width:100%;margin-top:0.25rem;">Login</button>
                </form>
            </div>
            <div id="auth-register" class="auth-panel">
                <form method="post" action="messaging.jsp">
                    <input type="hidden" name="action" value="register"/>
                    <input type="text" name="reg_username" placeholder="Username" required autocomplete="username"/>
                    <input type="text" name="reg_displayname" placeholder="Display Name (optional)"/>
                    <input type="email" name="reg_email" placeholder="Email (optional)"/>
                    <input type="password" name="reg_password" placeholder="Password (4+ chars)" required minlength="4" autocomplete="new-password"/>
                    <button type="submit" class="btn btn-primary btn-sm" style="width:100%;margin-top:0.25rem;">Create Account</button>
                </form>
            </div>
        </div>
        <% } else { %>
        <div class="auth-card">
            <div style="display:flex;align-items:center;gap:0.5rem;">
                <div class="post-avatar" style="background:var(--accent);width:32px;height:32px;font-size:0.8rem;"><%= sessionUsername.substring(0,1).toUpperCase() %></div>
                <div>
                    <div style="font-size:0.85rem;font-weight:600;color:var(--text-primary);"><%= esc(sessionUsername) %></div>
                    <div style="font-size:0.7rem;color:var(--text-muted);"><%= sessionAdmin ? "Administrator" : "Member" %></div>
                </div>
            </div>
        </div>
        <% } %>

        <!-- Groups -->
        <h3>Channels</h3>
        <ul class="group-list">
            <li><a href="messaging.jsp" class="group-item <%= (viewGroup == null || viewGroup.isEmpty()) ? "active" : "" %>">
                <span class="group-dot" style="background:#6b7280;"></span>General
            </a></li>
            <% for (Map<String, Object> g : subgroups) { %>
            <li><a href="messaging.jsp?group=<%= g.get("id") %>" class="group-item <%= String.valueOf(g.get("id")).equals(viewGroup) ? "active" : "" %>">
                <span class="group-dot"></span><%= esc((String)g.get("group_name")) %>
                <span class="group-count"><%= g.get("post_count") %></span>
            </a></li>
            <% } %>
        </ul>

        <!-- Create Subgroup (profiled only) -->
        <% if (sessionUserId != null) { %>
        <div class="create-group-card">
            <h4>+ New Subgroup</h4>
            <form method="post" action="messaging.jsp">
                <input type="hidden" name="action" value="create_group"/>
                <input type="text" name="group_name" placeholder="Group name" required class="compose-input" style="width:100%;margin-bottom:0.4rem;"/>
                <input type="text" name="group_desc" placeholder="Description (optional)" class="compose-input" style="width:100%;margin-bottom:0.4rem;"/>
                <button type="submit" class="btn btn-primary btn-sm" style="width:100%;">Create</button>
            </form>
        </div>
        <% } %>

        <!-- Admin: delete group -->
        <% if ((sessionAdmin || sessionUserId != null) && viewGroup != null && !viewGroup.isEmpty()) {
            boolean canDelete = sessionAdmin;
            if (!canDelete && sessionUserId != null) {
                for (Map<String, Object> g : subgroups) {
                    if (String.valueOf(g.get("id")).equals(viewGroup) && sessionUserId.equals(g.get("owner_id"))) { canDelete = true; break; }
                }
            }
            if (canDelete) { %>
        <a href="messaging.jsp?action=delete_group&group_id=<%= viewGroup %>" class="btn btn-ghost btn-sm" style="color:#f87171;border-color:#f87171;text-align:center;" onclick="return confirm('Archive this subgroup?');">Archive Group</a>
        <%  } } %>
    </aside>

    <!-- MAIN CONTENT -->
    <main class="msg-main">
        <% if (errorMsg != null) { %><div class="flash flash-error"><%= esc(errorMsg) %></div><% } %>
        <% if (successMsg != null) { %><div class="flash flash-success"><%= esc(successMsg) %></div><% } %>

        <!-- Compose -->
        <div class="compose-card">
            <h3><%= sessionUserId != null ? "Post as " + esc(sessionUsername) : "Post Anonymously" %></h3>
            <form method="post" action="messaging.jsp<%= (viewGroup != null && !viewGroup.isEmpty()) ? "?group=" + viewGroup : "" %>">
                <input type="hidden" name="action" value="post"/>
                <% if (viewGroup != null && !viewGroup.isEmpty()) { %>
                <input type="hidden" name="subgroup_id" value="<%= viewGroup %>"/>
                <% } %>
                <div class="compose-row">
                    <input type="text" name="post_title" placeholder="Title (optional)" class="compose-input"/>
                    <% if (sessionUserId == null) { %>
                    <input type="text" name="anon_name" placeholder="Your name (optional)" class="compose-input" style="max-width:180px;"/>
                    <% } %>
                </div>
                <textarea name="content" class="compose-textarea" placeholder="Share a message, concern, or idea..." required></textarea>
                <div class="compose-actions">
                    <div class="type-pills">
                        <label class="type-pill active" onclick="selectType(this,'message')"><input type="radio" name="post_type" value="message" checked style="display:none;"/>Message</label>
                        <label class="type-pill" onclick="selectType(this,'concern')"><input type="radio" name="post_type" value="concern" style="display:none;"/>Concern</label>
                        <label class="type-pill" onclick="selectType(this,'idea')"><input type="radio" name="post_type" value="idea" style="display:none;"/>Idea</label>
                    </div>
                    <button type="submit" class="btn btn-primary btn-sm" style="margin-left:auto;">Post</button>
                </div>
            </form>
        </div>

        <!-- Posts -->
        <% if (posts.isEmpty()) { %>
        <div class="empty-state">
            <h3>No messages yet</h3>
            <p>Be the first to post in this channel. No account required.</p>
        </div>
        <% } else {
            for (Map<String, Object> post : posts) {
                String author = post.get("username") != null ? (String) post.get("display_name") : (String) post.get("anonymous_name");
                if (author == null || author.isEmpty()) author = "Anonymous";
                String avatarColor = post.get("avatar_color") != null ? (String) post.get("avatar_color") : "#6b7280";
                String pType = (String) post.get("post_type");
                boolean isPinned = (Boolean) post.get("is_pinned");
                boolean isOwner = (sessionUserId != null && sessionUserId.equals(post.get("user_id")));
                long postId = (Long) post.get("id");
        %>
        <div class="post-card<%= isPinned ? " pinned" : "" %>" id="post-<%= postId %>">
            <div class="post-header">
                <div class="post-avatar" style="background:<%= avatarColor %>;"><%= author.substring(0,1).toUpperCase() %></div>
                <div class="post-meta">
                    <span class="post-author"><%= esc(author) %><%= post.get("user_id") == null ? " <span style='font-size:0.6rem;color:var(--text-muted);'>(anon)</span>" : "" %></span>
                    <span class="post-time"><%= timeAgo((Timestamp) post.get("created_at")) %></span>
                </div>
                <span class="post-type-badge post-type-<%= pType %>"><%= pType %></span>
            </div>
            <% if (post.get("title") != null && !((String)post.get("title")).isEmpty()) { %>
            <div class="post-title"><%= esc((String) post.get("title")) %></div>
            <% } %>
            <div class="post-content"><%= esc((String) post.get("content")) %></div>
            <div class="post-footer">
                <button class="post-action" onclick="replyTo(<%= postId %>)">↩ Reply</button>
                <% if (isOwner || sessionAdmin) { %>
                <button class="post-action" onclick="editPost(<%= postId %>, '<%= esc((String) post.get("title")).replace("'","\\'") %>', this)">✎ Edit</button>
                <a href="messaging.jsp?action=delete&post_id=<%= postId %><%= (viewGroup != null ? "&group=" + viewGroup : "") %>" class="post-action" onclick="return confirm('Delete this post?');" style="color:#f87171;">✕ Delete</a>
                <% } %>
                <% if ((Integer) post.get("edit_count") > 0) { %>
                <span class="post-edited">(edited <%= post.get("edit_count") %>×)</span>
                <% } %>
            </div>
        </div>
        <% } } %>
    </main>
</div>

<% } %>

<!-- Edit Dialog -->
<div id="edit-overlay" class="edit-overlay">
    <div class="edit-dialog">
        <h3>Edit Post</h3>
        <form method="post" action="messaging.jsp<%= (viewGroup != null && !viewGroup.isEmpty()) ? "?group=" + viewGroup : "" %>">
            <input type="hidden" name="action" value="edit"/>
            <input type="hidden" name="post_id" id="edit-post-id" value=""/>
            <input type="text" name="edit_title" id="edit-title" placeholder="Title (optional)" class="compose-input" style="width:100%;margin-bottom:0.5rem;"/>
            <textarea name="edit_content" id="edit-content" class="compose-textarea" required></textarea>
            <div style="display:flex;gap:0.5rem;margin-top:0.75rem;justify-content:flex-end;">
                <button type="button" class="btn btn-ghost btn-sm" onclick="closeEdit()">Cancel</button>
                <button type="submit" class="btn btn-primary btn-sm">Save</button>
            </div>
        </form>
    </div>
</div>

<footer class="footer" style="padding:2rem;text-align:center;border-top:1px solid var(--border);color:var(--text-muted);font-size:0.75rem;">
    <span>&#169; 2026 MEARVK LLC — NitroWebExpress™ — Messaging</span>
</footer>

<script>
// Auth tabs
function showAuthTab(tab) {
    document.querySelectorAll('.auth-tab').forEach(function(t) { t.classList.remove('active'); });
    document.querySelectorAll('.auth-panel').forEach(function(p) { p.classList.remove('active'); });
    event.target.classList.add('active');
    document.getElementById('auth-' + tab).classList.add('active');
}

// Post type pills
function selectType(el, type) {
    el.closest('.type-pills').querySelectorAll('.type-pill').forEach(function(p) { p.classList.remove('active'); });
    el.classList.add('active');
}

// Reply (sets parent_id, focuses compose)
function replyTo(postId) {
    var form = document.querySelector('.compose-card form');
    var existing = form.querySelector('input[name="parent_id"]');
    if (existing) existing.remove();
    var input = document.createElement('input');
    input.type = 'hidden'; input.name = 'parent_id'; input.value = postId;
    form.appendChild(input);
    // Select reply type
    var replyPill = document.createElement('label');
    // Just focus the textarea
    form.querySelector('textarea').focus();
    form.querySelector('textarea').placeholder = 'Replying to post #' + postId + '...';
}

// Edit post
function editPost(postId, title, btn) {
    document.getElementById('edit-post-id').value = postId;
    document.getElementById('edit-title').value = title || '';
    // Get content from the post card
    var card = document.getElementById('post-' + postId);
    var content = card ? card.querySelector('.post-content').textContent : '';
    document.getElementById('edit-content').value = content.trim();
    document.getElementById('edit-overlay').classList.add('active');
}
function closeEdit() {
    document.getElementById('edit-overlay').classList.remove('active');
}
// Close on overlay click
document.getElementById('edit-overlay').addEventListener('click', function(e) {
    if (e.target === this) closeEdit();
});
</script>
</body>
</html>
