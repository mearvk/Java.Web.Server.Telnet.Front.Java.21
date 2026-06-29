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
 *   - Header injection prevention
 *   - Rate-limited at Postfix level (2s/destination)
 *
 * REQUIREMENT: Postfix must be installed and running on localhost.
 */
public class EmailDistributor {

    private static final String SMTP_HOST = "localhost";
    private static final int SMTP_PORT = 25;
    private static final String FROM = "contact@lauradei.us";
    private static final String DOMAIN = "lauradei.us";
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$");

    /** Send a single email — throws on failure. */
    public static void sendOne(String to, String subject, String body, List<File> attachments) throws Exception {
        sendOneWithConfirmation(to, subject, body, attachments);
    }

    /**
     * Send a single email and return the SMTP 250 confirmation (queue ID).
     */
    public static String sendOneWithConfirmation(String to, String subject, String body, List<File> attachments) throws Exception {
        if (!isValidEmail(to)) throw new IllegalArgumentException("Invalid recipient: " + to);
        subject = sanitizeHeader(subject);

        boolean hasAttachments = attachments != null && !attachments.isEmpty();
        String boundary = hasAttachments ? "----=_AE6E66_" + System.currentTimeMillis() : null;

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

            // Headers
            out.println("From: " + FROM);
            out.println("To: " + to);
            out.println("Subject: " + subject);
            out.println("MIME-Version: 1.0");
            if (hasAttachments) {
                out.println("Content-Type: multipart/mixed; boundary=\"" + boundary + "\"");
            } else {
                out.println("Content-Type: text/plain; charset=UTF-8");
            }
            writeDeliverabilityHeaders(out);
            out.println();

            // Body
            if (hasAttachments) {
                out.println("--" + boundary);
                out.println("Content-Type: text/plain; charset=UTF-8");
                out.println("Content-Transfer-Encoding: 7bit");
                out.println();
            }
            for (String line : body.split("\\r?\\n")) {
                if (line.startsWith(".")) out.print(".");
                out.println(line);
            }
            if (hasAttachments) {
                out.println();
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
                out.println("--" + boundary + "--");
            }

            out.println(".");
            String confirmation = expect(in, "250");
            out.println("QUIT");
            return confirmation;
        }
    }

    private static boolean isValidEmail(String email) {
        return email != null && email.length() <= 254 && EMAIL_PATTERN.matcher(email).matches();
    }

    private static String sanitizeHeader(String value) {
        if (value == null) return "";
        return value.replaceAll("[\\r\\n]", "").trim();
    }

    private static void writeDeliverabilityHeaders(PrintWriter out) {
        out.println("Message-ID: <" + UUID.randomUUID() + "@" + DOMAIN + ">");
        out.println("Date: " + java.time.ZonedDateTime.now(java.time.ZoneOffset.UTC)
                .format(java.time.format.DateTimeFormatter.RFC_1123_DATE_TIME));
        out.println("List-Unsubscribe: <mailto:unsubscribe@" + DOMAIN + "?subject=unsubscribe>");
        out.println("List-Unsubscribe-Post: List-Unsubscribe=One-Click");
        out.println("X-Mailer: AE6E66/1.3");
    }

    private static String expect(BufferedReader in, String code) throws IOException {
        String line = in.readLine();
        if (line == null || !line.startsWith(code)) {
            throw new IOException("SMTP expected " + code + ", got: " + line);
        }
        StringBuilder full = new StringBuilder(line);
        while (line != null && line.length() > 3 && line.charAt(3) == '-') {
            line = in.readLine();
            full.append("\n").append(line);
        }
        return full.toString();
    }
}
