/**
 * BMA Connector Dialog — Shared JavaScript
 * Handles the CD1 connector button, dialog toggle, and Strernary/Direct port routing.
 *
 * Include this script in any BMA JSP page after the CD1 dialog HTML block.
 * Requires: cd1-btn, cd1-dialog, cd1-overlay, cd1-textarea, cd1-action, cd1-direct-port (checkbox)
 *
 * MEARVK LLC — 2026
 */
(function() {
    var btn = document.getElementById("cd1-btn");
    var dialog = document.getElementById("cd1-dialog");
    var overlay = document.getElementById("cd1-overlay");
    var textarea = document.getElementById("cd1-textarea");
    if (!btn || !dialog || !overlay || !textarea) return;

    // Restore direct-port preference from localStorage
    var directCheck = document.getElementById("cd1-direct-port");
    if (directCheck) {
        var saved = localStorage.getItem("bma-cd1-direct-port");
        if (saved === "true") directCheck.checked = true;
        directCheck.addEventListener("change", function() {
            localStorage.setItem("bma-cd1-direct-port", directCheck.checked);
            var ts = new Date().toLocaleTimeString();
            if (directCheck.checked) {
                textarea.value += "[" + ts + "] MODE: Direct port (bypassing Strernary™ port 20000)\n";
            } else {
                textarea.value += "[" + ts + "] MODE: Strernary™ inference (port 20000)\n";
            }
            textarea.scrollTop = textarea.scrollHeight;
        });
    }

    // Dialog toggle
    btn.addEventListener("click", function() {
        if (dialog.style.display !== "none") {
            dialog.style.display = "none";
            overlay.style.display = "none";
            btn.setAttribute("aria-pressed", "false");
            btn.style.transform = "";
            btn.style.filter = "";
            return;
        }
        btn.setAttribute("aria-pressed", "true");
        btn.style.transform = "scale(0.9)";
        btn.style.filter = "drop-shadow(0 0 8px #3b82f6)";
        setTimeout(function() {
            btn.style.transform = "";
            btn.style.filter = "";
            dialog.style.display = "block";
            overlay.style.display = "block";
        }, 750);
    });
    overlay.addEventListener("click", function() {
        dialog.style.display = "none";
        overlay.style.display = "none";
        btn.setAttribute("aria-pressed", "false");
        btn.style.transform = "";
        btn.style.filter = "";
    });
})();

/**
 * Returns whether the user wants direct port connection (bypassing Strernary).
 */
function cd1IsDirectPort() {
    var cb = document.getElementById("cd1-direct-port");
    return cb ? cb.checked : false;
}

/**
 * Returns the active routing mode label.
 */
function cd1RoutingLabel() {
    return cd1IsDirectPort() ? "DIRECT" : "STRERNARY";
}

function cd1Send() {
    var s = document.getElementById("cd1-action");
    var t = document.getElementById("cd1-textarea");
    if (!s || !t) return;
    var action = s.value;
    var ts = new Date().toLocaleTimeString();
    var mode = cd1RoutingLabel();
    var portInput = document.getElementById("cd1-port");
    var port = portInput ? portInput.value : "20000";
    var roleInput = document.getElementById("cd1-role");
    var role = roleInput ? roleInput.value : "guest";

    // If direct-port mode and action is connect, show the direct port info
    if (cd1IsDirectPort()) {
        var directPort = portInput ? portInput.value : (window.CD1_MODULE_PORT || "unknown");
        t.value += "[" + ts + "] [" + mode + "] " + action.toUpperCase() + " → port " + directPort + " (direct, no Strernary relay)\n";
    } else {
        t.value += "[" + ts + "] [" + mode + "] " + action.toUpperCase() + " → port 20000 (Strernary™ inference)\n";
    }
    t.scrollTop = t.scrollHeight;
}

function cd1Ok() {
    var t = document.getElementById("cd1-textarea");
    if (!t) return;
    t.value += "[" + new Date().toLocaleTimeString() + "] OK.\n";
    t.scrollTop = t.scrollHeight;
}
