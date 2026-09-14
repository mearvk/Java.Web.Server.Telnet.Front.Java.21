<%@ page import="java.sql.*, java.security.MessageDigest" %>
<%--
    NitroWebExpress™ — Analytics Tracking Include
    ════════════════════════════════════════════════════════════════════════
    Include this at the top of any module's JSP page to auto-record visits
    to the nwe_analytics database.

    Usage (in any module JSP):
        <%@ include file="/WEB-INF/analytics-track.jsp" %>

    Or copy this file to each module's WEB-INF/ and include locally:
        <%@ include file="/WEB-INF/analytics-track.jsp" %>

    Set the module name as a page-scope variable BEFORE including:
        <% String ANALYTICS_MODULE = "Communicator"; %>
        <%@ include file="/WEB-INF/analytics-track.jsp" %>

    If ANALYTICS_MODULE is not set, it derives from the context path.
    ════════════════════════════════════════════════════════════════════════
--%>
<%
{
    String __amod = (String) pageContext.getAttribute("ANALYTICS_MODULE");
    if (__amod == null || __amod.isEmpty()) {
        __amod = request.getContextPath().replaceAll("^/", "");
        if (__amod.isEmpty()) __amod = "root";
    }
    String __aip = request.getRemoteAddr();
    String __aua = request.getHeader("User-Agent");
    if (__aua == null) __aua = "";
    String __aref = request.getHeader("Referer");
    if (__aref == null) __aref = "";
    String __apath = request.getRequestURI();

    // Hash visitor
    String __ahash = __aip;
    try {
        MessageDigest __md = MessageDigest.getInstance("SHA-256");
        byte[] __h = __md.digest((__aip + __aua.substring(0, Math.min(__aua.length(), 32))).getBytes());
        StringBuilder __sb = new StringBuilder();
        for (int __i = 0; __i < 8; __i++) __sb.append(String.format("%02x", __h[__i]));
        __ahash = __sb.toString();
    } catch (Exception __e) {}

    Connection __aconn = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        __aconn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_analytics", "root", "$$Ironman1");

        // Log visit
        PreparedStatement __aps = __aconn.prepareStatement(
            "INSERT INTO visitor_log (module_name, visitor_hash, ip_address, user_agent, page_path, referrer) VALUES (?, ?, ?, ?, ?, ?)");
        __aps.setString(1, __amod);
        __aps.setString(2, __ahash);
        __aps.setString(3, __aip);
        __aps.setString(4, __aua.length() > 512 ? __aua.substring(0, 512) : __aua);
        __aps.setString(5, __apath);
        __aps.setString(6, __aref.length() > 512 ? __aref.substring(0, 512) : __aref);
        __aps.executeUpdate();
        __aps.close();

        // Upsert daily views
        __aps = __aconn.prepareStatement(
            "INSERT INTO page_views (module_name, view_date, total_views, unique_visitors) " +
            "VALUES (?, CURDATE(), 1, 1) " +
            "ON DUPLICATE KEY UPDATE total_views = total_views + 1, " +
            "unique_visitors = (SELECT COUNT(DISTINCT visitor_hash) FROM visitor_log WHERE module_name = ? AND DATE(visited_at) = CURDATE())");
        __aps.setString(1, __amod);
        __aps.setString(2, __amod);
        __aps.executeUpdate();
        __aps.close();

        // Upsert popular content
        __aps = __aconn.prepareStatement(
            "INSERT INTO popular_content (module_name, page_path, content_date, view_count, unique_visitors) " +
            "VALUES (?, ?, CURDATE(), 1, 1) " +
            "ON DUPLICATE KEY UPDATE view_count = view_count + 1");
        __aps.setString(1, __amod);
        __aps.setString(2, __apath);
        __aps.executeUpdate();
        __aps.close();

        // Referrer tracking
        if (!__aref.isEmpty()) {
            String __refDom = "";
            try { __refDom = new java.net.URL(__aref).getHost(); } catch (Exception __ex) { __refDom = __aref; }
            if (!__refDom.isEmpty()) {
                __aps = __aconn.prepareStatement(
                    "INSERT INTO referring_sites (module_name, referrer_domain, ref_date, visit_count, unique_visitors) " +
                    "VALUES (?, ?, CURDATE(), 1, 1) ON DUPLICATE KEY UPDATE visit_count = visit_count + 1");
                __aps.setString(1, __amod);
                __aps.setString(2, __refDom.length() > 256 ? __refDom.substring(0, 256) : __refDom);
                __aps.executeUpdate();
                __aps.close();
            }
        }
    } catch (Exception __ae) {
        // Analytics failure is silent — never break the host page
    } finally {
        if (__aconn != null) try { __aconn.close(); } catch (Exception __e2) {}
    }
}
%>
