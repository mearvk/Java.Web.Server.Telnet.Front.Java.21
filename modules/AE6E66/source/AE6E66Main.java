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

    private static final String HOL_MEMBERS_URL = "https://members.parliament.uk/members/Lords";
    private static final String HOC_MEMBERS_URL = "https://members.parliament.uk/members/Commons";
    private static final String HOC_ENQUIRIES_URL = "https://www.parliament.uk/mps-lords-and-offices/offices/commons/house-of-commons-enquiries-service/contact-us/";
    private static final String PORTRAIT_TEMPLATE = "https://members.parliament.uk/member/%d/portrait";
    private static final String CONTACT_TEMPLATE = "https://members.parliament.uk/member/%d/contact";

    private static final Path BASE = Path.of("modules/AE6E66");
    private static final Path PORTRAITS_DIR = BASE.resolve("portraits");
    private static final Path MARRISTER_DIR = BASE.resolve("marrister");
    private static final Path SENT_DIR = BASE.resolve("sent");
    private static final Path CONTACTS_CSV = BASE.resolve("contacts.csv");

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

        Files.createDirectories(PORTRAITS_DIR);
        Files.createDirectories(MARRISTER_DIR);
        Files.createDirectories(SENT_DIR);

        List<MemberRecord> allRecords = new ArrayList<>();

        // 1. Crawl House of Lords
        List<Integer> holIds = scrapeMemberIds(HOL_MEMBERS_URL);
        print(". Found " + holIds.size() + " HOL member IDs .");
        allRecords.addAll(crawlMembers(holIds, "HOL"));

        // 2. Crawl House of Commons
        List<Integer> hocIds = scrapeMemberIds(HOC_MEMBERS_URL);
        print(". Found " + hocIds.size() + " HOC member IDs .");
        allRecords.addAll(crawlMembers(hocIds, "HOC"));

        // 3. Crawl HOC Enquiries Service page for general contact info
        allRecords.addAll(scrapeHocEnquiries());

        // 4. Write contacts.csv
        writeContactsCsv(allRecords);
        print(". Wrote " + allRecords.size() + " records to contacts.csv .");

        // 5. Distribute any message in /marrister
        distributeMessages(allRecords);

        pool.shutdown();
        print(". AE6E66™ Complete .");
    }

    private List<Integer> scrapeMemberIds(String url) throws Exception {
        HttpRequest req = HttpRequest.newBuilder().uri(URI.create(url)).GET().build();
        String body = http.send(req, HttpResponse.BodyHandlers.ofString()).body();

        Set<Integer> ids = new LinkedHashSet<>();
        Matcher m = Pattern.compile("/member/(\\d+)/").matcher(body);
        while (m.find()) ids.add(Integer.parseInt(m.group(1)));
        return new ArrayList<>(ids);
    }

    private List<MemberRecord> crawlMembers(List<Integer> ids, String source) {
        List<Future<MemberRecord>> futures = new ArrayList<>();
        for (int id : ids) {
            futures.add(pool.submit(() -> processMember(id, source)));
        }

        List<MemberRecord> records = new ArrayList<>();
        for (var f : futures) {
            try {
                MemberRecord r = f.get(30, TimeUnit.SECONDS);
                if (r != null) records.add(r);
            } catch (Exception e) { /* skip failed */ }
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
        String contactPage = http.send(contactReq, HttpResponse.BodyHandlers.ofString()).body();

        record.name = extractPattern(contactPage, "<h1[^>]*>([^<]+)</h1>");
        record.email = extractPattern(contactPage, "[\\w.+-]+@[\\w.-]+\\.[a-zA-Z]{2,}");
        record.phone = extractPattern(contactPage, "(\\+44[\\s\\d()-]{8,}|020[\\s\\d()-]{8,})");
        record.ministry = extractPattern(contactPage, "(?:Ministry|Party|Affiliation)[^<]*<[^>]*>([^<]+)");

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
        try (BufferedWriter w = Files.newBufferedWriter(CONTACTS_CSV)) {
            w.write("id,name,email,phone,ministry,gender,age,source");
            w.newLine();
            for (MemberRecord r : records) {
                w.write(String.join(",",
                        String.valueOf(r.id), csvEscape(r.name), csvEscape(r.email),
                        csvEscape(r.phone), csvEscape(r.ministry), csvEscape(r.gender),
                        csvEscape(r.age), csvEscape(r.source)));
                w.newLine();
            }
        }
    }

    private void distributeMessages(List<MemberRecord> records) throws Exception {
        File[] drafts = MARRISTER_DIR.toFile().listFiles((d, n) -> n.endsWith(".txt"));
        if (drafts == null || drafts.length == 0) {
            print(". No messages in marrister/ .");
            return;
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
            EmailDistributor.distribute(emails, "Parliamentary Communication", content);
            print(". Sent '" + draft.getName() + "' SHA-256:" + hash.substring(0, 12) + "… to " + emails.size() + " recipients .");
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
        String name, email, phone, ministry, gender, age, source;
    }
}
