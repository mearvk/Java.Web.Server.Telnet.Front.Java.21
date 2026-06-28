package com.mearvk.servlet;

import org.apache.catalina.startup.Tomcat;
import org.apache.catalina.Context;
import java.io.File;

public class BmaEmbeddedTomcat {
    public static void main(String[] args) throws Exception {
        int port = args.length > 0 ? Integer.parseInt(args[0]) : 8080;
        String webappDir = args.length > 1 ? args[1] :
            new File("servlets/servlet/src/main/webapp").getAbsolutePath();

        Tomcat tomcat = new Tomcat();
        tomcat.setPort(port);
        tomcat.getConnector();

        Context ctx = tomcat.addWebapp("/brarner.m.alete", new File(webappDir).getAbsolutePath());
        System.out.println("Brarner.M.Alete™ starting on port " + port);
        System.out.println("Webapp: " + webappDir);

        tomcat.start();
        tomcat.getServer().await();
    }
}
