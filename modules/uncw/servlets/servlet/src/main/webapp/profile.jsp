<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String __user = (String) session.getAttribute("uncw_username");
    Boolean __admin = (Boolean) session.getAttribute("uncw_admin");
    if (__admin == null) __admin = false;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Profile — UNCW™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">UNCW™ 🌊</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Home</a></li>
        <li><a href="profile.jsp" class="active">Profile</a></li>
        <li><a href="messages.jsp">Messages</a></li>
        <li><a href="files.jsp">Files</a></li>
        <li><a href="community.jsp">Community</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions">
        <% if (__admin) { %>
            <span style="font-size:0.75rem;color:#f59e0b;margin-right:4px;">&#9733; Admin</span>
            <a href="profile.jsp?action=logout" class="nav-cta" style="border-color:#dc2626;color:#dc2626;">Logout</a>
        <% } else if (__user != null) { %>
            <span style="font-size:0.8rem;color:var(--accent);margin-right:6px;"><%= __user %></span>
            <a href="profile.jsp?action=logout" class="nav-cta" style="border-color:#dc2626;color:#dc2626;">Logout</a>
        <% } else { %>
            <a href="profile.jsp" class="nav-cta">Login</a>
            <a href="profile.jsp" class="nav-cta" style="border-color:#f59e0b;color:#f59e0b;">Admin</a>
        <% } %>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Your Profile — UNCW Seahawks</span>
        <h1>Profile</h1>
        <p>Manage your profile picture, resume, National ID, and account settings. Other users can view your public profile.</p>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 49231</div>
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
<script>window.CD1_MODULE_PORT = "49231";</script>
<script src="js/cd1-connector.js"></script>


<section class="section">
    <div class="section-inner">
        <h2>Profile Picture</h2>
        <div class="profile-card">
            <div style="display:flex;align-items:center;gap:1.5rem;">
                <div id="avatar-preview" style="width:96px;height:96px;border-radius:50%;background:var(--bg-card);border:2px solid var(--accent);display:flex;align-items:center;justify-content:center;overflow:hidden;">
                    <span style="font-size:2rem;color:var(--text-muted);">👤</span>
                </div>
                <div>
                    <p style="color:var(--text-muted);font-size:0.85rem;margin-bottom:0.75rem;">Upload a profile picture (jpg, png, gif, webp). Max 5MB recommended.</p>
                    <input type="file" id="profile-pic-input" accept="image/jpeg,image/png,image/gif,image/webp" onchange="previewProfilePic(this)" style="font-size:0.8rem;color:var(--text-muted);"/>
                    <br/><button class="btn btn-primary" style="margin-top:0.75rem;" onclick="uploadProfilePic()">Upload Profile Picture</button>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Resume</h2>
        <div class="profile-card">
            <p style="color:var(--text-muted);font-size:0.85rem;margin-bottom:0.75rem;">Upload your resume (pdf, doc, docx, txt, rtf, odt). Visible on your profile for others to see if you choose.</p>
            <input type="file" id="resume-input" accept=".pdf,.doc,.docx,.txt,.rtf,.odt" style="font-size:0.8rem;color:var(--text-muted);"/>
            <br/><button class="btn btn-primary" style="margin-top:0.75rem;" onclick="uploadResume()">Upload Resume</button>
            <p id="resume-status" style="margin-top:0.5rem;font-size:0.8rem;color:var(--gold);"></p>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>National ID</h2>
        <div class="profile-card">
            <p style="color:var(--text-muted);font-size:0.85rem;margin-bottom:0.75rem;">⚠ Reminder: Please check for National IDs. Set yours below and it will be confirmed by one of our Servers.</p>
            <form style="display:flex;gap:0.75rem;align-items:flex-end;flex-wrap:wrap;">
                <div class="form-group" style="margin:0;flex:1;min-width:200px;">
                    <label>National ID</label>
                    <input type="text" id="national-id-input" placeholder="Enter your National ID"/>
                </div>
                <button type="button" class="btn btn-primary" onclick="setNationalId()">Set & Verify</button>
            </form>
            <p id="nid-status" style="margin-top:0.5rem;font-size:0.8rem;color:var(--accent-hover);"></p>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Account Details</h2>
        <div class="profile-card">
            <div class="field"><span style="color:var(--text-muted);">Username</span><span style="color:var(--text);">(login to see)</span></div>
            <div class="field"><span style="color:var(--text-muted);">Student ID</span><span style="color:var(--text);">(login to see)</span></div>
            <div class="field"><span style="color:var(--text-muted);">College</span><span style="color:var(--text);">(login to see)</span></div>
            <div class="field"><span style="color:var(--text-muted);">Email</span><span style="color:var(--text);">(login to see)</span></div>
            <div class="field"><span style="color:var(--text-muted);">National ID Confirmed</span><span style="color:var(--text);">(login to see)</span></div>
            <div class="field"><span style="color:var(--text-muted);">Profile Picture</span><span style="color:var(--text);">(login to see)</span></div>
            <div class="field"><span style="color:var(--text-muted);">Resume</span><span style="color:var(--text);">(login to see)</span></div>
            <div class="field"><span style="color:var(--text-muted);">File Storage Preference</span><span style="color:var(--text);">(login to see)</span></div>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>View Another User's Profile</h2>
        <form style="display:flex;gap:0.75rem;align-items:flex-end;flex-wrap:wrap;">
            <div class="form-group" style="margin:0;flex:1;min-width:200px;">
                <label>Username</label>
                <input type="text" id="view-user-input" placeholder="Enter username to view"/>
            </div>
            <button type="button" class="btn btn-ghost" onclick="viewProfile()">View Profile</button>
        </form>
        <div id="view-profile-result" style="margin-top:1rem;"></div>
    </div>
</section>

<footer class="footer">
    <span>UNCW™ — Profile — Go Seahawks! 🌊 — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>

<script>
function previewProfilePic(input) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();
        reader.onload = function(e) {
            var preview = document.getElementById('avatar-preview');
            preview.innerHTML = '<img src="' + e.target.result + '" style="width:100%;height:100%;object-fit:cover;"/>';
        };
        reader.readAsDataURL(input.files[0]);
    }
}
function uploadProfilePic() {
    var input = document.getElementById('profile-pic-input');
    if (!input.files || !input.files[0]) { alert('Select an image first.'); return; }
    alert('Profile picture ready to upload via backend (SET_PROFILE_PIC command on port 49231).');
}
function uploadResume() {
    var input = document.getElementById('resume-input');
    if (!input.files || !input.files[0]) { alert('Select a resume file first.'); return; }
    document.getElementById('resume-status').textContent = '✓ Resume "' + input.files[0].name + '" ready for upload via backend (UPLOAD_RESUME command).';
}
function setNationalId() {
    var nid = document.getElementById('national-id-input').value.trim();
    if (!nid) { alert('Enter your National ID.'); return; }
    document.getElementById('nid-status').textContent = 'National ID "' + nid + '" submitted. Awaiting server confirmation...';
}
function viewProfile() {
    var user = document.getElementById('view-user-input').value.trim();
    if (!user) { alert('Enter a username.'); return; }
    document.getElementById('view-profile-result').innerHTML = '<div class="profile-card"><h3>' + user + '</h3><p style="color:var(--text-muted);">Connect to backend (VIEW_PROFILE|' + user + ') to load profile data.</p></div>';
}
</script>
</body>
</html>
