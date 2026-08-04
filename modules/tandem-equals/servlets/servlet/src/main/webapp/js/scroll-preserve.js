/**
 * Scroll Preserve — Maintains scroll position on page reload
 * MEARVK LLC — NitroWebExpress™ 2026
 */
(function() {
    var key = "nwe-scroll-" + window.location.pathname;
    var saved = sessionStorage.getItem(key);
    if (saved) {
        window.scrollTo(0, parseInt(saved, 10));
    }
    window.addEventListener("beforeunload", function() {
        sessionStorage.setItem(key, window.scrollY || document.documentElement.scrollTop);
    });
})();
