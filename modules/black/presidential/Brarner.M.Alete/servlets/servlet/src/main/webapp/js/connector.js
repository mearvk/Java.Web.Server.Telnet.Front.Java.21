/* CD1 Connector — Open/Close with button, idle/reset timers, double-click restore */

(function() {
    var btn = document.getElementById('cd1-btn');
    var dialog = document.getElementById('cd1-dialog');
    var overlay = document.getElementById('cd1-overlay');
    var textarea = document.getElementById('cd1-textarea');

    var IDLE_CLOSE_MS = 20 * 60 * 1000;   // 20 minutes — close + clear text, keep connection info
    var FULL_RESET_MS = 60 * 60 * 1000;   // 60 minutes — full circuit reset

    var idleTimer = null;
    var resetTimer = null;
    var savedContent = '';
    var connectionInfo = '';

    function isOpen() { return dialog.style.display !== 'none'; }

    function openDialog() {
        dialog.style.display = 'block';
        overlay.style.display = 'block';
        btn.setAttribute('aria-pressed', 'true');
        btn.style.transform = 'scale(0.9)';
        btn.style.filter = 'drop-shadow(0 0 8px rgba(59,130,246,0.6))';
        resetIdleTimer();
    }

    function closeDialog() {
        dialog.style.display = 'none';
        overlay.style.display = 'none';
        btn.setAttribute('aria-pressed', 'false');
        btn.style.transform = '';
        btn.style.filter = '';
        // Save content before clearing
        if (textarea.value && textarea.value !== 'Connection idle...') {
            savedContent = textarea.value;
        }
        textarea.value = '';
        textarea.placeholder = 'Connection idle...';
        clearTimeout(idleTimer);
    }

    function fullReset() {
        savedContent = '';
        connectionInfo = '';
        textarea.value = '';
        textarea.placeholder = 'Connection idle...';
        closeDialog();
        clearTimeout(resetTimer);
        resetTimer = null;
    }

    function resetIdleTimer() {
        clearTimeout(idleTimer);
        clearTimeout(resetTimer);
        idleTimer = setTimeout(function() {
            // 20 min idle: close + clear text, keep connection info
            connectionInfo = extractConnectionInfo(textarea.value || savedContent);
            savedContent = textarea.value || savedContent;
            textarea.value = '';
            textarea.placeholder = 'Connection idle...';
            closeDialog();
            // Start full reset timer (remaining 40 min to total 60)
            resetTimer = setTimeout(fullReset, FULL_RESET_MS - IDLE_CLOSE_MS);
        }, IDLE_CLOSE_MS);
    }

    function extractConnectionInfo(text) {
        // Keep lines that mention connect/disconnect status
        if (!text) return '';
        var lines = text.split('\n');
        var info = [];
        for (var i = 0; i < lines.length; i++) {
            if (/connect/i.test(lines[i])) info.push(lines[i]);
        }
        return info.join('\n');
    }

    // Button click toggles
    btn.addEventListener('click', function() {
        if (isOpen()) closeDialog(); else openDialog();
    });

    // Click off (overlay) closes
    overlay.addEventListener('click', function() {
        closeDialog();
    });

    // Double-click textarea restores saved content
    textarea.addEventListener('dblclick', function() {
        if (savedContent) {
            textarea.value = savedContent;
        } else if (connectionInfo) {
            textarea.value = connectionInfo;
        }
    });

    // Any interaction in dialog resets idle timer
    dialog.addEventListener('click', function() { resetIdleTimer(); });
    dialog.addEventListener('keydown', function() { resetIdleTimer(); });

    // Start full reset timer on page load (60 min from page open)
    resetTimer = setTimeout(fullReset, FULL_RESET_MS);
})();

/* CD1 Send/OK actions */
function cd1Send() {
    var select = document.getElementById('cd1-action');
    var textarea = document.getElementById('cd1-textarea');
    var action = select.value;
    var ts = new Date().toLocaleTimeString();
    var msg = '';
    switch (action) {
        case 'connect':
            msg = '[' + ts + '] Connecting to BMA server port 49152...\n[' + ts + '] Connected. Ready for commands.\n';
            break;
        case 'disconnect':
            msg = '[' + ts + '] Disconnecting from BMA server...\n[' + ts + '] Disconnected.\n';
            break;
        case 'poll':
            msg = '[' + ts + '] Polling area data — traversing linked sources...\n[' + ts + '] Poll complete. Data refreshed.\n';
            break;
        case 'hardreset':
            msg = '[' + ts + '] Requesting formal hard reset...\n[' + ts + '] Connection formally closed by server. Reset complete.\n';
            break;
    }
    textarea.value += msg;
    textarea.scrollTop = textarea.scrollHeight;
}

function cd1Ok() {
    var textarea = document.getElementById('cd1-textarea');
    var ts = new Date().toLocaleTimeString();
    textarea.value += '[' + ts + '] OK — Acknowledged.\n';
    textarea.scrollTop = textarea.scrollHeight;
}
