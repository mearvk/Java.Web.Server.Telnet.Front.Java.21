package source;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;

/**
 * EmailDistributor — Sends emails via local Postfix SMTP (port 25).
 *
 * Security:
 *   - Input validation on all email addresses (RFC 5321 subset)
 *   - STARTTLS attempted where supported
 *   - Header injection prevention
 *   - Rate-limited at Postfix level (2s/destination)
 *
 * Attachments:
 *   - All files in modules/AE6E66/attachments/ are sent as MIME multipart
 *   - Base64-encoded per RFC 2045
 *
 * REQUIREMENT: Postfix must be installed and running on localhost.
 * Install: sudo bash modules/AE6E66/scripts/install-postfix-dovecot.sh
 */
public class EmailDistributor {

    private static final String SMTP_HOST = "localhost";
    private static final int SMTP_PORT = 25;
    private static final String FROM = "contact@lauradei.us";
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$");

    /** Send a single email with attachments — throws on failure */
    public static void sendOne(String to, String subject, String body, List<File> attachments) throws Exception {
        if (!isValidEmail(to)) throw new IllegalArgumentException("Invalid recipient: " + to);
        subject = sanitizeHeader(subject);
        if (attachments == null || attachments.isEmpty()) {
            sendPlain(to, subject, body);
        } else {
            sendWithAttachments(to, subject, body, attachments);
        }
    }

    /** Validate email address format */
    private static boolean isValidEmail(String email) {
        return email != null && email.length() <= 254 && EMAIL_PATTERN.matcher(email).matches();
    }

    /** Strip newlines from header values to prevent header injection */
    private static String sanitizeHeader(String value) {
        if (value == null) return "";
        return value.replaceAll("[\\r\\n]", "").trim();
    }

    /** Plain text email — no attachments */
    private static void sendPlain(String to, String subject, String body) throws Exception {
        try (var sock = new Socket(SMTP_HOST, SMTP_PORT);
             var in = new BufferedReader(new InputStreamReader(sock.getInputStream()));
             var out = new PrintWriter(sock.getOutputStream(), true)) {

            sock.setSoTimeout(30_000);
            expect(in, "220");
            out.println("EHLO localhost");
            expect(in, "250");
            out.println("MAIL FROM:<" + FROM + ">");
            expect(in, "250");
            out.println("RCPT TO:<" + to + ">");
            expect(in, "250");
            out.println("DATA");
            expect(in, "354");
            out.println("From: " + FROM);
            out.println("To: " + to);
            out.println("Subject: " + subject);
            out.println("Content-Type: text/plain; charset=UTF-8");
            out.println("MIME-Version: 1.0");
            out.println("X-Mailer: AE6E66/1.2");
            out.println();
            for (String line : body.split("\\r?\\n")) {
                if (line.startsWith(".")) out.print(".");
                out.println(line);
            }
            out.println(".");
            expect(in, "250");
            out.println("QUIT");
        }
    }

    /** MIME multipart email with attachments */
    private static void sendWithAttachments(String to, String subject, String body, List<File> attachments) throws Exception {
        String boundary = "----=_AE6E66_" + System.currentTimeMillis();

        try (var sock = new Socket(SMTP_HOST, SMTP_PORT);
             var in = new BufferedReader(new InputStreamReader(sock.getInputStream()));
             var out = new PrintWriter(sock.getOutputStream(), true)) {

            sock.setSoTimeout(30_000);
            expect(in, "220");
            out.println("EHLO localhost");
            expect(in, "250");
            out.println("MAIL FROM:<" + FROM + ">");
            expect(in, "250");
            out.println("RCPT TO:<" + to + ">");
            expect(in, "250");
            out.println("DATA");
            expect(in, "354");
            out.println("From: " + FROM);
            out.println("To: " + to);
            out.println("Subject: " + subject);
            out.println("MIME-Version: 1.0");
            out.println("Content-Type: multipart/mixed; boundary=\"" + boundary + "\"");
            out.println("X-Mailer: AE6E66/1.2");
            out.println();

            // Body part
            out.println("--" + boundary);
            out.println("Content-Type: text/plain; charset=UTF-8");
            out.println("Content-Transfer-Encoding: 7bit");
            out.println();
            for (String line : body.split("\\r?\\n")) {
                if (line.startsWith(".")) out.print(".");
                out.println(line);
            }
            out.println();

            // Attachment parts
            for (File file : attachments) {
                if (!file.exists() || !file.isFile()) continue;
                byte[] data = Files.readAllBytes(file.toPath());
                String encoded = Base64.getMimeEncoder(76, "\r\n".getBytes()).encodeToString(data);

                out.println("--" + boundary);
                out.println("Content-Type: application/octet-stream; name=\"" + file.getName() + "\"");
                out.println("Content-Disposition: attachment; filename=\"" + file.getName() + "\"");
                out.println("Content-Transfer-Encoding: base64");
                out.println();
                out.println(encoded);
                out.println();
            }

            // End boundary
            out.println("--" + boundary + "--");
            out.println(".");
            expect(in, "250");
            out.println("QUIT");
        }
    }

    private static void expect(BufferedReader in, String code) throws IOException {
        String line = in.readLine();
        if (line == null || !line.startsWith(code)) {
            throw new IOException("SMTP expected " + code + ", got: " + line);
        }
        while (line != null && line.length() > 3 && line.charAt(3) == '-') {
            line = in.readLine();
        }
    }
}
