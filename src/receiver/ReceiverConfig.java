package receiver;

import javax.xml.parsers.*;
import org.w3c.dom.*;
import java.io.File;

/**
 * ReceiverConfig — Parses receiver.only.xml
 * MEARVK LLC — Max Rupplin
 */
public class ReceiverConfig {

    private int port = 443;
    private String host = "0.0.0.0";
    private String tlsVersion = "TLSv1.3";
    private String keystorePath = "psychiatry/secrets/receiver.keystore.jks";
    private String keystorePassword = "changeit";
    private boolean requireClientAuth = false;
    private boolean requirePassword = false;
    private String storageBackend = "mysql";

    // MySQL
    private String mysqlHost = "localhost";
    private int mysqlPort = 3306;
    private String mysqlDatabase = "nwe_receiver";
    private String mysqlUsername = "nwe";
    private String mysqlPassword = "nwe_receiver_pass";
    private String mysqlTable = "received_data";

    // Binary wallet
    private String walletPath = "data/receiver.wallet.bin";
    private int walletMaxSizeMb = 512;

    public ReceiverConfig(String xmlPath) throws Exception {
        Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new File(xmlPath));
        doc.getDocumentElement().normalize();

        // Network
        NodeList net = doc.getElementsByTagName("network");
        if (net.getLength() > 0) {
            Element n = (Element) net.item(0);
            host = getText(n, "host", host);
            port = Integer.parseInt(getText(n, "port", String.valueOf(port)));
            tlsVersion = getText(n, "tls-version", tlsVersion);
            keystorePath = getText(n, "keystore", keystorePath);
            keystorePassword = getText(n, "keystore-password", keystorePassword);
            requireClientAuth = Boolean.parseBoolean(getText(n, "require-client-auth", "false"));
            requirePassword = Boolean.parseBoolean(getText(n, "require-password", "false"));
        }

        // Storage
        NodeList stor = doc.getElementsByTagName("storage");
        if (stor.getLength() > 0) {
            Element s = (Element) stor.item(0);
            storageBackend = getText(s, "backend", storageBackend);

            NodeList my = s.getElementsByTagName("mysql");
            if (my.getLength() > 0) {
                Element m = (Element) my.item(0);
                mysqlHost = getText(m, "host", mysqlHost);
                mysqlPort = Integer.parseInt(getText(m, "port", String.valueOf(mysqlPort)));
                mysqlDatabase = getText(m, "database", mysqlDatabase);
                mysqlUsername = getText(m, "username", mysqlUsername);
                mysqlPassword = getText(m, "password", mysqlPassword);
                mysqlTable = getText(m, "table", mysqlTable);
            }

            NodeList bw = s.getElementsByTagName("binary-wallet");
            if (bw.getLength() > 0) {
                Element b = (Element) bw.item(0);
                walletPath = getText(b, "path", walletPath);
                walletMaxSizeMb = Integer.parseInt(getText(b, "max-size-mb", String.valueOf(walletMaxSizeMb)));
            }
        }
    }

    private String getText(Element parent, String tag, String def) {
        NodeList nl = parent.getElementsByTagName(tag);
        if (nl.getLength() > 0) return nl.item(0).getTextContent().trim();
        return def;
    }

    public int getPort() { return port; }
    public String getHost() { return host; }
    public String getTlsVersion() { return tlsVersion; }
    public String getKeystorePath() { return keystorePath; }
    public String getKeystorePassword() { return keystorePassword; }
    public boolean isRequireClientAuth() { return requireClientAuth; }
    public boolean isRequirePassword() { return requirePassword; }
    public String getStorageBackend() { return storageBackend; }
    public String getMysqlHost() { return mysqlHost; }
    public int getMysqlPort() { return mysqlPort; }
    public String getMysqlDatabase() { return mysqlDatabase; }
    public String getMysqlUsername() { return mysqlUsername; }
    public String getMysqlPassword() { return mysqlPassword; }
    public String getMysqlTable() { return mysqlTable; }
    public String getWalletPath() { return walletPath; }
    public int getWalletMaxSizeMb() { return walletMaxSizeMb; }
}
