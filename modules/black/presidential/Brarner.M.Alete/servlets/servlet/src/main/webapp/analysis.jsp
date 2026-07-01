<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream, java.util.ArrayList, java.util.List" %>
<%!
    // Helper class for taxon info
    static class TaxonEntry {
        String rank;
        String name;
        TaxonEntry(String r, String n) { this.rank = r; this.name = n; }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Analysis — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <style>
        .analysis-card {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .analysis-card h3 { font-size: 1rem; margin-bottom: 0.75rem; color: var(--text-primary); }
        .rank-badge {
            display: inline-block; font-size: 0.7rem; font-weight: 600;
            text-transform: uppercase; letter-spacing: 0.05em;
            padding: 0.2rem 0.6rem; border-radius: 4px; margin-right: 0.5rem;
        }
        .rank-kingdom { background: #7c3aed22; color: #a78bfa; border: 1px solid #7c3aed44; }
        .rank-phylum  { background: #db277822; color: #f472b6; border: 1px solid #db277844; }
        .rank-class   { background: #2563eb22; color: #60a5fa; border: 1px solid #2563eb44; }
        .rank-order   { background: #0891b222; color: #22d3ee; border: 1px solid #0891b244; }
        .rank-family  { background: #05966922; color: #34d399; border: 1px solid #05966944; }

        .upload-zone {
            border: 2px dashed var(--border); border-radius: var(--radius);
            padding: 1.5rem; text-align: center; cursor: pointer;
            transition: border-color 0.2s, background 0.2s; margin-top: 0.75rem;
        }
        .upload-zone:hover, .upload-zone.dragover { border-color: #dc2626; background: rgba(220,38,38,0.04); }
        .upload-zone input[type="file"] { display: none; }
        .upload-zone .icon { font-size: 2rem; margin-bottom: 0.5rem; }
        .upload-zone p { color: var(--text-secondary); font-size: 0.85rem; margin: 0; }

        .type-select { display: flex; gap: 0.5rem; margin-top: 0.75rem; flex-wrap: wrap; }
        .type-select label {
            display: flex; align-items: center; gap: 0.4rem; font-size: 0.82rem;
            color: var(--text-secondary); cursor: pointer; padding: 0.4rem 0.8rem;
            border: 1px solid var(--border); border-radius: 6px;
            transition: border-color 0.2s, background 0.2s;
        }
        .type-select label:has(input:checked) { border-color: #dc2626; background: rgba(220,38,38,0.08); color: #fca5a5; }
        .type-select input[type="radio"] { display: none; }

        .upload-btn {
            background: #dc2626; color: #fff; border: none; border-radius: var(--radius);
            padding: 0.6rem 1.5rem; font-size: 0.85rem; font-weight: 600; cursor: pointer;
            margin-top: 1rem; transition: background 0.2s, transform 0.1s;
        }
        .upload-btn:hover { background: #b91c1c; }
        .upload-btn:active { transform: scale(0.97); }
        .upload-btn:disabled { background: #52525b; cursor: not-allowed; }

        .progress-container { display: none; margin-top: 1rem; }
        .progress-container.active { display: block; }
        .progress-bar-outer { width: 100%; height: 8px; background: #27272a; border-radius: 4px; overflow: hidden; }
        .progress-bar-inner {
            height: 100%; background: linear-gradient(90deg, #dc2626, #ef4444);
            border-radius: 4px; width: 0%; transition: width 0.4s ease;
        }
        .progress-label { display: flex; justify-content: space-between; margin-top: 0.4rem; font-size: 0.75rem; color: var(--text-muted); }
        .progress-stage { color: #ef4444; font-weight: 600; }

        .result-box { display: none; margin-top: 1rem; padding: 1rem; background: #0f1a0f; border: 1px solid #166534; border-radius: var(--radius); }
        .result-box.active { display: block; }
        .result-box.error { background: #1a0f0f; border-color: #991b1b; }
        .result-download {
            display: inline-flex; align-items: center; gap: 0.4rem;
            background: #166534; color: #fff; padding: 0.5rem 1rem;
            border-radius: 6px; font-size: 0.82rem; font-weight: 600;
            text-decoration: none; margin-top: 0.5rem; transition: background 0.2s;
        }
        .result-download:hover { background: #15803d; color: #fff; }

        .file-info { margin-top: 0.5rem; font-size: 0.78rem; color: var(--text-muted); display: none; }
        .file-info.active { display: block; }

        .taxon-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 1.5rem; }
    </style>
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
        <li><a href="analysis.jsp" class="active">Analysis</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="guest.jsp" class="nav-cta">Guest</a>
        <a href="register.jsp" class="nav-cta">Register</a>
        <a href="admin/login.xhtml" class="nav-cta">Admin &#8594;</a>
    </div>
</div></nav>

<!-- CD1 Connector -->
<div style="text-align:center;margin:1.5rem 0 0.5rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">BMA Connector &#8212; Analysis Division</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="poll">Poll Analysis Queue</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#a1a1aa;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#3b82f6;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#1e3a5f;color:#60a5fa;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>var CD1_MODULE_PORT = "49152";</script>

<section class="hero" style="padding:3rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Data &#183; Audio &#183; Image Analysis</span>
        <h1>Taxonomy Analysis</h1>
        <p>Upload data, audio, or image files for analysis per taxonomy level. Files are scanned by ClamAV and heuristic analysis, then processed by SignalProcessor&#8482; for results.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    // Load taxonomy entries from DB to build upload cards
    Connection conn = null;
    List<TaxonEntry> entries = new ArrayList<>();
    try {
        Properties dbProps = new Properties();
        InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); }
        String dbUrl = dbProps.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience");
        String dbUser = dbProps.getProperty("db.user", "root");
        String dbPass = dbProps.getProperty("db.password", "");
        Class.forName(dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // Kingdoms
        PreparedStatement ps = conn.prepareStatement(
            "SELECT DISTINCT kingdom FROM animalia WHERE kingdom IS NOT NULL AND kingdom!='' ORDER BY kingdom");
        ResultSet rs = ps.executeQuery();
        while (rs.next()) entries.add(new TaxonEntry("kingdom", rs.getString("kingdom")));
        rs.close(); ps.close();

        // Classes (top 20 by order count)
        ps = conn.prepareStatement(
            "SELECT class_name, COUNT(DISTINCT order_name) AS cnt FROM animalia WHERE class_name IS NOT NULL AND class_name!='' GROUP BY class_name ORDER BY cnt DESC LIMIT 20");
        rs = ps.executeQuery();
        while (rs.next()) entries.add(new TaxonEntry("class", rs.getString("class_name")));
        rs.close(); ps.close();

        // Orders (top 20 by family count)
        ps = conn.prepareStatement(
            "SELECT order_name, COUNT(DISTINCT family_name) AS cnt FROM animalia WHERE order_name IS NOT NULL AND order_name!='' GROUP BY order_name ORDER BY cnt DESC LIMIT 20");
        rs = ps.executeQuery();
        while (rs.next()) entries.add(new TaxonEntry("order", rs.getString("order_name")));
        rs.close(); ps.close();

        // Families (top 20 by species count)
        ps = conn.prepareStatement(
            "SELECT family_name, COUNT(*) AS cnt FROM animalia WHERE family_name IS NOT NULL AND family_name!='' GROUP BY family_name ORDER BY cnt DESC LIMIT 20");
        rs = ps.executeQuery();
        while (rs.next()) entries.add(new TaxonEntry("family", rs.getString("family_name")));
        rs.close(); ps.close();

    } catch (Exception e) {
        // Fallback: show static entries
        entries.add(new TaxonEntry("kingdom", "Animalia"));
        entries.add(new TaxonEntry("kingdom", "Plantae"));
        entries.add(new TaxonEntry("kingdom", "Fungi"));
        entries.add(new TaxonEntry("class", "Mammalia"));
        entries.add(new TaxonEntry("class", "Aves"));
        entries.add(new TaxonEntry("class", "Insecta"));
        entries.add(new TaxonEntry("class", "Reptilia"));
        entries.add(new TaxonEntry("class", "Actinopterygii"));
        entries.add(new TaxonEntry("order", "Carnivora"));
        entries.add(new TaxonEntry("order", "Primates"));
        entries.add(new TaxonEntry("order", "Lepidoptera"));
        entries.add(new TaxonEntry("order", "Coleoptera"));
        entries.add(new TaxonEntry("family", "Felidae"));
        entries.add(new TaxonEntry("family", "Canidae"));
        entries.add(new TaxonEntry("family", "Hominidae"));
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }

    // Group by rank for display
    String[] ranks = {"kingdom", "phylum", "class", "order", "family"};
    String[] rankLabels = {"Kingdoms", "Phyla", "Classes", "Orders", "Families"};
    for (int ri = 0; ri < ranks.length; ri++) {
        String rank = ranks[ri];
        String label = rankLabels[ri];
        List<TaxonEntry> rankEntries = new ArrayList<>();
        for (TaxonEntry e : entries) { if (e.rank.equals(rank)) rankEntries.add(e); }
        if (rankEntries.isEmpty()) continue;
%>
        <h2 style="margin-bottom:1rem; margin-top:<%= ri > 0 ? "2.5rem" : "0" %>;"><span class="rank-badge rank-<%= rank %>"><%= rank %></span> <%= label %></h2>
        <div class="taxon-grid">
<%
        int idx = 0;
        for (TaxonEntry te : rankEntries) {
            String cardId = rank + "-" + idx;
%>
            <div class="analysis-card" id="card-<%= cardId %>">
                <h3><span class="rank-badge rank-<%= rank %>"><%= rank %></span> <%= te.name %></h3>
                <div class="type-select">
                    <label><input type="radio" name="type-<%= cardId %>" value="data" checked/> &#128202; Data</label>
                    <label><input type="radio" name="type-<%= cardId %>" value="audio"/> &#127925; Audio</label>
                    <label><input type="radio" name="type-<%= cardId %>" value="image"/> &#128247; Image</label>
                </div>
                <div class="upload-zone" id="zone-<%= cardId %>" onclick="document.getElementById('file-<%= cardId %>').click();"
                     ondragover="event.preventDefault();this.classList.add('dragover');"
                     ondragleave="this.classList.remove('dragover');"
                     ondrop="event.preventDefault();this.classList.remove('dragover');handleDrop(event,'<%= cardId %>');">
                    <div class="icon">&#128194;</div>
                    <p>Drop file here or click to browse</p>
                    <p style="font-size:0.75rem;color:var(--text-muted);margin-top:0.3rem;">Max 50MB &#8212; Data: CSV, JSON, XML, TXT &#8212; Audio: MP3, WAV, FLAC &#8212; Image: PNG, JPG, TIFF</p>
                    <input type="file" id="file-<%= cardId %>" accept="*/*" onchange="fileSelected(this,'<%= cardId %>')"/>
                </div>
                <div class="file-info" id="info-<%= cardId %>"></div>
                <button class="upload-btn" id="btn-<%= cardId %>" onclick="startUpload('<%= cardId %>','<%= rank %>','<%= te.name.replace("'", "\\'") %>')" disabled>
                    &#9654; Analyze
                </button>
                <div class="progress-container" id="prog-<%= cardId %>">
                    <div class="progress-bar-outer"><div class="progress-bar-inner" id="bar-<%= cardId %>"></div></div>
                    <div class="progress-label">
                        <span class="progress-stage" id="stage-<%= cardId %>">Uploading...</span>
                        <span id="pct-<%= cardId %>">0%</span>
                    </div>
                </div>
                <div class="result-box" id="result-<%= cardId %>"></div>
            </div>
<%
            idx++;
        }
%>
        </div>
<%
    }
%>
    </div>
</section>

<footer class="footer"><div class="footer-bottom" style="border:none;padding:0;">
    <span>&#169; 2026 MEARVK LLC. All rights reserved.</span>
</div></footer>

<script>
(function() {
    'use strict';

    // Track selected files per card
    var selectedFiles = {};

    window.fileSelected = function(input, cardId) {
        var file = input.files[0];
        if (!file) return;
        selectedFiles[cardId] = file;
        var info = document.getElementById('info-' + cardId);
        info.textContent = file.name + ' (' + formatSize(file.size) + ')';
        info.classList.add('active');
        document.getElementById('btn-' + cardId).disabled = false;
    };

    window.handleDrop = function(event, cardId) {
        var files = event.dataTransfer.files;
        if (files.length > 0) {
            selectedFiles[cardId] = files[0];
            var info = document.getElementById('info-' + cardId);
            info.textContent = files[0].name + ' (' + formatSize(files[0].size) + ')';
            info.classList.add('active');
            document.getElementById('btn-' + cardId).disabled = false;
            // Update the file input too
            var input = document.getElementById('file-' + cardId);
            var dt = new DataTransfer();
            dt.items.add(files[0]);
            input.files = dt.files;
        }
    };

    window.startUpload = function(cardId, rank, taxon) {
        var file = selectedFiles[cardId];
        if (!file) return;

        // Get selected type
        var typeRadios = document.querySelectorAll('input[name="type-' + cardId + '"]');
        var type = 'data';
        for (var i = 0; i < typeRadios.length; i++) {
            if (typeRadios[i].checked) { type = typeRadios[i].value; break; }
        }

        // Disable button, show progress
        var btn = document.getElementById('btn-' + cardId);
        btn.disabled = true;
        btn.textContent = 'Processing...';

        var prog = document.getElementById('prog-' + cardId);
        prog.classList.add('active');

        var resultBox = document.getElementById('result-' + cardId);
        resultBox.classList.remove('active', 'error');

        // Build FormData
        var fd = new FormData();
        fd.append('file', file);
        fd.append('rank', rank);
        fd.append('taxon', taxon);
        fd.append('type', type);

        // Upload via XHR for progress tracking
        var xhr = new XMLHttpRequest();
        xhr.open('POST', 'api/analysis/upload', true);

        xhr.upload.onprogress = function(e) {
            if (e.lengthComputable) {
                var uploadPct = Math.round((e.loaded / e.total) * 15);
                updateProgress(cardId, uploadPct, 'Uploading...');
            }
        };

        xhr.onload = function() {
            if (xhr.status === 202 || xhr.status === 200) {
                var resp = JSON.parse(xhr.responseText);
                pollStatus(cardId, resp.id);
            } else {
                var err = 'Upload failed';
                try { err = JSON.parse(xhr.responseText).error || err; } catch(ex) {}
                showError(cardId, err);
            }
        };

        xhr.onerror = function() { showError(cardId, 'Network error — server may be offline'); };
        xhr.send(fd);
    };

    function pollStatus(cardId, jobId) {
        var interval = setInterval(function() {
            fetch('api/analysis/status?id=' + jobId)
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    updateProgress(cardId, data.progress, stageLabel(data.stage));

                    if (data.stage === 'complete') {
                        clearInterval(interval);
                        showResult(cardId, jobId);
                    } else if (data.stage === 'failed') {
                        clearInterval(interval);
                        showError(cardId, data.error || 'Analysis failed');
                    }
                })
                .catch(function() {
                    clearInterval(interval);
                    showError(cardId, 'Lost connection to server');
                });
        }, 800);
    }

    function updateProgress(cardId, pct, stage) {
        var bar = document.getElementById('bar-' + cardId);
        var stageEl = document.getElementById('stage-' + cardId);
        var pctEl = document.getElementById('pct-' + cardId);
        bar.style.width = pct + '%';
        stageEl.textContent = stage;
        pctEl.textContent = pct + '%';
    }

    function stageLabel(stage) {
        switch(stage) {
            case 'uploading':   return 'Uploading...';
            case 'scanning':    return 'ClamAV Scanning...';
            case 'heuristic':   return 'Heuristic Analysis...';
            case 'processing':  return 'SignalProcessor\u2122...';
            case 'complete':    return 'Complete';
            case 'failed':      return 'Failed';
            default:            return stage;
        }
    }

    function showResult(cardId, jobId) {
        var resultBox = document.getElementById('result-' + cardId);
        resultBox.innerHTML = '<div style="color:#34d399;font-weight:600;margin-bottom:0.5rem;">&#10003; Analysis Complete</div>'
            + '<div style="font-size:0.82rem;color:var(--text-secondary);margin-bottom:0.5rem;">File scanned, heuristic passed, processed by SignalProcessor\u2122.</div>'
            + '<a href="api/analysis/result?id=' + jobId + '" class="result-download">&#128196; Download Results</a>'
            + '<div style="font-size:0.72rem;color:var(--text-muted);margin-top:0.75rem;">Graphs for results coming soon.</div>';
        resultBox.classList.add('active');
        resultBox.classList.remove('error');
        resetButton(cardId);
    }

    function showError(cardId, message) {
        var resultBox = document.getElementById('result-' + cardId);
        resultBox.innerHTML = '<div style="color:#ef4444;font-weight:600;margin-bottom:0.3rem;">&#10007; Analysis Failed</div>'
            + '<div style="font-size:0.82rem;color:#fca5a5;">' + escapeHtml(message) + '</div>';
        resultBox.classList.add('active', 'error');
        resetButton(cardId);
    }

    function resetButton(cardId) {
        var btn = document.getElementById('btn-' + cardId);
        btn.disabled = false;
        btn.textContent = '\u25B6 Analyze';
    }

    function formatSize(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / 1048576).toFixed(1) + ' MB';
    }

    function escapeHtml(s) {
        var d = document.createElement('div');
        d.appendChild(document.createTextNode(s));
        return d.innerHTML;
    }
})();
</script>
<script src="js/cd1-connector.js"></script>
</body>
</html>
