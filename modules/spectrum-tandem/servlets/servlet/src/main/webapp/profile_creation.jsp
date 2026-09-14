<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.security.MessageDigest, java.nio.charset.StandardCharsets" %>
<%!
    static String hashPw(String password, String salt) {
        try { MessageDigest md = MessageDigest.getInstance("SHA-256"); byte[] h = md.digest((salt + password).getBytes(StandardCharsets.UTF_8)); StringBuilder sb = new StringBuilder(); for (byte b : h) sb.append(String.format("%02x", b)); return sb.toString(); } catch (Exception e) { return ""; }
    }
    static String genSalt() { String c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; StringBuilder s = new StringBuilder(); java.util.Random r = new java.util.Random(); for (int i = 0; i < 16; i++) s.append(c.charAt(r.nextInt(c.length()))); return s.toString(); }
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    String MODULE_NAME = request.getContextPath().replaceAll("^/", "");
    if (MODULE_NAME.isEmpty()) MODULE_NAME = "NWE";

    String action = request.getParameter("action");
    String successMsg = null;
    String errorMsg = null;
    boolean registered = false;

    if ("register".equals(action) && "POST".equals(request.getMethod())) {
        String u = request.getParameter("username");
        String p = request.getParameter("password");
        String p2 = request.getParameter("password_confirm");
        String dn = request.getParameter("display_name");
        String em = request.getParameter("email");

        if (u == null || u.trim().isEmpty()) { errorMsg = "Username is required."; }
        else if (p == null || p.length() < 4) { errorMsg = "Password must be at least 4 characters."; }
        else if (!p.equals(p2)) { errorMsg = "Passwords do not match."; }
        else {
            Connection conn = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_messaging", "root", "$$Ironman1");
                String salt = genSalt();
                String hash = hashPw(p, salt);
                PreparedStatement ps = conn.prepareStatement("INSERT INTO msg_users (username, display_name, password_hash, salt, email) VALUES (?, ?, ?, ?, ?)", Statement.RETURN_GENERATED_KEYS);
                ps.setString(1, u.trim());
                ps.setString(2, (dn != null && !dn.trim().isEmpty()) ? dn.trim() : u.trim());
                ps.setString(3, hash);
                ps.setString(4, salt);
                ps.setString(5, em);
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) {
                    session.setAttribute("msg_user_id", keys.getInt(1));
                    session.setAttribute("msg_username", u.trim());
                    session.setAttribute("msg_display_name", (dn != null && !dn.trim().isEmpty()) ? dn.trim() : u.trim());
                    session.setAttribute("msg_admin", false);
                    registered = true;
                    successMsg = "Account created! Welcome, " + esc(u.trim()) + ".";
                }
                keys.close(); ps.close();
            } catch (SQLIntegrityConstraintViolationException ex) { errorMsg = "Username \"" + esc(u) + "\" is already taken."; }
            catch (Exception e) { errorMsg = "Registration unavailable. Database offline."; }
            finally { if (conn != null) try { conn.close(); } catch (Exception e) {} }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <title>Create Account — <%= esc(MODULE_NAME) %>™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <style>
        .reg-page{max-width:420px;margin:0 auto;padding:3rem 2rem;}
        .reg-card{background:var(--bg-section,#12121a);border:1px solid var(--border,#27272a);border-radius:12px;padding:2rem;}
        .reg-card h1{font-size:1.25rem;font-weight:700;margin-bottom:0.25rem;color:var(--accent,#3b82f6);}
        .reg-card p{font-size:0.8rem;color:var(--text-muted,#71717a);margin-bottom:1.5rem;}
        .reg-card label{display:block;font-size:0.7rem;color:var(--text-muted,#71717a);margin-bottom:0.2rem;font-weight:500;text-transform:uppercase;letter-spacing:0.03em;}
        .reg-card input{width:100%;background:var(--bg-card,#1a1a24);border:1px solid var(--border,#27272a);border-radius:8px;padding:0.55rem 0.75rem;color:var(--text,#e8e8f0);font-size:0.85rem;margin-bottom:0.75rem;}
        .reg-card input:focus{outline:none;border-color:var(--accent,#3b82f6);}
        .reg-card button{width:100%;background:var(--accent,#3b82f6);color:#fff;border:none;border-radius:8px;padding:0.65rem;font-size:0.85rem;font-weight:600;cursor:pointer;margin-top:0.5rem;}
        .reg-card button:hover{opacity:0.9;}
        .reg-card .reg-footer{text-align:center;margin-top:1rem;font-size:0.7rem;color:var(--text-muted,#71717a);}
        .reg-card .reg-footer a{color:var(--accent,#3b82f6);}
        .flash-s{padding:0.6rem 1rem;border-radius:8px;font-size:0.8rem;margin-bottom:1rem;background:rgba(34,197,94,0.1);border:1px solid rgba(34,197,94,0.3);color:#4ade80;}
        .flash-e{padding:0.6rem 1rem;border-radius:8px;font-size:0.8rem;margin-bottom:1rem;background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#f87171;}
    </style>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand"><%= esc(MODULE_NAME) %>™</span>
    <ul class="nav-links" style="list-style:none;display:flex;gap:1.25rem;margin-left:auto;">
        <li><a href="index.jsp">Home</a></li>
        <li><a href="profile.jsp">Profile</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
    </ul>
</div></nav>

<div class="reg-page">
    <div class="reg-card">
        <h1>Create Account</h1>
        <p>Register for <%= esc(MODULE_NAME) %>™. One account works across all NitroWebExpress™ modules.</p>

        <% if (successMsg != null) { %><div class="flash-s"><%= successMsg %> <a href="index.jsp" style="color:#4ade80;">Continue →</a></div><% } %>
        <% if (errorMsg != null) { %><div class="flash-e"><%= errorMsg %></div><% } %>

        <% if (!registered) { %>
        <form method="post" action="profile_creation.jsp">
            <input type="hidden" name="action" value="register"/>
            <label>Username *</label>
            <input type="text" name="username" placeholder="Choose a username" required autocomplete="username"/>
            <label>Display Name</label>
            <input type="text" name="display_name" placeholder="Your display name (optional)"/>
            <label>Email</label>
            <input type="email" name="email" placeholder="Email address (optional)"/>
            <label>Password *</label>
            <input type="password" name="password" placeholder="At least 4 characters" required minlength="4" autocomplete="new-password"/>
            <label>Confirm Password *</label>
            <input type="password" name="password_confirm" placeholder="Re-enter password" required minlength="4" autocomplete="new-password"/>
            <button type="submit">Create Account</button>
        </form>
        <div class="reg-footer">Already have an account? <a href="index.jsp">Login</a></div>
        <% } %>
    </div>
</div>

<footer style="padding:2rem;text-align:center;color:var(--text-muted,#71717a);font-size:0.7rem;">NitroWebExpress™ — Account Creation — MEARVK LLC 2026</footer>
</body>
</html>
