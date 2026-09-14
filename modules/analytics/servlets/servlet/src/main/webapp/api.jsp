<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%--
    NitroWebExpress™ — Analytics JSON API
    Returns traffic data as JSON for JavaScript fetch() calls.
    Used by .data.jsp for auto-refresh without full page reload.

    Params:
        module  - module name (default: ALL)
        type    - views|users|uploads|clones|referrers|content (default: views)
        days    - lookback period in days (default: 14, max: 90)
--%>
<%
    response.setHeader("Cache-Control", "no-cache");
    String module = request.getParameter("module");
    if (module == null || module.isEmpty()) module = "ALL";
    String type = request.getParameter("type");
    if (type == null || type.isEmpty()) type = "views";
    int days = 14;
    try { days = Math.min(Integer.parseInt(request.getParameter("days")), 90); } catch (Exception e) {}

    StringBuilder json = new StringBuilder("{");
    Connection conn = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_analytics", "root", "$$Ironman1");

        if ("views".equals(type)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT view_date, total_views, unique_visitors FROM page_views " +
                "WHERE module_name = ? AND view_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) ORDER BY view_date ASC");
            ps.setString(1, module); ps.setInt(2, days);
            ResultSet rs = ps.executeQuery();
            json.append("\"labels\":["); StringBuilder d1 = new StringBuilder(); StringBuilder d2 = new StringBuilder();
            boolean first = true;
            while (rs.next()) {
                if (!first) { json.append(","); d1.append(","); d2.append(","); }
                json.append("\"").append(rs.getString(1)).append("\"");
                d1.append(rs.getInt(2)); d2.append(rs.getInt(3));
                first = false;
            }
            json.append("],\"total\":[").append(d1).append("],\"unique\":[").append(d2).append("]");
            rs.close(); ps.close();

        } else if ("users".equals(type)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT register_date, user_count FROM new_users " +
                "WHERE module_name = ? AND register_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) ORDER BY register_date ASC");
            ps.setString(1, module); ps.setInt(2, days);
            ResultSet rs = ps.executeQuery();
            json.append("\"labels\":["); StringBuilder d1 = new StringBuilder();
            boolean first = true;
            while (rs.next()) {
                if (!first) { json.append(","); d1.append(","); }
                json.append("\"").append(rs.getString(1)).append("\"");
                d1.append(rs.getInt(2));
                first = false;
            }
            json.append("],\"count\":[").append(d1).append("]");
            rs.close(); ps.close();

        } else if ("uploads".equals(type)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT upload_date, upload_count, total_bytes FROM uploads " +
                "WHERE module_name = ? AND upload_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) ORDER BY upload_date ASC");
            ps.setString(1, module); ps.setInt(2, days);
            ResultSet rs = ps.executeQuery();
            json.append("\"labels\":["); StringBuilder d1 = new StringBuilder(); StringBuilder d2 = new StringBuilder();
            boolean first = true;
            while (rs.next()) {
                if (!first) { json.append(","); d1.append(","); d2.append(","); }
                json.append("\"").append(rs.getString(1)).append("\"");
                d1.append(rs.getInt(2)); d2.append(rs.getLong(3));
                first = false;
            }
            json.append("],\"count\":[").append(d1).append("],\"bytes\":[").append(d2).append("]");
            rs.close(); ps.close();

        } else if ("clones".equals(type)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT clone_date, total_clones, unique_cloners FROM clones " +
                "WHERE module_name = ? AND clone_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) ORDER BY clone_date ASC");
            ps.setString(1, module); ps.setInt(2, days);
            ResultSet rs = ps.executeQuery();
            json.append("\"labels\":["); StringBuilder d1 = new StringBuilder(); StringBuilder d2 = new StringBuilder();
            boolean first = true;
            while (rs.next()) {
                if (!first) { json.append(","); d1.append(","); d2.append(","); }
                json.append("\"").append(rs.getString(1)).append("\"");
                d1.append(rs.getInt(2)); d2.append(rs.getInt(3));
                first = false;
            }
            json.append("],\"total\":[").append(d1).append("],\"unique\":[").append(d2).append("]");
            rs.close(); ps.close();

        } else if ("referrers".equals(type)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT referrer_domain, SUM(visit_count) as vc, SUM(unique_visitors) as uv " +
                "FROM referring_sites WHERE module_name = ? AND ref_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                "GROUP BY referrer_domain ORDER BY vc DESC LIMIT 20");
            ps.setString(1, module); ps.setInt(2, days);
            ResultSet rs = ps.executeQuery();
            json.append("\"rows\":[");
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                json.append("{\"domain\":\"").append(rs.getString(1).replace("\"","\\\""))
                    .append("\",\"views\":").append(rs.getInt(2))
                    .append(",\"unique\":").append(rs.getInt(3)).append("}");
                first = false;
            }
            json.append("]");
            rs.close(); ps.close();

        } else if ("content".equals(type)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT page_path, SUM(view_count) as vc, SUM(unique_visitors) as uv " +
                "FROM popular_content WHERE module_name = ? AND content_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                "GROUP BY page_path ORDER BY vc DESC LIMIT 20");
            ps.setString(1, module); ps.setInt(2, days);
            ResultSet rs = ps.executeQuery();
            json.append("\"rows\":[");
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                json.append("{\"path\":\"").append(rs.getString(1).replace("\"","\\\""))
                    .append("\",\"views\":").append(rs.getInt(2))
                    .append(",\"unique\":").append(rs.getInt(3)).append("}");
                first = false;
            }
            json.append("]");
            rs.close(); ps.close();
        }

        json.append(",\"ok\":true}");
    } catch (Exception e) {
        json = new StringBuilder("{\"ok\":false,\"error\":\"" + e.getMessage().replace("\"","\\\"") + "\"}");
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }
%><%= json.toString() %>
