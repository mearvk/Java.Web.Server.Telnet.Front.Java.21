<%@ page import="java.sql.*" %>
<%--
    NitroWebExpress™ — Auth Buttons Include (auth-buttons.jsp)
    ════════════════════════════════════════════════════════════════════
    Include in any JSP page AFTER the </nav> tag to add login/register
    buttons and login popup. Uses host module's CSS --accent variable.

    Usage:
        <%@ include file="auth-buttons.jsp" %>

    Place AFTER your </nav> closing tag or at end of nav-actions div.
    Reads session: msg_user_id, msg_username, msg_admin
    Links to: profile_creation.jsp (register), profile.jsp (view)
    ════════════════════════════════════════════════════════════════════
--%>
<%
    Integer __abUserId = (Integer) session.getAttribute("msg_user_id");
    String __abUsername = (String) session.getAttribute("msg_username");
    Boolean __abAdmin = (Boolean) session.getAttribute("msg_admin");
    if (__abAdmin == null) __abAdmin = false;

    // Handle login POST from popup
    String __abAction = request.getParameter("auth_action");
    String __abError = null;
    if ("login".equals(__abAction) && "POST".equals(request.getMethod())) {
        String __u = request.getParameter("auth_username");
        String __p = request.getParameter("auth_password");
        if (__u != null && __p != null && !__u.isEmpty() && !__p.isEmpty()) {
            Connection __c = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                __c = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_messaging", "root", "$$Ironman1");
                PreparedStatement __ps = __c.prepareStatement("SELECT id, username, display_name, password_hash, salt, is_admin, is_banned FROM msg_users WHERE username = ?");
                __ps.setString(1, __u.trim());
                ResultSet __rs = __ps.executeQuery();
                if (__rs.next()) {
                    if (__rs.getBoolean("is_banned")) { __abError = "Account suspended."; }
                    else {
                        String __salt = __rs.getString("salt");
                        String __hash = __rs.getString("password_hash");
                        java.security.MessageDigest __md = java.security.MessageDigest.getInstance("SHA-256");
                        byte[] __hb = __md.digest((__salt + __p).getBytes(java.nio.charset.StandardCharsets.UTF_8));
                        StringBuilder __sb = new StringBuilder();
                        for (byte b : __hb) __sb.append(String.format("%02x", b));
                        if (__sb.toString().equals(__hash)) {
                            session.setAttribute("msg_user_id", __rs.getInt("id"));
                            session.setAttribute("msg_username", __rs.getString("username"));
                            session.setAttribute("msg_display_name", __rs.getString("display_name"));
                            session.setAttribute("msg_admin", __rs.getBoolean("is_admin"));
                            __abUserId = __rs.getInt("id");
                            __abUsername = __rs.getString("username");
                            __abAdmin = __rs.getBoolean("is_admin");
                            PreparedStatement __up = __c.prepareStatement("UPDATE msg_users SET last_active = NOW() WHERE id = ?");
                            __up.setInt(1, __abUserId); __up.executeUpdate(); __up.close();
                        } else { __abError = "Invalid password."; }
                    }
                } else { __abError = "User not found."; }
                __rs.close(); __ps.close();
            } catch (Exception __e) { __abError = "Login unavailable."; }
            finally { if (__c != null) try { __c.close(); } catch (Exception __e2) {} }
        }
    }
    if ("logout".equals(__abAction)) {
        session.removeAttribute("msg_user_id"); session.removeAttribute("msg_username");
        session.removeAttribute("msg_display_name"); session.removeAttribute("msg_admin");
        __abUserId = null; __abUsername = null; __abAdmin = false;
    }
