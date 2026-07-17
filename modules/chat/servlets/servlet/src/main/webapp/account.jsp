<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Account — NWE Chat™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">NWE Chat™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Chat</a></li>
        <li><a href="account.jsp" class="active">Account</a></li>
        <li><a href="federation.jsp">Federation</a></li>
        <li><a href="settings.jsp">Settings</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Account Management</span>
        <h1>Your Account</h1>
        <p>Register, login, change username, or delete your account. All actions encrypted.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Register</h2>
        <form method="POST" action="account.jsp" style="max-width:500px;">
            <input type="hidden" name="action" value="register"/>
            <div class="form-group"><label>Username (3-32 chars)</label><input type="text" name="username" required minlength="3" maxlength="32"/></div>
            <div class="form-group"><label>Password (6+ chars)</label><input type="password" name="password" required minlength="6"/></div>
            <div class="form-group"><label>Email</label><input type="email" name="email" required/></div>
            <button type="submit" class="btn btn-primary">Create Account</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Login</h2>
        <form method="POST" action="account.jsp" style="max-width:500px;">
            <input type="hidden" name="action" value="login"/>
            <div class="form-group"><label>Username</label><input type="text" name="username" required/></div>
            <div class="form-group"><label>Password</label><input type="password" name="password" required/></div>
            <button type="submit" class="btn btn-primary">Login</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Change Username</h2>
        <form method="POST" action="account.jsp" style="max-width:500px;">
            <input type="hidden" name="action" value="change_username"/>
            <div class="form-group"><label>New Username</label><input type="text" name="new_username" required minlength="3" maxlength="32"/></div>
            <button type="submit" class="btn btn-ghost">Change Username</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Delete Account</h2>
        <p style="color:var(--text-muted);margin-bottom:1rem;">This marks your account for deletion. Existing chat logs remain for audit purposes.</p>
        <form method="POST" action="account.jsp" onsubmit="return confirm('Are you sure? This cannot be undone.');">
            <input type="hidden" name="action" value="delete"/>
            <button type="submit" class="btn btn-danger">Delete My Account</button>
        </form>
    </div>
</section>

<footer class="footer">
    <span>NWE Chat™ — Account — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
