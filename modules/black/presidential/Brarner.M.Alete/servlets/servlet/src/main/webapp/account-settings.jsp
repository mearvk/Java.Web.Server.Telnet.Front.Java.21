<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*, java.nio.file.*, java.security.MessageDigest" %>
<%
    // ─── DB Connection ───
    Properties dbProps = new Properties();
    boolean propsLoaded = false;
    InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
    if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
    if (!propsLoaded) {
        String rp = application.getRealPath("/WEB-INF/db.properties");
        if (rp != null && new File(rp).exists()) { FileInputStream fis = new FileInputStream(rp); dbProps.load(fis); fis.close(); propsLoaded = true; }
    }
    if (!propsLoaded) {
        String[] tryPaths = { "/opt/tomcat/webapps/brarner.m.alete/WEB-INF/db.properties",
            System.getProperty("user.dir") + "/servlets/servlet/src/main/webapp/WEB-INF/db.properties",
            "/mnt/blockstorage/Java.Web.Server.Telnet.Front.Java.21/modules/black/presidential/Brarner.M.Alete/servlets/servlet/src/main/webapp/WEB-INF/db.properties" };
        for (String tp : tryPaths) { File f = new File(tp); if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; break; } }
    }

    Connection conn = null;
    String message = null;
    String messageColor = "#22c55e";
    String userId = request.getParameter("user_id");
    if (userId == null || userId.isEmpty()) userId = "1"; // Default to user 1 for now

    try {
        Class.forName(dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(
            dbProps.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience"),
            dbProps.getProperty("db.user", "root"),
            dbProps.getProperty("db.password", ""));

        // ─── Create tables if not exist ───
        Statement st = conn.createStatement();
        st.executeUpdate(
            "CREATE TABLE IF NOT EXISTS account_settings (" +
            "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
            "  user_id VARCHAR(64) NOT NULL UNIQUE," +
            "  display_name VARCHAR(200)," +
            "  email VARCHAR(320)," +
            "  phone VARCHAR(30)," +
            "  organization VARCHAR(200)," +
            "  title VARCHAR(100)," +
            "  bio TEXT," +
            "  ssl_public_key TEXT," +
            "  ssl_key_filename VARCHAR(200)," +
            "  ssl_key_fingerprint VARCHAR(128)," +
            "  ssl_key_type VARCHAR(20) DEFAULT 'RSA'," +
            "  ssl_key_bits INT DEFAULT 2048," +
            "  dh_group VARCHAR(30) DEFAULT 'modp2048'," +
            "  dh_key_exchange_mode VARCHAR(30) DEFAULT 'ephemeral'," +
            "  dh_custom_prime TEXT," +
            "  dh_custom_generator TEXT," +
            "  pref_strernary_enabled BOOLEAN DEFAULT TRUE," +
            "  pref_strernary_timeout INT DEFAULT 25," +
            "  pref_direct_port_default BOOLEAN DEFAULT FALSE," +
            "  pref_theme VARCHAR(20) DEFAULT 'dark'," +
            "  pref_language VARCHAR(10) DEFAULT 'en'," +
            "  pref_notifications BOOLEAN DEFAULT TRUE," +
            "  ref_name_1 VARCHAR(200)," +
            "  ref_title_1 VARCHAR(100)," +
            "  ref_org_1 VARCHAR(200)," +
            "  ref_email_1 VARCHAR(320)," +
            "  ref_phone_1 VARCHAR(30)," +
            "  ref_relationship_1 VARCHAR(100)," +
            "  ref_name_2 VARCHAR(200)," +
            "  ref_title_2 VARCHAR(100)," +
            "  ref_org_2 VARCHAR(200)," +
            "  ref_email_2 VARCHAR(320)," +
            "  ref_phone_2 VARCHAR(30)," +
            "  ref_relationship_2 VARCHAR(100)," +
            "  ref_name_3 VARCHAR(200)," +
            "  ref_title_3 VARCHAR(100)," +
            "  ref_org_3 VARCHAR(200)," +
            "  ref_email_3 VARCHAR(320)," +
            "  ref_phone_3 VARCHAR(30)," +
            "  ref_relationship_3 VARCHAR(100)," +
            "  fam_father_name VARCHAR(200)," +
            "  fam_father_birthplace VARCHAR(200)," +
            "  fam_mother_name VARCHAR(200)," +
            "  fam_mother_birthplace VARCHAR(200)," +
            "  fam_spouse_name VARCHAR(200)," +
            "  fam_children_count INT DEFAULT 0," +
            "  fam_siblings TEXT," +
            "  fam_ancestry_origin VARCHAR(300)," +
            "  fam_notes TEXT," +
            "  installer_id VARCHAR(64)," +
            "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
            "  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
            ")"
        );
        st.close();

        // ─── Handle POST (save settings) ───
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            // Read all fields from request
            String displayName = request.getParameter("display_name");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String organization = request.getParameter("organization");
            String titleField = request.getParameter("title");
            String bio = request.getParameter("bio");
            String sslPublicKey = request.getParameter("ssl_public_key");
            String sslKeyFilename = request.getParameter("ssl_key_filename");
            String sslKeyType = request.getParameter("ssl_key_type");
            String sslKeyBitsStr = request.getParameter("ssl_key_bits");
            String dhGroup = request.getParameter("dh_group");
            String dhMode = request.getParameter("dh_key_exchange_mode");
            String dhPrime = request.getParameter("dh_custom_prime");
            String dhGenerator = request.getParameter("dh_custom_generator");
            String prefStrernary = request.getParameter("pref_strernary_enabled");
            String prefTimeout = request.getParameter("pref_strernary_timeout");
            String prefDirect = request.getParameter("pref_direct_port_default");
            String prefTheme = request.getParameter("pref_theme");
            String prefLang = request.getParameter("pref_language");
            String prefNotif = request.getParameter("pref_notifications");
            // References
            String refName1 = request.getParameter("ref_name_1");
            String refTitle1 = request.getParameter("ref_title_1");
            String refOrg1 = request.getParameter("ref_org_1");
            String refEmail1 = request.getParameter("ref_email_1");
            String refPhone1 = request.getParameter("ref_phone_1");
            String refRel1 = request.getParameter("ref_relationship_1");
            String refName2 = request.getParameter("ref_name_2");
            String refTitle2 = request.getParameter("ref_title_2");
            String refOrg2 = request.getParameter("ref_org_2");
            String refEmail2 = request.getParameter("ref_email_2");
            String refPhone2 = request.getParameter("ref_phone_2");
            String refRel2 = request.getParameter("ref_relationship_2");
            String refName3 = request.getParameter("ref_name_3");
            String refTitle3 = request.getParameter("ref_title_3");
            String refOrg3 = request.getParameter("ref_org_3");
            String refEmail3 = request.getParameter("ref_email_3");
            String refPhone3 = request.getParameter("ref_phone_3");
            String refRel3 = request.getParameter("ref_relationship_3");
            // Family
            String famFather = request.getParameter("fam_father_name");
            String famFatherBp = request.getParameter("fam_father_birthplace");
            String famMother = request.getParameter("fam_mother_name");
            String famMotherBp = request.getParameter("fam_mother_birthplace");
            String famSpouse = request.getParameter("fam_spouse_name");
            String famChildrenStr = request.getParameter("fam_children_count");
            String famSiblings = request.getParameter("fam_siblings");
            String famAncestry = request.getParameter("fam_ancestry_origin");
            String famNotes = request.getParameter("fam_notes");

            int sslKeyBits = 2048;
            try { sslKeyBits = Integer.parseInt(sslKeyBitsStr); } catch (Exception ignored) {}
            int prefTimeoutVal = 25;
            try { prefTimeoutVal = Integer.parseInt(prefTimeout); } catch (Exception ignored) {}
            int famChildren = 0;
            try { famChildren = Integer.parseInt(famChildrenStr); } catch (Exception ignored) {}

            // Compute SSL key fingerprint if key provided
            String fingerprint = "";
            if (sslPublicKey != null && !sslPublicKey.trim().isEmpty()) {
                try {
                    MessageDigest md = MessageDigest.getInstance("SHA-256");
                    byte[] hash = md.digest(sslPublicKey.trim().getBytes("UTF-8"));
                    StringBuilder hex = new StringBuilder();
                    for (byte b : hash) hex.append(String.format("%02x:", b));
                    fingerprint = hex.substring(0, hex.length() - 1);
                } catch (Exception ignored) {}
            }

            // Upsert
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO account_settings (user_id, display_name, email, phone, organization, title, bio, " +
                "ssl_public_key, ssl_key_filename, ssl_key_fingerprint, ssl_key_type, ssl_key_bits, " +
                "dh_group, dh_key_exchange_mode, dh_custom_prime, dh_custom_generator, " +
                "pref_strernary_enabled, pref_strernary_timeout, pref_direct_port_default, pref_theme, pref_language, pref_notifications, " +
                "ref_name_1, ref_title_1, ref_org_1, ref_email_1, ref_phone_1, ref_relationship_1, " +
                "ref_name_2, ref_title_2, ref_org_2, ref_email_2, ref_phone_2, ref_relationship_2, " +
                "ref_name_3, ref_title_3, ref_org_3, ref_email_3, ref_phone_3, ref_relationship_3, " +
                "fam_father_name, fam_father_birthplace, fam_mother_name, fam_mother_birthplace, " +
                "fam_spouse_name, fam_children_count, fam_siblings, fam_ancestry_origin, fam_notes) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) " +
                "ON DUPLICATE KEY UPDATE display_name=VALUES(display_name), email=VALUES(email), phone=VALUES(phone), " +
                "organization=VALUES(organization), title=VALUES(title), bio=VALUES(bio), " +
                "ssl_public_key=VALUES(ssl_public_key), ssl_key_filename=VALUES(ssl_key_filename), " +
                "ssl_key_fingerprint=VALUES(ssl_key_fingerprint), ssl_key_type=VALUES(ssl_key_type), ssl_key_bits=VALUES(ssl_key_bits), " +
                "dh_group=VALUES(dh_group), dh_key_exchange_mode=VALUES(dh_key_exchange_mode), " +
                "dh_custom_prime=VALUES(dh_custom_prime), dh_custom_generator=VALUES(dh_custom_generator), " +
                "pref_strernary_enabled=VALUES(pref_strernary_enabled), pref_strernary_timeout=VALUES(pref_strernary_timeout), " +
                "pref_direct_port_default=VALUES(pref_direct_port_default), pref_theme=VALUES(pref_theme), " +
                "pref_language=VALUES(pref_language), pref_notifications=VALUES(pref_notifications), " +
                "ref_name_1=VALUES(ref_name_1), ref_title_1=VALUES(ref_title_1), ref_org_1=VALUES(ref_org_1), " +
                "ref_email_1=VALUES(ref_email_1), ref_phone_1=VALUES(ref_phone_1), ref_relationship_1=VALUES(ref_relationship_1), " +
                "ref_name_2=VALUES(ref_name_2), ref_title_2=VALUES(ref_title_2), ref_org_2=VALUES(ref_org_2), " +
                "ref_email_2=VALUES(ref_email_2), ref_phone_2=VALUES(ref_phone_2), ref_relationship_2=VALUES(ref_relationship_2), " +
                "ref_name_3=VALUES(ref_name_3), ref_title_3=VALUES(ref_title_3), ref_org_3=VALUES(ref_org_3), " +
                "ref_email_3=VALUES(ref_email_3), ref_phone_3=VALUES(ref_phone_3), ref_relationship_3=VALUES(ref_relationship_3), " +
                "fam_father_name=VALUES(fam_father_name), fam_father_birthplace=VALUES(fam_father_birthplace), " +
                "fam_mother_name=VALUES(fam_mother_name), fam_mother_birthplace=VALUES(fam_mother_birthplace), " +
                "fam_spouse_name=VALUES(fam_spouse_name), fam_children_count=VALUES(fam_children_count), " +
                "fam_siblings=VALUES(fam_siblings), fam_ancestry_origin=VALUES(fam_ancestry_origin), fam_notes=VALUES(fam_notes)"
            );
            int i = 1;
            ps.setString(i++, userId);
            ps.setString(i++, displayName); ps.setString(i++, email); ps.setString(i++, phone);
            ps.setString(i++, organization); ps.setString(i++, titleField); ps.setString(i++, bio);
            ps.setString(i++, sslPublicKey); ps.setString(i++, sslKeyFilename); ps.setString(i++, fingerprint);
            ps.setString(i++, sslKeyType); ps.setInt(i++, sslKeyBits);
            ps.setString(i++, dhGroup); ps.setString(i++, dhMode); ps.setString(i++, dhPrime); ps.setString(i++, dhGenerator);
            ps.setBoolean(i++, "on".equals(prefStrernary) || "true".equals(prefStrernary));
            ps.setInt(i++, prefTimeoutVal);
            ps.setBoolean(i++, "on".equals(prefDirect) || "true".equals(prefDirect));
            ps.setString(i++, prefTheme); ps.setString(i++, prefLang);
            ps.setBoolean(i++, "on".equals(prefNotif) || "true".equals(prefNotif));
            ps.setString(i++, refName1); ps.setString(i++, refTitle1); ps.setString(i++, refOrg1);
            ps.setString(i++, refEmail1); ps.setString(i++, refPhone1); ps.setString(i++, refRel1);
            ps.setString(i++, refName2); ps.setString(i++, refTitle2); ps.setString(i++, refOrg2);
            ps.setString(i++, refEmail2); ps.setString(i++, refPhone2); ps.setString(i++, refRel2);
            ps.setString(i++, refName3); ps.setString(i++, refTitle3); ps.setString(i++, refOrg3);
            ps.setString(i++, refEmail3); ps.setString(i++, refPhone3); ps.setString(i++, refRel3);
            ps.setString(i++, famFather); ps.setString(i++, famFatherBp);
            ps.setString(i++, famMother); ps.setString(i++, famMotherBp);
            ps.setString(i++, famSpouse); ps.setInt(i++, famChildren);
            ps.setString(i++, famSiblings); ps.setString(i++, famAncestry); ps.setString(i++, famNotes);
            ps.executeUpdate();
            ps.close();
            message = "Settings saved successfully.";
            messageColor = "#22c55e";
        }

        // ─── Load existing settings ───
        PreparedStatement loadPs = conn.prepareStatement("SELECT * FROM account_settings WHERE user_id=?");
        loadPs.setString(1, userId);
        ResultSet rs = loadPs.executeQuery();
        // Default values
        String dName="", dEmail="", dPhone="", dOrg="", dTitle="", dBio="";
        String dSslKey="", dSslFilename="", dSslFingerprint="", dSslType="RSA"; int dSslBits=2048;
        String dDhGroup="modp2048", dDhMode="ephemeral", dDhPrime="", dDhGen="";
        boolean dPrefStrernary=true; int dPrefTimeout=25; boolean dPrefDirect=false;
        String dPrefTheme="dark", dPrefLang="en"; boolean dPrefNotif=true;
        String dRef1N="",dRef1T="",dRef1O="",dRef1E="",dRef1P="",dRef1R="";
        String dRef2N="",dRef2T="",dRef2O="",dRef2E="",dRef2P="",dRef2R="";
        String dRef3N="",dRef3T="",dRef3O="",dRef3E="",dRef3P="",dRef3R="";
        String dFamFather="",dFamFatherBp="",dFamMother="",dFamMotherBp="",dFamSpouse="";
        int dFamChildren=0; String dFamSiblings="",dFamAncestry="",dFamNotes="";

        if (rs.next()) {
            dName = rs.getString("display_name") != null ? rs.getString("display_name") : "";
            dEmail = rs.getString("email") != null ? rs.getString("email") : "";
            dPhone = rs.getString("phone") != null ? rs.getString("phone") : "";
            dOrg = rs.getString("organization") != null ? rs.getString("organization") : "";
            dTitle = rs.getString("title") != null ? rs.getString("title") : "";
            dBio = rs.getString("bio") != null ? rs.getString("bio") : "";
            dSslKey = rs.getString("ssl_public_key") != null ? rs.getString("ssl_public_key") : "";
            dSslFilename = rs.getString("ssl_key_filename") != null ? rs.getString("ssl_key_filename") : "";
            dSslFingerprint = rs.getString("ssl_key_fingerprint") != null ? rs.getString("ssl_key_fingerprint") : "";
            dSslType = rs.getString("ssl_key_type") != null ? rs.getString("ssl_key_type") : "RSA";
            dSslBits = rs.getInt("ssl_key_bits");
            dDhGroup = rs.getString("dh_group") != null ? rs.getString("dh_group") : "modp2048";
            dDhMode = rs.getString("dh_key_exchange_mode") != null ? rs.getString("dh_key_exchange_mode") : "ephemeral";
            dDhPrime = rs.getString("dh_custom_prime") != null ? rs.getString("dh_custom_prime") : "";
            dDhGen = rs.getString("dh_custom_generator") != null ? rs.getString("dh_custom_generator") : "";
            dPrefStrernary = rs.getBoolean("pref_strernary_enabled");
            dPrefTimeout = rs.getInt("pref_strernary_timeout");
            dPrefDirect = rs.getBoolean("pref_direct_port_default");
            dPrefTheme = rs.getString("pref_theme") != null ? rs.getString("pref_theme") : "dark";
            dPrefLang = rs.getString("pref_language") != null ? rs.getString("pref_language") : "en";
            dPrefNotif = rs.getBoolean("pref_notifications");
            dRef1N = rs.getString("ref_name_1") != null ? rs.getString("ref_name_1") : "";
            dRef1T = rs.getString("ref_title_1") != null ? rs.getString("ref_title_1") : "";
            dRef1O = rs.getString("ref_org_1") != null ? rs.getString("ref_org_1") : "";
            dRef1E = rs.getString("ref_email_1") != null ? rs.getString("ref_email_1") : "";
            dRef1P = rs.getString("ref_phone_1") != null ? rs.getString("ref_phone_1") : "";
            dRef1R = rs.getString("ref_relationship_1") != null ? rs.getString("ref_relationship_1") : "";
            dRef2N = rs.getString("ref_name_2") != null ? rs.getString("ref_name_2") : "";
            dRef2T = rs.getString("ref_title_2") != null ? rs.getString("ref_title_2") : "";
            dRef2O = rs.getString("ref_org_2") != null ? rs.getString("ref_org_2") : "";
            dRef2E = rs.getString("ref_email_2") != null ? rs.getString("ref_email_2") : "";
            dRef2P = rs.getString("ref_phone_2") != null ? rs.getString("ref_phone_2") : "";
            dRef2R = rs.getString("ref_relationship_2") != null ? rs.getString("ref_relationship_2") : "";
            dRef3N = rs.getString("ref_name_3") != null ? rs.getString("ref_name_3") : "";
            dRef3T = rs.getString("ref_title_3") != null ? rs.getString("ref_title_3") : "";
            dRef3O = rs.getString("ref_org_3") != null ? rs.getString("ref_org_3") : "";
            dRef3E = rs.getString("ref_email_3") != null ? rs.getString("ref_email_3") : "";
            dRef3P = rs.getString("ref_phone_3") != null ? rs.getString("ref_phone_3") : "";
            dRef3R = rs.getString("ref_relationship_3") != null ? rs.getString("ref_relationship_3") : "";
            dFamFather = rs.getString("fam_father_name") != null ? rs.getString("fam_father_name") : "";
            dFamFatherBp = rs.getString("fam_father_birthplace") != null ? rs.getString("fam_father_birthplace") : "";
            dFamMother = rs.getString("fam_mother_name") != null ? rs.getString("fam_mother_name") : "";
            dFamMotherBp = rs.getString("fam_mother_birthplace") != null ? rs.getString("fam_mother_birthplace") : "";
            dFamSpouse = rs.getString("fam_spouse_name") != null ? rs.getString("fam_spouse_name") : "";
            dFamChildren = rs.getInt("fam_children_count");
            dFamSiblings = rs.getString("fam_siblings") != null ? rs.getString("fam_siblings") : "";
            dFamAncestry = rs.getString("fam_ancestry_origin") != null ? rs.getString("fam_ancestry_origin") : "";
            dFamNotes = rs.getString("fam_notes") != null ? rs.getString("fam_notes") : "";
        }
        rs.close(); loadPs.close();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Brarner.M.Alete™ — Account Settings</title>
    <link rel="stylesheet" href="css/style.css"/>
    <style>
        .settings-form { max-width: 800px; margin: 0 auto; }
        .form-section { background: var(--bg-card, #1a1a24); border: 1px solid #27272a; border-radius: 12px; padding: 1.5rem; margin-bottom: 1.5rem; }
        .form-section h3 { color: #fff; font-size: 1rem; margin: 0 0 1rem 0; padding-bottom: 0.5rem; border-bottom: 1px solid #27272a; }
        .form-section h3 .badge { font-size: 0.65rem; background: #1e3a5f; color: #60a5fa; padding: 0.15rem 0.5rem; border-radius: 4px; margin-left: 0.5rem; vertical-align: middle; }
        .form-row { display: flex; gap: 1rem; margin-bottom: 0.75rem; flex-wrap: wrap; }
        .form-group { flex: 1; min-width: 200px; }
        .form-group label { display: block; font-size: 0.75rem; color: #a1a1aa; margin-bottom: 0.3rem; font-weight: 500; }
        .form-group input, .form-group select, .form-group textarea {
            width: 100%; background: #0f0f14; color: #fff; border: 1px solid #27272a; border-radius: 8px;
            padding: 0.5rem 0.75rem; font-size: 0.8rem; font-family: inherit; box-sizing: border-box;
        }
        .form-group textarea { min-height: 80px; resize: vertical; font-family: monospace; }
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus { outline: none; border-color: #3b82f6; }
        .form-check { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem; }
        .form-check input[type="checkbox"] { accent-color: #3b82f6; width: 16px; height: 16px; }
        .form-check label { font-size: 0.8rem; color: #d4d4d8; cursor: pointer; }
        .btn-save { background: #3b82f6; color: #fff; border: none; border-radius: 8px; padding: 0.75rem 2rem; font-size: 0.85rem; font-weight: 600; cursor: pointer; transition: background 0.2s; }
        .btn-save:hover { background: #2563eb; }
        .fingerprint { font-family: monospace; font-size: 0.7rem; color: #71717a; word-break: break-all; margin-top: 0.3rem; }
        .ref-block { background: #0f0f14; border: 1px solid #1f1f2e; border-radius: 8px; padding: 1rem; margin-bottom: 0.75rem; }
        .ref-block-title { font-size: 0.75rem; color: #60a5fa; font-weight: 600; margin-bottom: 0.5rem; }
    </style>
</head>
<body>
<header><nav><a href="index.jsp" style="color:#fff;text-decoration:none;font-weight:700;">Brarner.M.Alete™</a>
    <span style="color:#71717a;margin:0 0.5rem;">|</span>
    <a href="species.jsp" style="color:#a1a1aa;text-decoration:none;font-size:0.85rem;">Species</a>
    <a href="postal.jsp" style="color:#a1a1aa;text-decoration:none;font-size:0.85rem;margin-left:1rem;">Postal</a>
    <a href="art.jsp" style="color:#a1a1aa;text-decoration:none;font-size:0.85rem;margin-left:1rem;">Art</a>
    <a href="science.jsp" style="color:#a1a1aa;text-decoration:none;font-size:0.85rem;margin-left:1rem;">Science</a>
    <a href="legal.jsp" style="color:#a1a1aa;text-decoration:none;font-size:0.85rem;margin-left:1rem;">Legal</a>
    <a href="account-settings.jsp" style="color:#3b82f6;text-decoration:none;font-size:0.85rem;margin-left:1rem;font-weight:600;">Account</a>
</nav></header>

<section class="section">
<div class="section-inner settings-form">
    <h2 style="color:#fff;margin-bottom:0.5rem;">Account Settings</h2>
    <p style="color:#71717a;font-size:0.8rem;margin-bottom:1.5rem;">Manage your profile, security keys, connection preferences, references, and family history.</p>

    <% if (message != null) { %>
    <div style="padding:0.75rem 1rem;border-radius:8px;margin-bottom:1rem;border:1px solid <%= messageColor %>;background:<%= messageColor %>11;color:<%= messageColor %>;font-size:0.8rem;font-weight:600;">
        <%= message %>
    </div>
    <% } %>

    <form method="POST" action="account-settings.jsp?user_id=<%= userId %>">

    <!-- ═══ Profile Information ═══ -->
    <div class="form-section">
        <h3>&#128100; Profile Information</h3>
        <div class="form-row">
            <div class="form-group"><label>Display Name</label><input type="text" name="display_name" value="<%= dName %>" maxlength="200"/></div>
            <div class="form-group"><label>Email</label><input type="email" name="email" value="<%= dEmail %>" maxlength="320"/></div>
        </div>
        <div class="form-row">
            <div class="form-group"><label>Phone</label><input type="tel" name="phone" value="<%= dPhone %>" maxlength="30"/></div>
            <div class="form-group"><label>Organization</label><input type="text" name="organization" value="<%= dOrg %>" maxlength="200"/></div>
        </div>
        <div class="form-row">
            <div class="form-group"><label>Title / Position</label><input type="text" name="title" value="<%= dTitle %>" maxlength="100"/></div>
        </div>
        <div class="form-row">
            <div class="form-group" style="min-width:100%;"><label>Bio</label><textarea name="bio" maxlength="2000" style="font-family:inherit;"><%= dBio %></textarea></div>
        </div>
    </div>

    <!-- ═══ SSL/TLS Keys ═══ -->
    <div class="form-section">
        <h3>&#128274; SSL/TLS Keys <span class="badge">Personal Certificate</span></h3>
        <div class="form-row">
            <div class="form-group"><label>Key Type</label>
                <select name="ssl_key_type">
                    <option value="RSA" <%= "RSA".equals(dSslType) ? "selected" : "" %>>RSA</option>
                    <option value="ECDSA" <%= "ECDSA".equals(dSslType) ? "selected" : "" %>>ECDSA</option>
                    <option value="Ed25519" <%= "Ed25519".equals(dSslType) ? "selected" : "" %>>Ed25519</option>
                    <option value="DSA" <%= "DSA".equals(dSslType) ? "selected" : "" %>>DSA</option>
                </select>
            </div>
            <div class="form-group"><label>Key Size (bits)</label>
                <select name="ssl_key_bits">
                    <option value="1024" <%= dSslBits==1024 ? "selected" : "" %>>1024</option>
                    <option value="2048" <%= dSslBits==2048 ? "selected" : "" %>>2048</option>
                    <option value="3072" <%= dSslBits==3072 ? "selected" : "" %>>3072</option>
                    <option value="4096" <%= dSslBits==4096 ? "selected" : "" %>>4096</option>
                    <option value="256" <%= dSslBits==256 ? "selected" : "" %>>256 (EC)</option>
                    <option value="384" <%= dSslBits==384 ? "selected" : "" %>>384 (EC)</option>
                    <option value="521" <%= dSslBits==521 ? "selected" : "" %>>521 (EC)</option>
                </select>
            </div>
            <div class="form-group"><label>Key Filename</label><input type="text" name="ssl_key_filename" value="<%= dSslFilename %>" placeholder="my-key.pem" maxlength="200"/></div>
        </div>
        <div class="form-row">
            <div class="form-group" style="min-width:100%;"><label>Public Key (PEM/Base64)</label><textarea name="ssl_public_key" placeholder="-----BEGIN PUBLIC KEY-----&#10;...&#10;-----END PUBLIC KEY-----"><%= dSslKey %></textarea></div>
        </div>
        <% if (!dSslFingerprint.isEmpty()) { %>
        <div class="fingerprint">SHA-256 Fingerprint: <%= dSslFingerprint %></div>
        <% } %>
    </div>

    <!-- ═══ Diffie-Hellman Settings ═══ -->
    <div class="form-section">
        <h3>&#128737; Diffie-Hellman Key Exchange</h3>
        <div class="form-row">
            <div class="form-group"><label>DH Group</label>
                <select name="dh_group">
                    <option value="modp1536" <%= "modp1536".equals(dDhGroup) ? "selected" : "" %>>MODP-1536 (Group 5)</option>
                    <option value="modp2048" <%= "modp2048".equals(dDhGroup) ? "selected" : "" %>>MODP-2048 (Group 14)</option>
                    <option value="modp3072" <%= "modp3072".equals(dDhGroup) ? "selected" : "" %>>MODP-3072 (Group 15)</option>
                    <option value="modp4096" <%= "modp4096".equals(dDhGroup) ? "selected" : "" %>>MODP-4096 (Group 16)</option>
                    <option value="modp6144" <%= "modp6144".equals(dDhGroup) ? "selected" : "" %>>MODP-6144 (Group 17)</option>
                    <option value="modp8192" <%= "modp8192".equals(dDhGroup) ? "selected" : "" %>>MODP-8192 (Group 18)</option>
                    <option value="custom" <%= "custom".equals(dDhGroup) ? "selected" : "" %>>Custom Parameters</option>
                </select>
            </div>
            <div class="form-group"><label>Key Exchange Mode</label>
                <select name="dh_key_exchange_mode">
                    <option value="ephemeral" <%= "ephemeral".equals(dDhMode) ? "selected" : "" %>>Ephemeral (DHE)</option>
                    <option value="static" <%= "static".equals(dDhMode) ? "selected" : "" %>>Static DH</option>
                    <option value="anonymous" <%= "anonymous".equals(dDhMode) ? "selected" : "" %>>Anonymous DH (ADH)</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group"><label>Custom Prime (hex, optional)</label><textarea name="dh_custom_prime" placeholder="FFFFFFFF...FFFFFFFF" style="min-height:50px;"><%= dDhPrime %></textarea></div>
            <div class="form-group"><label>Custom Generator (hex, optional)</label><input type="text" name="dh_custom_generator" value="<%= dDhGen %>" placeholder="02"/></div>
        </div>
    </div>

    <!-- ═══ Connection Preferences ═══ -->
    <div class="form-section">
        <h3>&#9881; Connection Preferences <span class="badge">Strernary™</span></h3>
        <div class="form-check">
            <input type="checkbox" id="pref_strernary" name="pref_strernary_enabled" <%= dPrefStrernary ? "checked" : "" %>/>
            <label for="pref_strernary">Enable Strernary™ AI inference (port 20000)</label>
        </div>
        <div class="form-check">
            <input type="checkbox" id="pref_direct" name="pref_direct_port_default" <%= dPrefDirect ? "checked" : "" %>/>
            <label for="pref_direct">Default to Direct Port (bypass Strernary™)</label>
        </div>
        <div class="form-row" style="margin-top:0.75rem;">
            <div class="form-group" style="max-width:200px;"><label>Strernary Timeout (seconds)</label><input type="number" name="pref_strernary_timeout" value="<%= dPrefTimeout %>" min="5" max="120"/></div>
            <div class="form-group" style="max-width:150px;"><label>Theme</label>
                <select name="pref_theme">
                    <option value="dark" <%= "dark".equals(dPrefTheme) ? "selected" : "" %>>Dark</option>
                    <option value="light" <%= "light".equals(dPrefTheme) ? "selected" : "" %>>Light</option>
                    <option value="system" <%= "system".equals(dPrefTheme) ? "selected" : "" %>>System</option>
                </select>
            </div>
            <div class="form-group" style="max-width:150px;"><label>Language</label>
                <select name="pref_language">
                    <option value="en" <%= "en".equals(dPrefLang) ? "selected" : "" %>>English</option>
                    <option value="es" <%= "es".equals(dPrefLang) ? "selected" : "" %>>Spanish</option>
                    <option value="fr" <%= "fr".equals(dPrefLang) ? "selected" : "" %>>French</option>
                    <option value="de" <%= "de".equals(dPrefLang) ? "selected" : "" %>>German</option>
                    <option value="ja" <%= "ja".equals(dPrefLang) ? "selected" : "" %>>Japanese</option>
                    <option value="zh" <%= "zh".equals(dPrefLang) ? "selected" : "" %>>Chinese</option>
                </select>
            </div>
        </div>
        <div class="form-check" style="margin-top:0.5rem;">
            <input type="checkbox" id="pref_notif" name="pref_notifications" <%= dPrefNotif ? "checked" : "" %>/>
            <label for="pref_notif">Enable notifications</label>
        </div>
    </div>

    <!-- ═══ Professional References ═══ -->
    <div class="form-section">
        <h3>&#128188; Professional References</h3>
        <div class="ref-block">
            <div class="ref-block-title">Reference 1</div>
            <div class="form-row">
                <div class="form-group"><label>Name</label><input type="text" name="ref_name_1" value="<%= dRef1N %>" maxlength="200"/></div>
                <div class="form-group"><label>Title</label><input type="text" name="ref_title_1" value="<%= dRef1T %>" maxlength="100"/></div>
                <div class="form-group"><label>Organization</label><input type="text" name="ref_org_1" value="<%= dRef1O %>" maxlength="200"/></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Email</label><input type="email" name="ref_email_1" value="<%= dRef1E %>" maxlength="320"/></div>
                <div class="form-group"><label>Phone</label><input type="tel" name="ref_phone_1" value="<%= dRef1P %>" maxlength="30"/></div>
                <div class="form-group"><label>Relationship</label><input type="text" name="ref_relationship_1" value="<%= dRef1R %>" maxlength="100" placeholder="e.g. Former Manager"/></div>
            </div>
        </div>
        <div class="ref-block">
            <div class="ref-block-title">Reference 2</div>
            <div class="form-row">
                <div class="form-group"><label>Name</label><input type="text" name="ref_name_2" value="<%= dRef2N %>" maxlength="200"/></div>
                <div class="form-group"><label>Title</label><input type="text" name="ref_title_2" value="<%= dRef2T %>" maxlength="100"/></div>
                <div class="form-group"><label>Organization</label><input type="text" name="ref_org_2" value="<%= dRef2O %>" maxlength="200"/></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Email</label><input type="email" name="ref_email_2" value="<%= dRef2E %>" maxlength="320"/></div>
                <div class="form-group"><label>Phone</label><input type="tel" name="ref_phone_2" value="<%= dRef2P %>" maxlength="30"/></div>
                <div class="form-group"><label>Relationship</label><input type="text" name="ref_relationship_2" value="<%= dRef2R %>" maxlength="100"/></div>
            </div>
        </div>
        <div class="ref-block">
            <div class="ref-block-title">Reference 3</div>
            <div class="form-row">
                <div class="form-group"><label>Name</label><input type="text" name="ref_name_3" value="<%= dRef3N %>" maxlength="200"/></div>
                <div class="form-group"><label>Title</label><input type="text" name="ref_title_3" value="<%= dRef3T %>" maxlength="100"/></div>
                <div class="form-group"><label>Organization</label><input type="text" name="ref_org_3" value="<%= dRef3O %>" maxlength="200"/></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Email</label><input type="email" name="ref_email_3" value="<%= dRef3E %>" maxlength="320"/></div>
                <div class="form-group"><label>Phone</label><input type="tel" name="ref_phone_3" value="<%= dRef3P %>" maxlength="30"/></div>
                <div class="form-group"><label>Relationship</label><input type="text" name="ref_relationship_3" value="<%= dRef3R %>" maxlength="100"/></div>
            </div>
        </div>
    </div>

    <!-- ═══ Familial History ═══ -->
    <div class="form-section">
        <h3>&#127795; Familial History</h3>
        <div class="form-row">
            <div class="form-group"><label>Father's Name</label><input type="text" name="fam_father_name" value="<%= dFamFather %>" maxlength="200"/></div>
            <div class="form-group"><label>Father's Birthplace</label><input type="text" name="fam_father_birthplace" value="<%= dFamFatherBp %>" maxlength="200"/></div>
        </div>
        <div class="form-row">
            <div class="form-group"><label>Mother's Name</label><input type="text" name="fam_mother_name" value="<%= dFamMother %>" maxlength="200"/></div>
            <div class="form-group"><label>Mother's Birthplace</label><input type="text" name="fam_mother_birthplace" value="<%= dFamMotherBp %>" maxlength="200"/></div>
        </div>
        <div class="form-row">
            <div class="form-group"><label>Spouse Name</label><input type="text" name="fam_spouse_name" value="<%= dFamSpouse %>" maxlength="200"/></div>
            <div class="form-group" style="max-width:120px;"><label>Children</label><input type="number" name="fam_children_count" value="<%= dFamChildren %>" min="0" max="50"/></div>
        </div>
        <div class="form-row">
            <div class="form-group" style="min-width:100%;"><label>Siblings (names, comma-separated)</label><input type="text" name="fam_siblings" value="<%= dFamSiblings %>" maxlength="500"/></div>
        </div>
        <div class="form-row">
            <div class="form-group"><label>Ancestry / National Origin</label><input type="text" name="fam_ancestry_origin" value="<%= dFamAncestry %>" maxlength="300" placeholder="e.g. Swiss-German, Irish, Japanese"/></div>
        </div>
        <div class="form-row">
            <div class="form-group" style="min-width:100%;"><label>Family Notes</label><textarea name="fam_notes" maxlength="2000" style="font-family:inherit;"><%= dFamNotes %></textarea></div>
        </div>
    </div>

    <!-- ═══ Submit ═══ -->
    <div style="text-align:center;padding:1rem 0 2rem;">
        <button type="submit" class="btn-save">Save All Settings</button>
    </div>

    </form>
</div>
</section>

<footer style="text-align:center;padding:2rem;color:#52525b;font-size:0.75rem;">
    Brarner.M.Alete™ — MEARVK LLC — 2026
</footer>
</body>
</html>
<%
    } catch (Exception e) {
        message = "Database error: " + (e.getMessage() != null ? e.getMessage().replace("<","&lt;") : "unknown");
        messageColor = "#ef4444";
%>
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"/><title>Account Settings — Error</title><link rel="stylesheet" href="css/style.css"/></head>
<body><section class="section"><div class="section-inner">
<h2 style="color:#ef4444;">Database Error</h2>
<p style="color:#a1a1aa;"><%= message %></p>
<p style="color:#71717a;font-size:0.8rem;">Ensure MySQL is running and db.properties is configured. Table will be created automatically on first successful connection.</p>
<a href="index.jsp" style="color:#3b82f6;">← Back to Overview</a>
</div></section></body></html>
<%
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
%>
