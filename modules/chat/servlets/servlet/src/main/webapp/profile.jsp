<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Profile — NWE Chat™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">NWE Chat™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Chat</a></li>
        <li><a href="account.jsp">Account</a></li>
        <li><a href="profile.jsp" class="active">Profile</a></li>
        <li><a href="federation.jsp">Federation</a></li>
        <li><a href="settings.jsp">Settings</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Your Profile — NWE Chat™</span>
        <h1>Profile</h1>
        <p>Manage your profile picture, resume, and view other users' profiles.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Profile Picture</h2>
        <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:12px;padding:1.5rem;">
            <div style="display:flex;align-items:center;gap:1.5rem;">
                <div id="avatar-preview" style="width:96px;height:96px;border-radius:50%;background:var(--bg-section);border:2px solid var(--purple);display:flex;align-items:center;justify-content:center;overflow:hidden;">
                    <span style="font-size:2rem;color:var(--text-muted);">👤</span>
                </div>
                <div>
                    <p style="color:var(--text-muted);font-size:0.85rem;margin-bottom:0.75rem;">Upload a profile picture (jpg, png, gif, webp). Visible to other chat users.</p>
                    <input type="file" id="profile-pic-input" accept="image/jpeg,image/png,image/gif,image/webp" onchange="previewPic(this)" style="font-size:0.8rem;color:var(--text-muted);"/>
                    <br/><button class="btn btn-primary" style="margin-top:0.75rem;" onclick="uploadPic()">Upload Profile Picture</button>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Resume</h2>
        <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:12px;padding:1.5rem;">
            <p style="color:var(--text-muted);font-size:0.85rem;margin-bottom:0.75rem;">Upload your resume if wanted. Accepted formats: pdf, doc, docx, txt, rtf, odt. Viewable by other users on your profile.</p>
            <input type="file" id="resume-input" accept=".pdf,.doc,.docx,.txt,.rtf,.odt" style="font-size:0.8rem;color:var(--text-muted);"/>
            <br/><button class="btn btn-primary" style="margin-top:0.75rem;" onclick="uploadResume()">Upload Resume</button>
            <p id="resume-status" style="margin-top:0.5rem;font-size:0.8rem;color:var(--purple-hover);"></p>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>My Profile Info</h2>
        <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:12px;padding:1.5rem;">
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:0.5rem;font-size:0.85rem;">
                <span style="color:var(--text-muted);">Username</span><span>(login required)</span>
                <span style="color:var(--text-muted);">Email</span><span>(login required)</span>
                <span style="color:var(--text-muted);">Profile Picture</span><span>(login required)</span>
                <span style="color:var(--text-muted);">Resume</span><span>(login required)</span>
                <span style="color:var(--text-muted);">Geo</span><span>(login required)</span>
                <span style="color:var(--text-muted);">Federated Connects</span><span>(login required)</span>
                <span style="color:var(--text-muted);">Rank</span><span>(login required)</span>
                <span style="color:var(--text-muted);">Member Since</span><span>(login required)</span>
            </div>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>View Another User's Profile</h2>
        <form style="display:flex;gap:0.75rem;align-items:flex-end;flex-wrap:wrap;max-width:500px;">
            <div class="form-group" style="margin:0;flex:1;">
                <label>Username</label>
                <input type="text" id="view-user" placeholder="Enter username"/>
            </div>
            <button type="button" class="btn btn-ghost" onclick="viewProfile()">View</button>
        </form>
        <div id="profile-result" style="margin-top:1rem;"></div>
    </div>
</section>

<footer class="footer">
    <span>NWE Chat™ — Profile — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>

<script>
function previewPic(input) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();
        reader.onload = function(e) {
            document.getElementById('avatar-preview').innerHTML = '<img src="' + e.target.result + '" style="width:100%;height:100%;object-fit:cover;"/>';
        };
        reader.readAsDataURL(input.files[0]);
    }
}
function uploadPic() {
    var input = document.getElementById('profile-pic-input');
    if (!input.files || !input.files[0]) { alert('Select an image first.'); return; }
    alert('Profile picture "' + input.files[0].name + '" ready for upload via SET_PROFILE_PIC on port 49230.');
}
function uploadResume() {
    var input = document.getElementById('resume-input');
    if (!input.files || !input.files[0]) { alert('Select a resume file first.'); return; }
    document.getElementById('resume-status').textContent = '✓ Resume "' + input.files[0].name + '" selected. Upload via UPLOAD_RESUME on port 49230.';
}
function viewProfile() {
    var user = document.getElementById('view-user').value.trim();
    if (!user) { alert('Enter a username.'); return; }
    document.getElementById('profile-result').innerHTML = '<div style="background:var(--bg-card);border:1px solid var(--border);border-radius:12px;padding:1rem;"><p style="color:var(--accent-hover);font-weight:600;">' + user + '</p><p style="color:var(--text-muted);font-size:0.85rem;">Use VIEW_PROFILE|' + user + ' via port 49230 or CD1 connector to load full profile.</p></div>';
}
</script>
</body>
</html>
