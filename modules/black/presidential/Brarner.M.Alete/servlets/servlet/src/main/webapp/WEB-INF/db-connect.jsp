<%-- db-connect.jsp — Reads WEB-INF/db.properties, sets conn variable --%>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream" %>
<%
    Properties dbProps = new Properties();
    InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
    if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); }
    String dbDriver = dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver");
    String dbUrl = dbProps.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience");
    String dbUser = dbProps.getProperty("db.user", "root");
    String dbPass = dbProps.getProperty("db.password", "$$Ironman1");
    Class.forName(dbDriver);
    Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
%>
