package source;

import commons.CommonRails;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.net.http.*;
import java.nio.file.*;
import java.security.*;
import java.time.*;
import java.time.format.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.*;

/**
 * AE6E66 — House of Lords + House of Commons Contact Module
 *
 * Crawls:
 *   HOL: https://members.parliament.uk/members/Lords -> /member/XXX/contact
 *   HOC: https://members.parliament.uk/members/Commons -> /member/XXX/contact
 *        + https://www.parliament.uk/mps-lords-and-offices/offices/commons/house-of-commons-enquiries-service/contact-us/
 *
 * Print: CommonRails — Emerald Green designates Royals.
 * Requires: Postfix/Dovecot for outbound SMTP.
 */
public class AE6E66Main {

    private static final String HOC_ENQUIRIES_URL = "https://www.parliament.uk/mps-lords-and-offices/offices/commons/house-of-commons-enquiries-service/contact-us/";
    private static final String PORTRAIT_TEMPLATE = "https://members.parliament.uk/member/%d/portrait";
    private static final String CONTACT_TEMPLATE = "https://members.parliament.uk/member/%d/contact";
    private static final String CAREER_TEMPLATE = "https://members.parliament.uk/member/%d/career";

    private static final Path BASE = Path.of("modules/AE6E66");
    private static final Path PORTRAITS_DIR = BASE.resolve("portraits");
    private static final Path MARRISTER_DIR = BASE.resolve("marrister");
    private static final Path SENT_DIR = BASE.resolve("sent");
    private static final Path CONTACTS_CSV = BASE.resolve("contacts.csv");
    private static final Path PERSONAL_DIR = BASE.resolve("personal");

    private static final Path ATTACHMENTS_DIR = BASE.resolve("attachments");

    private static final Path LAST_CRAWL_FILE = BASE.resolve("configuration/.last-crawl");

    /** Emerald Green — designates Royals; to few; to pay outs; to ruins */
    private static final String EMERALD = ColorPalette.COLOR_EMERALD_GREEN;

