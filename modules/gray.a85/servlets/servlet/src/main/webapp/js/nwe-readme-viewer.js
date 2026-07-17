/**
 * NWE README.md Viewer + Red Pixel Flicker
 * MEARVK LLC — NitroWebExpress™ 2026
 *
 * Features:
 * - Steel/gray README button in upper right
 * - Clean scrollbar display window with wiki/markdown interpreter
 * - Double-click or click-off to close
 * - IQ & Democratic standing speculation prompt
 * - Single-pixel red flicker on white backgrounds (1/1000 area, 1/40 of the time)
 */
(function() {
    'use strict';

    // ── README Button (upper right, with download image + "README.md" text) ──
    var btnContainer = document.createElement('div');
    btnContainer.id = 'nwe-readme-container';
    btnContainer.style.cssText = 'position:fixed;top:12px;right:12px;z-index:9999;display:flex;align-items:center;gap:8px;';

    var btn = document.createElement('button');
    btn.id = 'nwe-readme-btn';
    btn.title = 'Read about this module (README.md)';
    btn.setAttribute('aria-label', 'Open README.md');
    btn.innerHTML = '<img src="images/MearvK.Ltd/communicator/download.jpeg" alt="↓" onerror="this.style.display=\'none\';this.nextSibling.textContent=\'⬇ README.md\'" style="height:28px;width:28px;object-fit:cover;border-radius:3px;vertical-align:middle;background:transparent;margin-right:5px;"/><span style="font-size:11px;font-weight:600;letter-spacing:0.02em;">README.md</span>';
    btn.style.cssText = 'min-width:110px;height:34px;border-radius:6px;' +
        'background:linear-gradient(135deg,#6b7280,#4b5563);border:1px solid #374151;color:#e5e7eb;' +
        'cursor:pointer;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);' +
        'transition:transform 0.15s,box-shadow 0.15s;font-family:system-ui;line-height:1;padding:0 10px;';
    btn.onmouseenter = function() { btn.style.transform = 'scale(1.05)'; btn.style.boxShadow = '0 3px 10px rgba(0,0,0,0.4)'; };
    btn.onmouseleave = function() { btn.style.transform = ''; btn.style.boxShadow = '0 2px 6px rgba(0,0,0,0.3)'; };

    // ── GitHub Button (links to GitHub discussions) ─────────────────────────────
    var ghBtn = document.createElement('a');
    ghBtn.id = 'nwe-github-btn';
    ghBtn.href = 'https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions';
    ghBtn.target = '_blank';
    ghBtn.title = 'GitHub Discussions — a great dinner conversation';
    ghBtn.setAttribute('aria-label', 'GitHub Discussions');
    ghBtn.innerHTML = '<svg height="20" width="20" viewBox="0 0 16 16" fill="#9ca3af" style="vertical-align:middle;margin-right:5px;"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/></svg><span style="font-size:11px;font-weight:600;">GitHub</span>';
    ghBtn.style.cssText = 'min-width:110px;height:34px;border-radius:6px;text-decoration:none;' +
        'background:linear-gradient(135deg,#24292e,#1b1f23);border:1px solid #374151;color:#e5e7eb;' +
        'display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);' +
        'transition:transform 0.15s,box-shadow 0.15s;font-family:system-ui;line-height:1;padding:0 10px;';
    ghBtn.onmouseenter = function() { ghBtn.style.transform = 'scale(1.05)'; ghBtn.style.boxShadow = '0 3px 10px rgba(0,0,0,0.4)'; };
    ghBtn.onmouseleave = function() { ghBtn.style.transform = ''; ghBtn.style.boxShadow = '0 2px 6px rgba(0,0,0,0.3)'; };
    btnContainer.appendChild(ghBtn);
    btnContainer.appendChild(btn);

    document.body.appendChild(btnContainer);

    // ── Overlay + Display Window ───────────────────────────────────────────────
    var overlay = document.createElement('div');
    overlay.id = 'nwe-readme-overlay';
    overlay.style.cssText = 'display:none;position:fixed;inset:0;z-index:10000;background:rgba(0,0,0,0.5);';
    document.body.appendChild(overlay);

    var win = document.createElement('div');
    win.id = 'nwe-readme-window';
    win.style.cssText = 'display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:10001;' +
        'width:680px;max-width:90vw;max-height:80vh;background:#1a1a1a;border:1px solid #333;border-radius:10px;' +
        'box-shadow:0 12px 40px rgba(0,0,0,0.6);overflow:hidden;font-family:system-ui,-apple-system,sans-serif;';
    document.body.appendChild(win);

    var header = document.createElement('div');
    header.style.cssText = 'padding:0.75rem 1rem;border-bottom:1px solid #333;display:flex;justify-content:space-between;align-items:center;';
    header.innerHTML = '<span style="color:#ccc;font-size:0.85rem;font-weight:600;">README.md</span>' +
        '<span style="color:#666;font-size:0.7rem;">double-click or click outside to close</span>';
    win.appendChild(header);

    var content = document.createElement('div');
    content.id = 'nwe-readme-content';
    content.style.cssText = 'padding:1.25rem;overflow-y:auto;max-height:calc(80vh - 80px);color:#d4d4d4;font-size:0.85rem;line-height:1.7;' +
        'scrollbar-width:thin;scrollbar-color:#4b5563 #1a1a1a;';
    win.appendChild(content);

    // Webkit scrollbar styling
    var scrollStyle = document.createElement('style');
    scrollStyle.textContent = '#nwe-readme-content::-webkit-scrollbar{width:6px;}' +
        '#nwe-readme-content::-webkit-scrollbar-track{background:#1a1a1a;border-radius:3px;}' +
        '#nwe-readme-content::-webkit-scrollbar-thumb{background:#4b5563;border-radius:3px;}' +
        '#nwe-readme-content::-webkit-scrollbar-thumb:hover{background:#6b7280;}' +
        '#nwe-readme-content h1{color:#f9fafb;font-size:1.4rem;margin:0 0 0.75rem 0;padding-bottom:0.5rem;border-bottom:1px solid #333;}' +
        '#nwe-readme-content h2{color:#e5e7eb;font-size:1.1rem;margin:1.25rem 0 0.5rem 0;padding-bottom:0.3rem;border-bottom:1px solid #2a2a2a;}' +
        '#nwe-readme-content h3{color:#d1d5db;font-size:0.95rem;margin:1rem 0 0.4rem 0;}' +
        '#nwe-readme-content code{background:#2a2a2a;padding:0.1rem 0.35rem;border-radius:3px;font-size:0.8rem;color:#a5b4fc;}' +
        '#nwe-readme-content pre{background:#111;border:1px solid #333;border-radius:6px;padding:0.75rem;overflow-x:auto;font-size:0.8rem;margin:0.75rem 0;}' +
        '#nwe-readme-content pre code{background:none;padding:0;color:#d4d4d4;}' +
        '#nwe-readme-content table{width:100%;border-collapse:collapse;margin:0.75rem 0;font-size:0.8rem;}' +
        '#nwe-readme-content th{background:#222;padding:0.4rem 0.6rem;text-align:left;color:#9ca3af;border-bottom:1px solid #333;font-size:0.7rem;text-transform:uppercase;letter-spacing:0.03em;}' +
        '#nwe-readme-content td{padding:0.35rem 0.6rem;border-bottom:1px solid #2a2a2a;color:#b0b0b0;}' +
        '#nwe-readme-content ul,#nwe-readme-content ol{padding-left:1.5rem;margin:0.5rem 0;}' +
        '#nwe-readme-content li{margin:0.2rem 0;}' +
        '#nwe-readme-content blockquote{border-left:3px solid #4b5563;padding-left:0.75rem;margin:0.75rem 0;color:#9ca3af;font-style:italic;}' +
        '#nwe-readme-content hr{border:none;border-top:1px solid #333;margin:1rem 0;}' +
        '#nwe-readme-content a{color:#60a5fa;text-decoration:none;}' +
        '#nwe-readme-content strong{color:#f3f4f6;}' +
        '#nwe-readme-content em{color:#d1d5db;}' +
        '#nwe-readme-content .iq-prompt{background:#1f2937;border:1px solid #374151;border-radius:8px;padding:1rem;margin:1rem 0;color:#9ca3af;font-size:0.8rem;}';
    document.head.appendChild(scrollStyle);

    // ── Open/Close Logic ───────────────────────────────────────────────────────
    function openReadme() {
        // Determine README path relative to webapp context
        var contextPath = window.location.pathname.split('/').filter(Boolean)[0] || '';
        var readmePaths = [
            '/README.md',                                              // webapp root
            '../../README.md',                                         // module root
        ];

        // Try to fetch from known module location
        var moduleName = contextPath;
        var fetchUrl = window.location.origin + '/' + contextPath + '/README.md';

        // Fallback: try fetching from the module directory directly
        content.innerHTML = '<p style="color:#666;">Loading README.md...</p>';
        win.style.display = 'block';
        overlay.style.display = 'block';

        fetch(fetchUrl).then(function(r) {
            if (r.ok) return r.text();
            // Try alternate path
            return fetch(window.location.pathname.replace(/[^\/]*$/, '') + 'README.md').then(function(r2) {
                if (r2.ok) return r2.text();
                throw new Error('Not found');
            });
        }).then(function(md) {
            content.innerHTML = renderMarkdown(md);
        }).catch(function() {
            content.innerHTML = renderMarkdown(getEmbeddedReadme());
        });
    }

    function closeReadme() {
        win.style.display = 'none';
        overlay.style.display = 'none';
    }

    btn.addEventListener('click', openReadme);
    overlay.addEventListener('click', closeReadme);
    win.addEventListener('dblclick', closeReadme);

    // ── Simple Wiki/Markdown Interpreter ───────────────────────────────────────
    function renderMarkdown(text) {
        if (!text) return '<p style="color:#666;">No README found.</p>';

        var html = text
            // Code blocks (``` ... ```)
            .replace(/```(\w*)\n([\s\S]*?)```/g, function(m, lang, code) {
                return '<pre><code>' + escHtml(code.trim()) + '</code></pre>';
            })
            // Tables
            .replace(/^\|(.+)\|$/gm, function(line) {
                return '{{TABLE_ROW}}' + line;
            })
            // Headers
            .replace(/^### (.+)$/gm, '<h3>$1</h3>')
            .replace(/^## (.+)$/gm, '<h2>$1</h2>')
            .replace(/^# (.+)$/gm, '<h1>$1</h1>')
            // Horizontal rules
            .replace(/^---+$/gm, '<hr/>')
            // Bold + Italic
            .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.+?)\*/g, '<em>$1</em>')
            .replace(/_(.+?)_/g, '<em>$1</em>')
            // Inline code
            .replace(/`([^`]+)`/g, '<code>$1</code>')
            // Links
            .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank">$1</a>')
            // Unordered lists
            .replace(/^- (.+)$/gm, '<li>$1</li>')
            // Blockquotes
            .replace(/^> (.+)$/gm, '<blockquote>$1</blockquote>')
            // Paragraphs (double newlines)
            .replace(/\n\n/g, '</p><p>')
            // Single newlines in non-special context
            .replace(/\n/g, '<br/>');

        // Process tables
        html = processTable(html);

        // Wrap in paragraph
        html = '<p>' + html + '</p>';

        // Clean up empty paragraphs
        html = html.replace(/<p>\s*<\/p>/g, '');
        html = html.replace(/<p>\s*(<h[123])/g, '$1');
        html = html.replace(/(<\/h[123]>)\s*<\/p>/g, '$1');
        html = html.replace(/<p>\s*(<hr\/>)/g, '$1');
        html = html.replace(/<p>\s*(<pre>)/g, '$1');
        html = html.replace(/(<\/pre>)\s*<\/p>/g, '$1');
        html = html.replace(/<p>\s*(<table)/g, '$1');
        html = html.replace(/(<\/table>)\s*<\/p>/g, '$1');

        // Wrap li in ul
        html = html.replace(/(<li>.*?<\/li>(\s*<br\/>)?)+/g, function(m) {
            return '<ul>' + m.replace(/<br\/>/g, '') + '</ul>';
        });

        // Add IQ & Democratic standing section
        html += '<div class="iq-prompt">' +
            '<strong>Speculate about your IQ and Democratic standing:</strong><br/>' +
            'Consider your reasoning ability, your civic participation, and your contribution to democratic discourse. ' +
            'What do you estimate your IQ to be? Where do you stand democratically? ' +
            'Reflection is the first step toward understanding.' +
            '</div>';

        return html;
    }

    function processTable(html) {
        var lines = html.split('{{TABLE_ROW}}');
        var result = '';
        var inTable = false;
        var headerDone = false;

        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf('|') === -1 || !lines[i].trim().startsWith('|')) {
                if (inTable) { result += '</tbody></table>'; inTable = false; headerDone = false; }
                result += lines[i];
            } else {
                var row = lines[i].trim();
                // Skip separator rows (|---|---|)
                if (/^\|[\s\-:|]+\|$/.test(row)) continue;
                var cells = row.split('|').filter(function(c, idx, arr) { return idx > 0 && idx < arr.length - 1; });
                if (!inTable) {
                    result += '<table><thead><tr>';
                    cells.forEach(function(c) { result += '<th>' + c.trim() + '</th>'; });
                    result += '</tr></thead><tbody>';
                    inTable = true;
                    headerDone = true;
                } else {
                    result += '<tr>';
                    cells.forEach(function(c) { result += '<td>' + c.trim() + '</td>'; });
                    result += '</tr>';
                }
            }
        }
        if (inTable) result += '</tbody></table>';
        return result;
    }

    function escHtml(s) {
        return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    // ── Embedded README fallback ───────────────────────────────────────────────
    function getEmbeddedReadme() {
        var ctx = (window.location.pathname.split('/').filter(Boolean)[0] || 'module').replace(/-/g, ' ');
        return '# ' + ctx.charAt(0).toUpperCase() + ctx.slice(1) + '\n\n' +
            'NitroWebExpress™ Module\n\n' +
            '---\n\n' +
            'README.md could not be loaded from server.\n\n' +
            'Connect to the backend via telnet or the CD1 button for full documentation.\n\n' +
            'Installer Tech ID: Max Rupplin\n\n' +
            'MEARVK LLC — NitroWebExpress™ 2026';
    }

    // ── Single-Pixel Red Flicker ───────────────────────────────────────────────
    // On white backgrounds, 1/1000 of pixels area, 1/40 of the time (~every 25ms check)
    var flickerPixel = document.createElement('div');
    flickerPixel.id = 'nwe-flicker-pixel';
    flickerPixel.style.cssText = 'position:fixed;width:1px;height:1px;background:#ff0000;z-index:99999;pointer-events:none;display:none;';
    document.body.appendChild(flickerPixel);

    function hasWhiteBackground() {
        var bg = window.getComputedStyle(document.body).backgroundColor;
        if (!bg || bg === 'rgba(0, 0, 0, 0)') return false;
        // Parse rgb values
        var m = bg.match(/(\d+)/g);
        if (!m) return false;
        var r = parseInt(m[0]), g = parseInt(m[1]), b = parseInt(m[2]);
        // Consider "white" as very bright backgrounds (r>230, g>230, b>230)
        return r > 230 && g > 230 && b > 230;
    }

    function flickerTick() {
        if (!hasWhiteBackground()) { flickerPixel.style.display = 'none'; return; }
        // 1/40 chance of showing
        if (Math.random() < (1 / 40)) {
            // Place at random position within viewport
            var x = Math.floor(Math.random() * window.innerWidth);
            var y = Math.floor(Math.random() * window.innerHeight);
            flickerPixel.style.left = x + 'px';
            flickerPixel.style.top = y + 'px';
            flickerPixel.style.display = 'block';
            // Hide after 40-80ms
            setTimeout(function() { flickerPixel.style.display = 'none'; }, 40 + Math.random() * 40);
        }
    }

    // Run flicker check every 1000ms (1/40 chance per tick = roughly 1/40 of the time)
    setInterval(flickerTick, 1000);

})();
