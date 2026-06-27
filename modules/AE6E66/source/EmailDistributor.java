package source;

import java.io.*;
import java.util.*;

/**
 * EmailDistributor — Sends emails via local Postfix SMTP (port 25).
 *
 * REQUIREMENT: Postfix and Dovecot must be installed and running on the host.
 *
 * Install on Ubuntu/Debian:
 *   sudo apt install postfix dovecot-core dovecot-imapd
 *   sudo systemctl enable postfix dovecot
 *   sudo systemctl start postfix dovecot
 *
 * Configure /etc/postfix/main.cf with your domain (mearvk.us or similar).
 */
public class EmailDistributor {

    private static final String SMTP_HOST = "localhost";
    private static final int SMTP_PORT = 25;
    private static final String FROM = "contact@lauradei.us";

    /** Distribute a message to all recipients via local Postfix SMTP */
    public static void distribute(List<String> recipients, String subject, String body) {
        for (String to : recipients) {
            try {
                sendMail(to, subject, body);
            } catch (Exception e) {
                System.err.println("-- : [AE6E66] Failed to send to " + to + ": " + e.getMessage());
            }
        }
    }

    /** Raw SMTP conversation with local Postfix */
    private static void sendMail(String to, String subject, String body) throws Exception {
        try (var sock = new java.net.Socket(SMTP_HOST, SMTP_PORT);
             var in = new BufferedReader(new InputStreamReader(sock.getInputStream()));
             var out = new PrintWriter(sock.getOutputStream(), true)) {

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
            out.println();
            out.println(body);
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
        // Consume multi-line responses (250-...)
        while (line != null && line.length() > 3 && line.charAt(3) == '-') {
            line = in.readLine();
        }
    }
}
