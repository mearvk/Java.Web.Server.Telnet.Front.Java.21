/**
 * NitroWebExpress™ — Scroll Position Preservation
 * Saves and restores scroll position across page reloads, form submissions,
 * and navigation within the same page. Uses sessionStorage keyed by URL path.
 *
 * Include in <head> or before </body> on any JSP page:
 *   <script src="${pageContext.request.contextPath}/js/scroll-preserve.js"></script>
 *
 * MEARVK LLC — 2026
 */
(function() {
    'use strict';

    var STORAGE_KEY = 'nwe-scroll-' + window.location.pathname;

    // Restore scroll position on page load
    function restoreScroll() {
        var saved = sessionStorage.getItem(STORAGE_KEY);
        if (saved) {
            var pos = JSON.parse(saved);
            window.scrollTo(pos.x, pos.y);
        }
    }

    // Save scroll position
    function saveScroll() {
        var pos = { x: window.scrollX || window.pageXOffset, y: window.scrollY || window.pageYOffset };
        try {
            sessionStorage.setItem(STORAGE_KEY, JSON.stringify(pos));
        } catch (e) { /* sessionStorage full or unavailable */ }
    }

    // Save on scroll (debounced)
    var scrollTimer = null;
    window.addEventListener('scroll', function() {
        if (scrollTimer) clearTimeout(scrollTimer);
        scrollTimer = setTimeout(saveScroll, 150);
    }, { passive: true });

    // Save before unload (navigation, reload, form submit)
    window.addEventListener('beforeunload', saveScroll);

    // Restore after DOM is ready
    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        setTimeout(restoreScroll, 0);
    } else {
        document.addEventListener('DOMContentLoaded', restoreScroll);
    }
})();
