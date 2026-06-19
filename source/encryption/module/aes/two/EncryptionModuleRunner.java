/**
 * EncryptionModuleRunner — Reads aes2-config.xml to decide whether to run
 * the configurable AES2 module or the original hardcoded version.
 *
 * @author Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.aes.two;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import java.io.File;
import java.util.Random;

public class EncryptionModuleRunner
{
    private static final String CONFIG_PATH = "source/encryption/module/aes2-config.xml";

    public static void run(Random random, String title, String plainText)
    {
        boolean useConfig = isConfigEnabled();

        if (useConfig)
        {
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
