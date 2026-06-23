package communicator;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import java.io.File;
import java.util.*;

/**
 * TransferSummaryMailer — reads contacts from configuration/transfer-contacts.xml,
 * composes and sends the Transfer of Summary document title to each contact via email.
 *
 * Uses the system sendmail/mailx if available, or falls back to SMTP via javax.mail-compatible
 * socket send on port 25/587.
 */
public class TransferSummaryMailer
{
    private static final String CONTACTS_XML = commons.AppRoot.resolveString("configuration/transfer-contacts.xml");

    private String documentTitle = "";
    private String author = "";
    private String date = "";
    private String subject = "";
    private final List<Contact> contacts = new ArrayList<>();

    public TransferSummaryMailer()
    {
        loadContacts();
    }

    public void sendAll()
    {
        commons.CommonRails.printSystemComponent(this, this.hashCode(),
            ". TransferSummaryMailer: sending to " + contacts.size() + " contacts .");

        for (Contact c : contacts)
        {
            if (c.email != null && !c.email.isBlank())
                sendEmail(c.email, c.name);
            if (c.emailAlt != null && !c.emailAlt.isBlank())
                sendEmail(c.emailAlt, c.name);
        }

        commons.CommonRails.printSystemComponent(this, this.hashCode(),
            ". TransferSummaryMailer: dispatch complete .");
    }

    private void sendEmail(String toAddress, String recipientName)
    {
        String body = composeBody(recipientName);

        try
        {
            // Attempt sendmail first (most Linux servers have this)
            ProcessBuilder pb = new ProcessBuilder("sendmail", "-t");
            pb.redirectErrorStream(true);
            Process p = pb.start();

            String message =
                "To: " + toAddress + "\n" +
                "From: mearvk@mearvk.us\n" +
                "Subject: " + subject + "\n" +
                "Content-Type: text/plain; charset=UTF-8\n" +
                "\n" +
                body + "\n";

            p.getOutputStream().write(message.getBytes());
            p.getOutputStream().close();
            int exit = p.waitFor();

            if (exit == 0)
            {
                commons.CommonRails.printSystemComponent(this, this.hashCode(),
                    ". TransferSummaryMailer: sent to " + toAddress + " via sendmail .");
            }
            else
            {
                // Fallback: try mailx
                sendViaMailx(toAddress, body);
            }
        }
        catch (Exception e)
        {
            // Fallback: try mailx
            sendViaMailx(toAddress, body);
        }
    }

    private void sendViaMailx(String toAddress, String body)
    {
        try
        {
            ProcessBuilder pb = new ProcessBuilder("mail", "-s", subject, toAddress);
            pb.redirectErrorStream(true);
            Process p = pb.start();
            p.getOutputStream().write(body.getBytes());
            p.getOutputStream().close();
            int exit = p.waitFor();

            if (exit == 0)
                commons.CommonRails.printSystemComponent(this, this.hashCode(),
                    ". TransferSummaryMailer: sent to " + toAddress + " via mailx .");
            else
                commons.CommonRails.printSystemComponent(this, this.hashCode(),
                    ". TransferSummaryMailer: FAILED to send to " + toAddress + " (no mail agent) .");
        }
        catch (Exception e)
        {
            commons.CommonRails.printSystemComponent(this, this.hashCode(),
                ". TransferSummaryMailer: FAILED to send to " + toAddress + " — " + e.getMessage() + " .");
        }
    }

    private String composeBody(String recipientName)
    {
        return "═══════════════════════════════════════════════════════════\n" +
               "  TRANSFER OF SUMMARY\n" +
               "═══════════════════════════════════════════════════════════\n\n" +
               "  Document: " + documentTitle + "\n" +
               "  Author:   " + author + "\n" +
               "  Date:     " + date + "\n\n" +
               "  Recipient: " + recipientName + "\n\n" +
               "  This document confirms the transfer of summary for the\n" +
               "  Java National Finance Engine software and its value in\n" +
               "  the United States of America.\n\n" +
               "  Software: NitroWebExpress / Java National Finance Engine v.2811\n" +
               "  Owner:    Max Rupplin — MEARVK LLC\n" +
               "  Contact:  mearvk@mearvk.us | mearvk@outlook.com\n\n" +
               "═══════════════════════════════════════════════════════════\n";
    }

    private void loadContacts()
    {
        try
        {
            File file = new File(CONTACTS_XML);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);

            // Load document metadata
            NodeList titles = doc.getElementsByTagName("title");
            if (titles.getLength() > 0) documentTitle = titles.item(0).getTextContent().trim();
            NodeList authors = doc.getElementsByTagName("author");
            if (authors.getLength() > 0) author = authors.item(0).getTextContent().trim();
            NodeList dates = doc.getElementsByTagName("date");
            if (dates.getLength() > 0) date = dates.item(0).getTextContent().trim();
            NodeList subjects = doc.getElementsByTagName("subject");
            if (subjects.getLength() > 0) subject = subjects.item(0).getTextContent().trim();

            // Load contacts
            NodeList nodes = doc.getElementsByTagName("contact");
            for (int i = 0; i < nodes.getLength(); i++)
            {
                Element el = (Element) nodes.item(i);
                Contact c = new Contact();
                c.name = getTag(el, "name");
                c.email = getTag(el, "email");
                c.emailAlt = getTag(el, "email-alt");
                c.phone = getTag(el, "phone");
                c.state = getTag(el, "state");
                c.location = getTag(el, "location");
                c.nationalId = getTag(el, "nationalId");
                c.role = getTag(el, "role");
                contacts.add(c);
            }
        }
        catch (Exception e) { exceptions.ExceptionHandler.dispatch(e); }
    }

    private static String getTag(Element el, String tag)
    {
        NodeList nl = el.getElementsByTagName(tag);
        return nl.getLength() > 0 ? nl.item(0).getTextContent().trim() : "";
    }

    public List<Contact> getContacts() { return contacts; }
    public String getDocumentTitle() { return documentTitle; }

    /** Standalone entry point for script execution. */
    public static void main(String[] args)
    {
        new TransferSummaryMailer().sendAll();
    }

    public static class Contact
    {
        public String name, email, emailAlt, phone, state, location, nationalId, role;
    }
}
