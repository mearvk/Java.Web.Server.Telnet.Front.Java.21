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
 * AE6E66 — House of Lords Contact Module
 *
 * Scrapes HOL member portraits, contact emails, and distributes messages.
 * Messages are drafted in /marrister, SHA-256 hashed, and archived in /sent/{date}/.
 *
 * Print: CommonRails — Emerald Green designates Royals.
 * Requires: Postfix/Dovecot for outbound SMTP.
 */
public class AE6E66Main {

    private static final String MEMBERS_URL = "https://members.parliament.uk/members/Lords";
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
        print(". AE6E66™ House of Lords Contact Module starting .");

        Files.createDirectories(PORTRAITS_DIR);
        Files.createDirectories(MARRISTER_DIR);
        Files.createDirectories(SENT_DIR);

        // 1. Gather member IDs from HOL listing
        List<Integer> memberIds = scrapeMemberIds();
        print(". Found " + memberIds.size() + " HOL member IDs .");

        // 2. Scrape contacts and portraits in parallel
        List<Future<MemberRecord>> futures = new ArrayList<>();
        for (int id : memberIds) {
            futures.add(pool.submit(() -> processMember(id)));
        }

        List<MemberRecord> records = new ArrayList<>();
        for (var f : futures) {
            try {
                MemberRecord r = f.get(30, TimeUnit.SECONDS);
                if (r != null) records.add(r);
            } catch (Exception e) { /* skip failed */ }
        }

        // 3. Write contacts.csv
        writeContactsCsv(records);
        print(". Wrote " + records.size() + " records to contacts.csv .");

        // 4. Distribute any message in /marrister
        distributeMessages(records);

        pool.shutdown();
        print(". AE6E66™ Complete .");
    }

    private List<Integer> scrapeMemberIds() throws Exception {
        HttpRequest req = HttpRequest.newBuilder().uri(URI.create(MEMBERS_URL)).GET().build();
        String body = http.send(req, HttpResponse.BodyHandlers.ofString()).body();

        Set<Integer> ids = new LinkedHashSet<>();
        Matcher m = Pattern.compile("/member/(\\d+)/").matcher(body);
        while (m.find()) ids.add(Integer.parseInt(m.group(1)));
        return new ArrayList<>(ids);
    }

    private MemberRecord processMember(int id) throws Exception {
        MemberRecord record = new MemberRecord();
        record.id = id;

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
            w.write("id,name,email,phone,ministry,gender,age");
            w.newLine();
            for (MemberRecord r : records) {
                w.write(String.join(",",
                        String.valueOf(r.id), csvEscape(r.name), csvEscape(r.email),
                        csvEscape(r.phone), csvEscape(r.ministry), csvEscape(r.gender), csvEscape(r.age)));
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
            EmailDistributor.distribute(emails, "House of Lords Communication", content);
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
        String name, email, phone, ministry, gender, age;
    }
}
