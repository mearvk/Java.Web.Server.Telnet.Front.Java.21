<%-- db-connect.jsp — Loads db.properties from multiple locations, sets conn variable --%>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream, java.io.FileInputStream, java.io.File" %>
<%
    Properties dbProps = new Properties();
    boolean propsLoaded = false;

    // Try 1: Servlet context resource (standard webapp deployment)
    InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
    if (dbIn != null) {
        dbProps.load(dbIn);
        dbIn.close();
        propsLoaded = true;
    }

    // Try 2: File system relative to webapp real path
    if (!propsLoaded) {
        String realPath = application.getRealPath("/WEB-INF/db.properties");
        if (realPath != null) {
            File f = new File(realPath);
            if (f.exists()) {
                FileInputStream fis = new FileInputStream(f);
                dbProps.load(fis);
                fis.close();
                propsLoaded = true;
            }
        }
    }

    // Try 3: Known absolute path (fallback for non-standard deploys)
    if (!propsLoaded) {
        String[] paths = {
            "/opt/tomcat/webapps/brarner.m.alete/WEB-INF/db.properties",
            System.getProperty("user.dir") + "/servlets/servlet/src/main/webapp/WEB-INF/db.properties",
            "/mnt/blockstorage/Java.Web.Server.Telnet.Front.Java.21/modules/black/presidential/Brarner.M.Alete/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
        };
        for (String p : paths) {
            File f = new File(p);
            if (f.exists()) {
                FileInputStream fis = new FileInputStream(f);
                dbProps.load(fis);
                fis.close();
                propsLoaded = true;
                break;
            }
        }
    }

    String dbDriver = dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver");
    String dbUrl = dbProps.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience");
    String dbUser = dbProps.getProperty("db.user", "root");
    String dbPass = dbProps.getProperty("db.password", "");
    Class.forName(dbDriver);
    Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
%>
