/* Expandable sections + BMA Server Connection logic */

function toggleExpand(el) {
    el.classList.toggle('open');
}

function toggleBmaPanel(event, el) {
    // Only toggle from header click
    if (el.classList.contains('open') && !event.target.closest('.expandable-header')) return;
    var wasOpen = el.classList.contains('open');
    el.classList.toggle('open');
    // Reset textarea on collapse
    if (wasOpen) {
        var ta = el.querySelector('.bma-textarea');
        if (ta) ta.value = '';
    }
}

function bmaSend(btn) {
    var panel = btn.closest('.bma-panel');
    var select = panel.querySelector('.bma-action-select');
    var textarea = panel.querySelector('.bma-textarea');
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

function bmaOk(btn) {
    var panel = btn.closest('.bma-panel');
    var textarea = panel.querySelector('.bma-textarea');
    var ts = new Date().toLocaleTimeString();
    textarea.value += '[' + ts + '] OK — Acknowledged.\n';
    textarea.scrollTop = textarea.scrollHeight;
}
