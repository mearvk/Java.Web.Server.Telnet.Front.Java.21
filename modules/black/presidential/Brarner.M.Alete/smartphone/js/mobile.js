/* Brarner.M.Alete™ — Smartphone Edition JS */
(function(){
    // ─── Hamburger Menu ───
    var hamburger = document.getElementById("m-hamburger");
    var menu = document.getElementById("m-menu");
    if (hamburger && menu) {
        hamburger.addEventListener("click", function() {
            hamburger.classList.toggle("open");
            menu.classList.toggle("open");
        });
        // Close on link click
        menu.querySelectorAll("a").forEach(function(a) {
            a.addEventListener("click", function() { hamburger.classList.remove("open"); menu.classList.remove("open"); });
        });
    }

    // ─── Bottom Nav Active State ───
    var path = window.location.pathname.split("/").pop() || "index.jsp";
    document.querySelectorAll(".m-bottom-nav a").forEach(function(a) {
        if (a.getAttribute("href") === path) a.classList.add("active");
    });

    // ─── CD1 Connector (Touch) ───
    var cd1btn = document.getElementById("m-cd1-btn");
    var cd1dialog = document.getElementById("m-cd1-dialog");
    var cd1overlay = document.getElementById("m-cd1-overlay");
    if (cd1btn && cd1dialog && cd1overlay) {
        cd1btn.addEventListener("click", function() {
            cd1dialog.style.display = "block";
            cd1overlay.style.display = "block";
        });
        cd1overlay.addEventListener("click", function() {
            cd1dialog.style.display = "none";
            cd1overlay.style.display = "none";
        });
    }

    // ─── Collapsibles ───
    document.querySelectorAll(".m-collapsible-header").forEach(function(h) {
        h.addEventListener("click", function() {
            h.classList.toggle("open");
            var body = h.nextElementSibling;
            if (body) body.classList.toggle("open");
        });
    });

    // ─── Orientation Change ───
    window.addEventListener("orientationchange", function() {
        setTimeout(function() { window.scrollTo(0, window.scrollY); }, 200);
    });

    // ─── Settings: Load from localStorage ───
    window.bmaSettings = {
        load: function() {
            return {
                port: localStorage.getItem("bma-port") || "18500",
                role: localStorage.getItem("bma-role") || "guest",
                page: localStorage.getItem("bma-page") || "legal"
            };
        },
        save: function(port, role) {
            localStorage.setItem("bma-port", port);
            localStorage.setItem("bma-role", role);
        },
        getRole: function() { return localStorage.getItem("bma-role") || "guest"; }
    };

    // Apply saved settings to inputs
    var settings = window.bmaSettings.load();
    var portEl = document.getElementById("cd1-port");
    var roleEl = document.getElementById("cd1-role");
    if (portEl) portEl.value = settings.port;
    if (roleEl) roleEl.value = settings.role;
})();

// ─── CD1 Send/OK (shared across all smartphone pages) ───
function cd1Send() {
    var s = document.getElementById("cd1-action");
    var t = document.getElementById("cd1-textarea");
    var portEl = document.getElementById("cd1-port");
    var roleEl = document.getElementById("cd1-role");
    if (!s || !t) return;
    var action = s.value;
    var ts = new Date().toLocaleTimeString();
    var port = portEl ? portEl.value : "18500";
    var role = roleEl ? roleEl.value : "guest";

    var portNames = {"18500":"caselaw","18501":"uscode","18502":"publiclaws","18503":"precedent","18504":"statutes","18505":"cfr","18506":"counts","18507":"citations"};
    var portName = portNames[port] || "unknown";

    var msg = "";
    switch(action) {
        case "setport":
            msg = "[" + ts + "] SET PORT|" + port + " (" + portName + ") \u2014 Active connector routed\n";
            break;
        case "unsetport":
            msg = "[" + ts + "] UNSET PORT|" + port + " (" + portName + ") \u2014 Disconnected\n";
            break;
        case "saveconfig":
            window.bmaSettings.save(port, role);
            msg = "[" + ts + "] SAVE|port=" + port + "|role=" + role + " \u2014 Saved to " + role + " session\n";
            break;
        case "connect":
            msg = "[" + ts + "] Connecting to port " + port + " (" + portName + ")...\n[" + ts + "] Connected.\n";
            break;
        case "disconnect":
            msg = "[" + ts + "] Disconnecting from port " + port + "...\n[" + ts + "] Disconnected.\n";
            break;
        case "status":
            msg = "[" + ts + "] STATUS|port=" + port + "|" + portName + "|OK|rating=9.5\n";
            break;
        default:
            msg = "[" + ts + "] " + action + " sent to port " + port + ".\n";
    }
    t.value += msg;
    t.scrollTop = t.scrollHeight;
}

function cd1Ok() {
    var t = document.getElementById("cd1-textarea");
    if (!t) return;
    var dialog = document.getElementById("m-cd1-dialog");
    var overlay = document.getElementById("m-cd1-overlay");
    if (dialog) dialog.style.display = "none";
    if (overlay) overlay.style.display = "none";
    t.value += "[" + new Date().toLocaleTimeString() + "] OK.\n";
}