    private final HttpClient http = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(15))
            .build();

    private final ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor();

    public static void main(String[] args) throws Exception {
        new AE6E66Main().run();
    }

    private void print(String msg) {
        CommonRails.printSystemComponent(this, this.hashCode(), msg, EMERALD);
    }

    public void run() throws Exception {
        print(". AE6E66™ House of Lords + Commons Contact Module starting .");

        // Check Postfix is running
        if (isPostfixRunning()) {
            print(". Postfix SMTP is ACTIVE on localhost:25 .");
        } else {
            print(". WARNING: Postfix SMTP is NOT running — emails will fail .");
        }

        Files.createDirectories(PORTRAITS_DIR);
        Files.createDirectories(MARRISTER_DIR);
        Files.createDirectories(SENT_DIR);
        Files.createDirectories(PERSONAL_DIR);
        Files.createDirectories(ATTACHMENTS_DIR);

        List<MemberRecord> allRecords = new ArrayList<>();

        // Check if we already crawled recently — skip unless new election season
        if (shouldSkipCrawl()) {
            print(". MPUK already scanned this session — skipping crawl .");
            print(". Re-crawl on new election season (Lords/Commons) or delete .last-crawl .");
            // Load existing CSV for distribution
            allRecords = loadContactsCsv();
        } else {
            // 1. Crawl all member IDs 0–999 (covers both HOL and HOC)
            print(". Crawling member IDs 0–999 on members.parliament.uk .");
            allRecords.addAll(crawlAllMembers("Parliament"));

            // 2. Crawl HOC Enquiries Service page for general contact info
            allRecords.addAll(scrapeHocEnquiries());

            // 3. Write contacts.csv
            writeContactsCsv(allRecords);
            print(". Wrote " + allRecords.size() + " records to contacts.csv .");

            // 4. Write Outlook-importable CSV for Lords/Ministers to /personal
            writePersonalOutlookCsv(allRecords);

            // Mark crawl complete
            markCrawlDone();
        }

        // 6. Distribute any message in /marrister
        distributeMessages(allRecords);

        pool.shutdown();
        print(". AE6E66™ Complete .");
    }

    /** Check if Postfix SMTP is reachable on localhost:25 */
    private boolean isPostfixRunning() {
        try (var sock = new Socket()) {
            sock.connect(new InetSocketAddress("localhost", 25), 2000);
            return true;
        } catch (Exception e) { return false; }
    }

    /** Reload contacts from existing CSV when crawl is skipped */
    private List<MemberRecord> loadContactsCsv() {
        List<MemberRecord> records = new ArrayList<>();
        try {
            if (!Files.exists(CONTACTS_CSV)) return records;
            for (String line : Files.readAllLines(CONTACTS_CSV)) {
                if (line.startsWith("#") || line.startsWith("id,") || line.isBlank()) continue;
                String[] parts = line.split(",", -1);
                if (parts.length < 3) continue;
                MemberRecord r = new MemberRecord();
                r.id = Integer.parseInt(parts[0].trim());
                r.name = parts[1].replace("\"", "");
                r.email = parts.length > 2 ? parts[2].replace("\"", "").trim() : null;
                if (r.email != null && r.email.isEmpty()) r.email = null;
                records.add(r);
            }
        } catch (Exception e) { /* fall through with what we have */ }
        return records;
    }

    /** Check if MPUK was already crawled this parliament session */
    private boolean shouldSkipCrawl() {
        try {
            if (!Files.exists(LAST_CRAWL_FILE)) return false;
            String stamp = Files.readString(LAST_CRAWL_FILE).trim();
            LocalDate lastCrawl = LocalDate.parse(stamp);
            // Skip if crawled within the last 30 days (no new election season)
            return LocalDate.now().minusDays(30).isBefore(lastCrawl);
        } catch (Exception e) { return false; }
    }

    /** Record that we just completed a crawl */
    private void markCrawlDone() throws IOException {
        Files.writeString(LAST_CRAWL_FILE, LocalDate.now().toString());
    }

    /** Brute-force crawl member IDs 0–999, hitting /member/XXX/contact directly */
    private List<MemberRecord> crawlAllMembers(String source) {
        List<Future<MemberRecord>> futures = new ArrayList<>();
        for (int id = 0; id <= 999; id++) {
            final int mid = id;
            futures.add(pool.submit(() -> processMember(mid, source)));
        }

        List<MemberRecord> records = new ArrayList<>();
        for (var f : futures) {
            try {
                MemberRecord r = f.get(30, TimeUnit.SECONDS);
                if (r != null) records.add(r);
            } catch (Exception e) { /* skip — page doesn't exist or timed out */ }
        }
        return records;
    }

    /** Scrape HOC Enquiries Service contact page for emails/phone */
    private List<MemberRecord> scrapeHocEnquiries() throws Exception {
        HttpRequest req = HttpRequest.newBuilder().uri(URI.create(HOC_ENQUIRIES_URL)).GET().build();
        String page = http.send(req, HttpResponse.BodyHandlers.ofString()).body();

        List<MemberRecord> records = new ArrayList<>();

        // Extract all emails from the enquiries page
        Matcher emailMatcher = Pattern.compile("[\\w.+-]+@parliament\\.uk").matcher(page);
        Set<String> emails = new LinkedHashSet<>();
        while (emailMatcher.find()) emails.add(emailMatcher.group());

        // Extract phone numbers
        Matcher phoneMatcher = Pattern.compile("(\\+44[\\s\\d()-]{8,}|020[\\s\\d()-]{8,})").matcher(page);
        String phone = phoneMatcher.find() ? phoneMatcher.group().trim() : null;

        for (String email : emails) {
            MemberRecord r = new MemberRecord();
            r.id = 0;
            r.name = "HOC Enquiries Service";
            r.email = email;
            r.phone = phone;
            r.ministry = "House of Commons";
            r.source = "HOC-Enquiries";
            records.add(r);
        }

        if (!records.isEmpty()) {
            print(". Scraped " + records.size() + " contacts from HOC Enquiries Service .");
        }
        return records;
    }

    private MemberRecord processMember(int id, String source) throws Exception {
        MemberRecord record = new MemberRecord();
        record.id = id;
        record.source = source;

        HttpRequest contactReq = HttpRequest.newBuilder()
                .uri(URI.create(String.format(CONTACT_TEMPLATE, id))).GET().build();
        HttpResponse<String> resp = http.send(contactReq, HttpResponse.BodyHandlers.ofString());
        if (resp.statusCode() != 200) return null;
        String contactPage = resp.body();

        record.name = extractPattern(contactPage, "<h1[^>]*>([^<]+)</h1>");
        if (record.name == null) return null;

        record.email = extractPattern(contactPage, "[\\w.+-]+@[\\w.-]+\\.[a-zA-Z]{2,}");
        record.phone = extractPattern(contactPage, "(\\+44[\\s\\d()-]{8,}|020[\\s\\d()-]{8,})");
        record.ministry = extractPattern(contactPage, "(?:Ministry|Party|Affiliation)[^<]*<[^>]*>([^<]+)");

        // Detect HOL vs HOC from page content
        if (contactPage.contains("Lords") || contactPage.contains("Baron") || contactPage.contains("Viscount") || contactPage.contains("Duchess")) {
            record.source = "HOL";
        } else {
            record.source = "HOC";
        }

        // Scrape /career page if it exists
        HttpRequest careerReq = HttpRequest.newBuilder()
                .uri(URI.create(String.format(CAREER_TEMPLATE, id))).GET().build();
        HttpResponse<String> careerResp = http.send(careerReq, HttpResponse.BodyHandlers.ofString());
        if (careerResp.statusCode() == 200) {
            record.career = extractPattern(careerResp.body(), "<div[^>]*class=\"[^\"]*career[^\"]*\"[^>]*>([\\s\\S]*?)</div>");
            if (record.career != null) record.career = record.career.replaceAll("<[^>]+>", " ").replaceAll("\\s+", " ").trim();
        }

        // Portrait into ministry subfolder
        String ministry = record.ministry != null ? record.ministry.replaceAll("[^a-zA-Z0-9 ]", "").trim() : "Unknown";
        Path ministryDir = PORTRAITS_DIR.resolve(ministry);
        Files.createDirectories(ministryDir);

        HttpRequest portraitReq = HttpRequest.newBuilder()
                .uri(URI.create(String.format(PORTRAIT_TEMPLATE, id))).GET().build();
        HttpResponse<byte[]> portraitResp = http.send(portraitReq, HttpResponse.BodyHandlers.ofByteArray());
        if (portraitResp.statusCode() == 200) {
            Files.write(ministryDir.resolve(id + ".jpg"), portraitResp.body());
        }

        return record;
    }

    private void writeContactsCsv(List<MemberRecord> records) throws IOException {
        String year = String.valueOf(Year.now().getValue());

        // Separate HOL and HOC
        List<MemberRecord> holRecords = records.stream().filter(r -> "HOL".equals(r.source)).toList();
        List<MemberRecord> hocRecords = records.stream().filter(r -> !"HOL".equals(r.source)).toList();

        try (BufferedWriter w = Files.newBufferedWriter(CONTACTS_CSV)) {
            // HOL Section
            w.write("# House of Lords - Year of Our Lord - " + year);
            w.newLine();
            w.write("id,name,email,phone,ministry,gender,age,source,career");
            w.newLine();
            for (MemberRecord r : holRecords) {
                writeMemberLine(w, r);
            }

            w.newLine();

            // HOC Section
            w.write("# House of Commons - Year of Our Lord - " + year);
            w.newLine();
            w.write("id,name,email,phone,ministry,gender,age,source,career");
            w.newLine();
            for (MemberRecord r : hocRecords) {
                writeMemberLine(w, r);
            }
        }
    }

    private void writeMemberLine(BufferedWriter w, MemberRecord r) throws IOException {
        w.write(String.join(",",
                String.valueOf(r.id), csvEscape(r.name), csvEscape(r.email),
                csvEscape(r.phone), csvEscape(r.ministry), csvEscape(r.gender),
                csvEscape(r.age), csvEscape(r.source), csvEscape(r.career)));
        w.newLine();
    }

    /** Outlook/Exchange-compatible CSV for Lords and Ministers only — /personal */
    private void writePersonalOutlookCsv(List<MemberRecord> records) throws IOException {
        List<MemberRecord> lords = records.stream()
                .filter(r -> "HOL".equals(r.source) && r.email != null)
                .toList();

        Path outlookCsv = PERSONAL_DIR.resolve("lords-ministers-outlook.csv");
        try (BufferedWriter w = Files.newBufferedWriter(outlookCsv)) {
            // Outlook CSV import header format
            w.write("First Name,Last Name,E-mail Address,Business Phone,Company,Job Title,Categories");
            w.newLine();
            for (MemberRecord r : lords) {
                String[] nameParts = splitName(r.name);
                w.write(String.join(",",
                        csvEscape(nameParts[0]),
                        csvEscape(nameParts[1]),
                        csvEscape(r.email),
                        csvEscape(r.phone),
                        csvEscape(r.ministry),
                        csvEscape("Lord/Minister"),
                        csvEscape("House of Lords")));
                w.newLine();
            }
        }
        print(". Wrote " + lords.size() + " Lords/Ministers to personal/lords-ministers-outlook.csv .");
    }

    private static String[] splitName(String name) {
        if (name == null) return new String[]{"", ""};
        int sp = name.indexOf(' ');
        if (sp < 0) return new String[]{name, ""};
        return new String[]{name.substring(0, sp), name.substring(sp + 1)};
    }

    private void distributeMessages(List<MemberRecord> records) throws Exception {
        File[] drafts = MARRISTER_DIR.toFile().listFiles((d, n) -> n.endsWith(".txt"));
        if (drafts == null || drafts.length == 0) {
            print(". No messages in marrister/ .");
            return;
        }

        // Collect all attachment files from /attachments
        File[] attachmentFiles = ATTACHMENTS_DIR.toFile().listFiles(File::isFile);
        List<File> attachments = (attachmentFiles != null) ? Arrays.asList(attachmentFiles) : Collections.emptyList();
        if (!attachments.isEmpty()) {
            print(". " + attachments.size() + " attachment(s) from attachments/ will be included .");
        }

        for (File draft : drafts) {
            String content = Files.readString(draft.toPath());
            String hash = sha256(content);

            String date = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
            Path dateDir = SENT_DIR.resolve(date);
            Files.createDirectories(dateDir);
            Files.copy(draft.toPath(), dateDir.resolve(draft.getName()), StandardCopyOption.REPLACE_EXISTING);
            Files.writeString(dateDir.resolve(draft.getName() + ".sha256"), hash);

            List<String> emails = records.stream().map(r -> r.email).filter(Objects::nonNull).toList();

            int success = 0, failure = 0;
            StringBuilder confirmations = new StringBuilder();
            StringBuilder failures = new StringBuilder();
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

            for (String email : emails) {
                try {
                    String confirmation = EmailDistributor.sendOneWithConfirmation(email, "Parliamentary Communication", content, attachments);
                    confirmations.append("[").append(timestamp).append("] ").append(email).append(" -> ").append(confirmation).append("\n");
                    print(". " + email + " -> " + confirmation + " .");
                    success++;
                } catch (Exception e) {
                    failures.append("[").append(timestamp).append("] ").append(email).append(" -> ").append(e.getClass().getSimpleName()).append(": ").append(e.getMessage()).append("\n");
                    failure++;
                }
            }

            // Write delivery confirmations log (SMTP 250 responses with queue IDs)
            Files.writeString(dateDir.resolve(draft.getName() + ".confirmations.log"),
                    "# Delivery Confirmations — " + draft.getName() + "\n# " + timestamp + "\n# Confirmed: " + success + "/" + (success + failure) + "\n\n" + confirmations);

            // Write failures log (exceptions and SMTP rejections)
            Files.writeString(dateDir.resolve(draft.getName() + ".failures.log"),
                    "# Delivery Failures — " + draft.getName() + "\n# " + timestamp + "\n# Failed: " + failure + "/" + (success + failure) + "\n\n" + failures);

            print(". Sent '" + draft.getName() + "' SHA-256:" + hash.substring(0, 12) + "… success=" + success + " failure=" + failure + " attachments=" + attachments.size() + " .");

            // Notify owner if nothing was delivered
            if (success == 0) {
                try {
                    String notice = "AE6E66™ NOTICE: 0 messages delivered for '" + draft.getName() + "' at " + timestamp + ".\nFailures:\n" + failures;
                    EmailDistributor.sendOne("mearvk@outlook.com", "AE6E66 — No Deliveries", notice, Collections.emptyList());
                    print(". Owner notified at mearvk@outlook.com — 0 deliveries .");
                } catch (Exception notifyEx) {
                    print(". WARN: Could not notify owner — " + notifyEx.getMessage() + " .");
                }
            }
        }
    }

    private static String sha256(String input) throws NoSuchAlgorithmException {
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(input.getBytes());
        StringBuilder sb = new StringBuilder();
        for (byte b : digest) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private static String extractPattern(String html, String regex) {
        Matcher m = Pattern.compile(regex).matcher(html);
        return m.find() ? m.group(m.groupCount() > 0 ? 1 : 0).trim() : null;
    }

    private static String csvEscape(String val) {
        if (val == null) return "";
        if (val.contains(",") || val.contains("\"")) return "\"" + val.replace("\"", "\"\"") + "\"";
        return val;
    }

    static class MemberRecord {
        int id;
        String name, email, phone, ministry, gender, age, source, career;
    }
}
