/**
 * EncryptionModuleRunner — Reads aes2-config.xml to decide whether to run
 * the configurable AES2 module or the original hardcoded version.
 * On startup, backs up aes2-config.xml and EncryptionModule.java to backups/{date}/.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.aes.two;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import java.io.File;
import java.io.IOException;
import java.nio.file.*;
import java.time.LocalDate;
import java.util.Random;

public class EncryptionModuleRunner
{
    private static final String CONFIG_PATH = "source/encryption/module/aes2-config.xml";
    private static final String EM_PATH = "source/encryption/module/aes/two/EncryptionModule.java";
    private static final String BACKUP_BASE = "source/encryption/module/backups";

    /**
     * Entry point. Ensures backups exist for today, then runs the appropriate module.
     *
     * @param random random seed source
     * @param title module title
     * @param plainText plaintext to encrypt
     * @javaowner Max Rupplin
     */
    public static void run(Random random, String title, String plainText)
    {
        ensureBackup();

        boolean useConfig = isConfigEnabled();

        if (useConfig)
        {
            backupBeforeConfigRun();
            EncryptionModule module = new EncryptionModule(random, title, plainText);
            executeConfigurable(module);
        }
        else
        {
            EncryptionModuleOriginal module = new EncryptionModuleOriginal(random, title, plainText);
            module.one();
            module.two();
            module.three();
            module.four();
        }
    }

    /**
     * On program start: if there is no backups/{date}/aes2-config.xml, copy it there.
     *
     * @javaowner Max Rupplin
     */
    private static void ensureBackup()
    {
        try
        {
            String date = LocalDate.now().toString();
            Path backupDir = Paths.get(BACKUP_BASE, date);
            Files.createDirectories(backupDir);

            Path configBackup = backupDir.resolve("aes2-config.xml");
            if (!Files.exists(configBackup))
            {
                Files.copy(Paths.get(CONFIG_PATH), configBackup, StandardCopyOption.REPLACE_EXISTING);
            }
        }
        catch (IOException e)
        {
            System.err.println("[EncryptionModuleRunner] Backup failed: " + e.getMessage());
        }
    }

    /**
     * Before creating new source from config settings, copy existing EM file to backups/{date}/.
     *
     * @javaowner Max Rupplin
     */
    private static void backupBeforeConfigRun()
    {
        try
        {
            String date = LocalDate.now().toString();
            Path backupDir = Paths.get(BACKUP_BASE, date);
            Files.createDirectories(backupDir);

            Path emBackup = backupDir.resolve("EncryptionModule.java");
            if (!Files.exists(emBackup))
            {
                Files.copy(Paths.get(EM_PATH), emBackup, StandardCopyOption.REPLACE_EXISTING);
            }
        }
        catch (IOException e)
        {
            System.err.println("[EncryptionModuleRunner] EM backup failed: " + e.getMessage());
        }
    }

    /**
     * Checks if the config XML has enabled=true at the top level.
     *
     * @javaowner Max Rupplin
     */
    private static boolean isConfigEnabled()
    {
        try
        {
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new File(CONFIG_PATH));
            doc.getDocumentElement().normalize();
            NodeList nl = doc.getElementsByTagName("enabled");
            if (nl.getLength() > 0)
            {
                return Boolean.parseBoolean(nl.item(0).getTextContent().trim());
            }
        }
        catch (Exception e) { /* fall through to original */ }
        return false;
    }

    /**
     * Executes passes from aes2-config.xml that are enabled.
     *
     * @javaowner Max Rupplin
     */
    private static void executeConfigurable(EncryptionModule module)
    {
        Document doc;
        try
        {
            doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new File(CONFIG_PATH));
            doc.getDocumentElement().normalize();
        }
        catch (Exception e) { return; }

        NodeList passes = doc.getElementsByTagName("pass");
        for (int i = 0; i < passes.getLength(); i++)
        {
            Element pass = (Element) passes.item(i);
            boolean enabled = Boolean.parseBoolean(getTag(pass, "enabled", "false"));
            if (!enabled) continue;

            String method = pass.getAttribute("method");
            switch (method)
            {
                case "one" -> module.one();
                case "two" -> module.two();
                case "three" -> module.three();
                case "four" -> module.four();
                case "five" -> module.five();
                case "six" -> module.six();
                case "seven" -> module.seven();
                case "eight" -> module.eight();
                case "nine" -> module.nine();
                case "ten" -> module.ten();
                case "eleven" -> module.eleven();
                case "twelve" -> module.twelve();
                case "thirteen" -> module.thirteen();
                case "fourteen" -> module.fourteen();
                case "fifteen" -> module.fifteen();
                case "sixteen" -> module.sixteen();
                case "seventeen" -> module.seventeen();
                case "eighteen" -> module.eighteen();
                case "nineteen" -> module.nineteen();
                case "twenty" -> module.twenty();
                case "twentyone" -> module.twentyone();
            }
        }
    }

    private static String getTag(Element parent, String tag, String def)
    {
        NodeList nl = parent.getElementsByTagName(tag);
        if (nl.getLength() > 0) return nl.item(0).getTextContent().trim();
        return def;
    }
}
