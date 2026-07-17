<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String sessionUser = (String) session.getAttribute("btc_username");
    String profileData = "";
    String walletsData = "";

    if (sessionUser != null) {
        // Fetch profile from backend
        try (Socket s = new Socket()) {
            s.connect(new InetSocketAddress("127.0.0.1", 6682), 5000);
            s.setSoTimeout(5000);
            BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
            PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
            br.readLine(); // banner
            pw.println("LOGIN|" + sessionUser + "|session_token");
            br.readLine();
            pw.println("PROFILE");
            profileData = br.readLine();
            pw.println("MY_WALLETS");
            walletsData = br.readLine();
            pw.println("QUIT");
        } catch (Exception e) { profileData = "Backend offline: " + e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Profile — Bitcoin™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">₿ Bitcoin™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="wallets.jsp">Wallets</a></li>
        <li><a href="transactions.jsp">Transactions</a></li>
        <li><a href="account.jsp">Account</a></li>
        <li><a href="profile.jsp" class="active">Profile</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <% if (__admin) { %>
            <span style="font-size:0.75rem;color:#f59e0b;margin-right:4px;">&#9733; Admin</span>
            <a href="admin.jsp?action=logout" class="nav-cta" style="border-color:#dc2626;color:#dc2626;">Logout</a>
        <% } else if (__user != null) { %>
            <span style="font-size:0.8rem;color:var(--accent);margin-right:6px;"><%= __user %></span>
            <a href="account.jsp?action=logout" class="nav-cta" style="border-color:#dc2626;color:#dc2626;">Logout</a>
        <% } else { %>
            <a href="account.jsp" class="nav-cta">Login</a>
            <a href="admin.jsp" class="nav-cta" style="border-color:#f59e0b;color:#f59e0b;">Admin</a>
        <% } %>
    </div>
</div></nav>

<section class="hero"><div class="hero-inner">
    <span class="hero-tag">Your Profile</span>
    <h1>Profile</h1>
    <p><% if (sessionUser != null) { %>Managing profile for <strong style="color:var(--accent);"><%= sessionUser %></strong><% } else { %>Login to view and manage your profile.<% } %></p>
</div></section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 6682</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#222;color:#e8e0d6;border:1px solid #444;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="status">Status</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#999;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#888;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#222;color:#aaa;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #333;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "6682";</script>
<script src="js/cd1-connector.js"></script>


<% if (sessionUser == null) { %>
<section class="section"><div class="section-inner">
    <h2>Login Required</h2>
    <p style="color:var(--text-muted);margin-bottom:1rem;">You must be logged in to view your profile. Your profile is populated after your first login.</p>
    <a href="account.jsp" class="btn btn-primary">Login / Create Account →</a>
</div></section>
<% } else { %>

<section class="section"><div class="section-inner">
    <h2>Profile Picture</h2>
    <div style="display:flex;align-items:center;gap:1.5rem;background:var(--bg-card);border:1px solid var(--border);border-radius:12px;padding:1.5rem;">
        <div id="avatar-preview" style="width:96px;height:96px;border-radius:50%;background:var(--bg-section);border:2px solid var(--accent);display:flex;align-items:center;justify-content:center;overflow:hidden;">
            <span style="font-size:2rem;color:var(--text-muted);">₿</span>
        </div>
        <div>
            <p style="color:var(--text-muted);font-size:0.85rem;margin-bottom:0.75rem;">Upload a profile picture (jpg, png, gif, webp).</p>
            <input type="file" id="profile-pic-input" accept="image/jpeg,image/png,image/gif,image/webp" onchange="previewPic(this)" style="font-size:0.8rem;color:var(--text-muted);"/>
            <br/><button class="btn btn-primary" style="margin-top:0.75rem;" onclick="uploadPic()">Upload</button>
        </div>
    </div>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Account Info</h2>
    <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:12px;padding:1.5rem;">
        <div style="display:grid;grid-template-columns:1fr 2fr;gap:0.4rem;font-size:0.85rem;">
            <span style="color:var(--text-muted);">Username</span><span style="color:var(--accent);"><%= sessionUser %></span>
            <span style="color:var(--text-muted);">Profile Data</span><span><code style="font-size:0.75rem;"><%= profileData != null ? profileData : "Not loaded" %></code></span>
        </div>
    </div>
</div></section>

<section class="section"><div class="section-inner">
    <h2>My Private Wallets</h2>
    <p style="color:var(--text-muted);margin-bottom:1rem;">Create and manage private wallets. Control whether each wallet is publicly visible.</p>

    <h3 style="color:var(--accent);margin-bottom:0.75rem;">Create New Wallet</h3>
    <form method="POST" action="profile.jsp" style="display:flex;gap:0.75rem;align-items:flex-end;flex-wrap:wrap;margin-bottom:1.5rem;">
        <input type="hidden" name="action" value="create_wallet"/>
        <div class="form-group" style="margin:0;flex:1;min-width:180px;"><label>Wallet Name</label><input type="text" name="wallet_name" required placeholder="e.g. Savings, Trading, Cold Store"/></div>
        <div class="form-group" style="margin:0;width:140px;">
            <label>Visibility</label>
            <select name="visibility">
                <option value="private">Private</option>
                <option value="public">Public</option>
            </select>
        </div>
        <button type="submit" class="btn btn-primary">Create Wallet</button>
    </form>

    <h3 style="color:var(--accent);margin-bottom:0.75rem;">Your Wallets</h3>
    <div class="table-wrap"><table>
        <thead><tr><th>Name</th><th>Visibility</th><th>Created</th><th>Actions</th></tr></thead>
        <tbody>
            <% if (walletsData != null && !walletsData.isEmpty() && !walletsData.contains("offline")) { %>
            <tr><td colspan="4"><code style="font-size:0.75rem;"><%= walletsData %></code></td></tr>
            <% } else { %>
            <tr><td colspan="4" style="color:var(--text-muted);text-align:center;">No wallets yet. Create one above.</td></tr>
            <% } %>
        </tbody>
    </table></div>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Wallet Visibility</h2>
    <p style="color:var(--text-muted);margin-bottom:1rem;">Control which wallets appear on the public <a href="wallets.jsp">Wallets</a> page.</p>
    <form method="POST" action="profile.jsp" style="max-width:500px;">
        <input type="hidden" name="action" value="set_visibility"/>
        <div class="form-group"><label>Wallet Name</label><input type="text" name="wallet_name" required placeholder="Wallet name"/></div>
        <div class="form-group"><label>Visibility</label>
            <select name="visibility">
                <option value="private">Private — only you can see</option>
                <option value="public">Public — listed on wallets.jsp</option>
            </select>
        </div>
        <button type="submit" class="btn btn-ghost">Update Visibility</button>
    </form>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Rename Wallet</h2>
    <form method="POST" action="profile.jsp" style="display:flex;gap:0.75rem;align-items:flex-end;flex-wrap:wrap;max-width:500px;">
        <input type="hidden" name="action" value="rename_wallet"/>
        <div class="form-group" style="margin:0;flex:1;"><label>Current Name</label><input type="text" name="old_name" required/></div>
        <div class="form-group" style="margin:0;flex:1;"><label>New Name</label><input type="text" name="new_name" required/></div>
        <button type="submit" class="btn btn-ghost">Rename</button>
    </form>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Delete Wallet</h2>
    <p style="color:var(--text-muted);margin-bottom:1rem;">Permanently delete a private wallet. Blockchain transactions remain immutable.</p>
    <form method="POST" action="profile.jsp" style="display:flex;gap:0.75rem;align-items:flex-end;max-width:400px;" onsubmit="return confirm('Delete this wallet permanently?');">
        <input type="hidden" name="action" value="delete_wallet"/>
        <div class="form-group" style="margin:0;flex:1;"><label>Wallet Name</label><input type="text" name="wallet_name" required/></div>
        <button type="submit" class="btn btn-ghost" style="border-color:#dc2626;color:#dc2626;">Delete</button>
    </form>
</div></section>

<% } %>

<footer class="footer"><span>Bitcoin™ — Profile — MEARVK LLC — NitroWebExpress™ 2026</span></footer>
<script>
function previewPic(input) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();
        reader.onload = function(e) { document.getElementById('avatar-preview').innerHTML = '<img src="' + e.target.result + '" style="width:100%;height:100%;object-fit:cover;"/>'; };
        reader.readAsDataURL(input.files[0]);
    }
}
function uploadPic() { var f = document.getElementById('profile-pic-input'); if (!f.files || !f.files[0]) { alert('Select an image.'); return; } alert('Upload via SET_PROFILE_PIC on port 6682.'); }
</script>
</body></html>