%>
<style>
.nwe-auth-bar{display:flex;align-items:center;gap:0.5rem;}
.nwe-auth-btn{font-size:0.75rem;padding:0.35rem 0.8rem;border-radius:6px;cursor:pointer;font-weight:600;text-decoration:none;transition:all 0.2s;border:1px solid var(--border,#27272a);display:inline-flex;align-items:center;gap:0.3rem;}
.nwe-auth-btn-login{background:transparent;color:var(--accent,#3b82f6);border-color:var(--accent,#3b82f6);}
.nwe-auth-btn-login:hover{background:var(--accent,#3b82f6);color:#fff;}
.nwe-auth-btn-register{background:var(--accent,#3b82f6);color:#fff;border-color:var(--accent,#3b82f6);}
.nwe-auth-btn-register:hover{opacity:0.85;}
.nwe-auth-btn-user{background:transparent;color:var(--accent,#3b82f6);border-color:transparent;font-weight:500;}
.nwe-auth-btn-logout{background:transparent;color:#71717a;border-color:#3a3a4a;font-weight:400;}
.nwe-auth-btn-logout:hover{border-color:#f87171;color:#f87171;}
.nwe-login-overlay{display:none;position:fixed;inset:0;z-index:9000;background:rgba(0,0,0,0.6);align-items:center;justify-content:center;}
.nwe-login-overlay.active{display:flex;}
.nwe-login-box{background:var(--bg-section,#12121a);border:1px solid var(--border,#27272a);border-radius:12px;padding:1.5rem;width:340px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.5);}
.nwe-login-box h3{font-size:0.9rem;font-weight:700;margin-bottom:1rem;color:var(--accent,#3b82f6);}
.nwe-login-box input{width:100%;background:var(--bg-card,#1a1a24);border:1px solid var(--border,#27272a);border-radius:6px;padding:0.5rem 0.75rem;color:var(--text,#e8e8f0);font-size:0.8rem;margin-bottom:0.6rem;}
.nwe-login-box input:focus{outline:none;border-color:var(--accent,#3b82f6);}
.nwe-login-box button[type=submit]{width:100%;background:var(--accent,#3b82f6);color:#fff;border:none;border-radius:6px;padding:0.55rem;font-size:0.8rem;font-weight:600;cursor:pointer;margin-top:0.3rem;}
.nwe-login-box button[type=submit]:hover{opacity:0.9;}
.nwe-login-box .nwe-login-cancel{display:block;text-align:center;margin-top:0.75rem;font-size:0.7rem;color:#71717a;cursor:pointer;}
.nwe-login-box .nwe-login-cancel:hover{color:var(--accent,#3b82f6);}
.nwe-login-box .nwe-login-error{font-size:0.7rem;color:#f87171;margin-bottom:0.5rem;}
.nwe-login-box .nwe-login-register{display:block;text-align:center;margin-top:0.5rem;font-size:0.7rem;color:#71717a;}
.nwe-login-box .nwe-login-register a{color:var(--accent,#3b82f6);}
</style>

<% if (__abUserId != null) { %>
<%-- Logged in: show username + logout --%>
<span class="nwe-auth-btn nwe-auth-btn-user"><%= __abUsername %><%= __abAdmin ? " ★" : "" %></span>
<a href="profile.jsp" class="nwe-auth-btn nwe-auth-btn-login" style="border-color:transparent;">Profile</a>
<a href="?auth_action=logout" class="nwe-auth-btn nwe-auth-btn-logout">Logout</a>
<% } else { %>
<%-- Not logged in: Login + Register buttons --%>
<button type="button" class="nwe-auth-btn nwe-auth-btn-login" onclick="document.getElementById('nwe-login-overlay').classList.add('active');">Login</button>
<a href="profile_creation.jsp" class="nwe-auth-btn nwe-auth-btn-register">Register</a>
<% } %>

<%-- Login Popup Overlay --%>
<div id="nwe-login-overlay" class="nwe-login-overlay<%= __abError != null ? " active" : "" %>">
    <div class="nwe-login-box">
        <h3>Login</h3>
        <% if (__abError != null) { %><div class="nwe-login-error"><%= __abError %></div><% } %>
        <form method="post" action="">
            <input type="hidden" name="auth_action" value="login"/>
            <input type="text" name="auth_username" placeholder="Username" required autocomplete="username"/>
            <input type="password" name="auth_password" placeholder="Password" required autocomplete="current-password"/>
            <button type="submit">Login</button>
        </form>
        <span class="nwe-login-cancel" onclick="document.getElementById('nwe-login-overlay').classList.remove('active');">Cancel</span>
        <span class="nwe-login-register">No account? <a href="profile_creation.jsp">Register here</a></span>
    </div>
</div>
<script>
document.getElementById('nwe-login-overlay').addEventListener('click',function(e){if(e.target===this)this.classList.remove('active');});
</script>
