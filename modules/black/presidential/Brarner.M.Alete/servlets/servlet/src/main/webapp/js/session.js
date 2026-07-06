/* BMA Session — Cookie-based IP auth with 24-hour degrade */

var BMA_SESSION_COOKIE = 'bma_session';
var BMA_SESSION_HOURS = 24;

function setCookie(name, value, hours) {
    var d = new Date();
    d.setTime(d.getTime() + (hours * 60 * 60 * 1000));
    document.cookie = name + '=' + encodeURIComponent(value) + ';expires=' + d.toUTCString() + ';path=/;SameSite=Lax';
}

function getCookie(name) {
    var match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
    return match ? decodeURIComponent(match[2]) : null;
}

function deleteCookie(name) {
    document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;';
}

function getSession() {
    var raw = getCookie(BMA_SESSION_COOKIE);
    if (!raw) return null;
    try { return JSON.parse(raw); } catch(e) { return null; }
}

function setSession(type, ip, settings) {
    var session = { type: type, ip: ip, settings: settings || {}, created: Date.now() };
    setCookie(BMA_SESSION_COOKIE, JSON.stringify(session), BMA_SESSION_HOURS);
    return session;
}

function enterGuest() {
    var session = setSession('guest', '', {});
    updateNavForSession(session);
    alert('Logged in as Guest. Session expires in 24 hours.');
}

function logout() {
    deleteCookie(BMA_SESSION_COOKIE);
    updateNavForSession(null);
}

function updateNavForSession(session) {
    var actions = document.querySelector('.nav-actions');
    if (!actions) return;
    if (session) {
        var label = session.type === 'registered' ? 'Registered' : 'Guest';
        actions.innerHTML =
            '<span class="nav-session-label">' + label + '</span>' +
            '<a href="javascript:void(0)" class="nav-cta" onclick="logout()">Logout</a>' +
            '<a href="admin/login.xhtml" class="nav-cta">Admin →</a>';
    } else {
        actions.innerHTML =
            '<a href="register.xhtml" class="nav-cta">Register</a>' +
            '<a href="javascript:void(0)" class="nav-cta" onclick="enterGuest()">Guest</a>' +
            '<a href="admin/login.xhtml" class="nav-cta">Admin →</a>';
    }
}

// On page load, check existing session
(function() {
    var session = getSession();
    if (session) updateNavForSession(session);
})();
