package modules.Defined.source.ai.server;

import modules.Defined.source.ai.module.DefinedMoralSpeculator;
import modules.Defined.source.ai.module.NTSBCommunicator;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.sql.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * DefinedAIServer — Dark Gray themed AI surveillance and moral assessment server.
 * Port 49220. Definition to narrow cause: defined.
 *
 * Lists obvious traitors to empire or mode of empire that create and co-exist
 * with Licentious brand. Supposing that banks and so on did not create Cause
 * but follow; and they follow a unique brand of ampathy (ampere style leading
 * apathy) that allows others to get away with bloody Murder if undetected and
 * not found by Brand (college and business theory actually).
 *
 * The custom work is kinded and secondary (also implied as good).
 *
 * AI accesses internet via port 80, checks for licentious connections based on
 * known moral shortcomings. Runs 4 times a day.
 *
 * Known trespass against final medical review may result in being discharged
 * from Earth forever.
 *
 * Safety classification: careful and possible government secret.
 *
 * Installer Tech ID: Max Rupplin — honest state fiduciary and forward US Democrat.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class DefinedAIServer extends Thread
{
    private static final int PORT = 49220;
    private static final int MAX_CONNECTIONS = 5040;
    private static final int MAX_PER_IP = 1;
    private static final int TIMEOUT_MS = 58 * 60 * 1000;
    private static final int BACKLOG = 128;
    private static final String INSTALLER_TECH_ID = "Max Rupplin — honest state fiduciary and forward US Democrat";
    private static final String THEME = "Dark Gray";
    private static final String DEFINITION = "Definition to narrow cause: defined";

    private static final String BANNER =
        "\n" +
        "╔═══════════════════════════════════════════════════════════════════════════╗\n" +
        "║  DEFINED™ — Dark Gray Module                                             ║\n" +
        "║  Definition to narrow cause: defined.                                    ║\n" +
        "║                                                                          ║\n" +
        "║  NOTICE: Known trespass against final medical review may result in       ║\n" +
        "║  being discharged from Earth forever.                                    ║\n" +
        "║                                                                          ║\n" +
        "║  Kinded and Secondary (implied as good).                                 ║\n" +
        "║  Installer Tech ID: Max Rupplin                                         ║\n" +
        "║  Safety: Careful and possible government secret.                         ║\n" +
        "╚═══════════════════════════════════════════════════════════════════════════╝\n";

    // Assessment categories for page links
    private static final String[] CATEGORIES = {
        "banking",
        "middle-schools",
        "strong-middle-schools",
        "improbable-activity-youth",
        "firefights-20-plus-casualties",
        "fire-department-errors-3-plus",
        "schools-burned-down",
        "misuse-of-scientology",
        "known-misuse-public-officials",
        "unkind-language-books-reading",
        "unkind-misuse-heads-of-state",
        "absence-fbi-presence",
        "absence-border-protection",
        "unequal-treatment-us-treasury",
        "unequal-footing-us-state-department",
        "private-ownership-lsat",
        "torturers",
        "rapists",
        "convicted-murderers",
        "gods-going-crazy",
        "anti-god-rhetoric",
        "against-space-nasa",
        "anti-political-whisper",
        "sovietism-vs-socialism",
        "failing-schools",
        "failing-final-tests",
        "non-social-graces",
        "prayer-against-even-temper",
        "ntsb"
    };

    // Report priority weights
    private static final int[] WEEKLY_PRIORITY = {8, 8, 8, 1, 1};
    private static final int[] MONTHLY_PRIORITY = {40, 32, 1, 8, 1};
    private static final int[] QUARTERLY_PRIORITY = {12, 1, 2, 6, 8, 1, 10};
    private static final int[] HALFYEAR_PRIORITY = {5, 5, 2, 1, 5};
    private static final int[] ANNUAL_PRIORITY = {6, 2, 1, 2, 1, 6};

    private ServerSocket serverSocket;
    private volatile boolean running = true;
    private final AtomicInteger activeConnections = new AtomicInteger(0);
    private final ConcurrentHashMap<String, AtomicInteger> ipCount = new ConcurrentHashMap<>();
    private final ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(4);

    private DefinedMoralSpeculator speculator;
    private NTSBCommunicator ntsbCommunicator;
    private Connection dbConnection;

    // Daily assessments: 1,2,3,4,final
    private final Map<Integer, String> dailyAssessments = new ConcurrentHashMap<>();

    // Moral disposition weights (Asia-first)
    // Order: Asia(1st), Asia(2nd), United States, Soviet Russia
    private float[] moralWeights;

    // Uptime tracking
    private long startTimeMs;

    public static void main(String[] args) throws Exception
    {
        DefinedAIServer server = new DefinedAIServer();
        server.initialize();
        server.start();
        Runtime.getRuntime().addShutdownHook(new Thread(server::shutdown));
    }

    /**
     * Full initialization: load training, connect DB, schedule scans.
     */
    public void initialize() throws Exception
    {
        startTimeMs = System.currentTimeMillis();
        System.out.println("[DefinedAIServer] Initializing — Theme: " + THEME);
        System.out.println("[DefinedAIServer] " + DEFINITION);
        System.out.println("[DefinedAIServer] Installer Tech ID: " + INSTALLER_TECH_ID);
        System.out.println("[DefinedAIServer] Safety: Careful and possible government secret.");

        // Initialize AI module
        speculator = new DefinedMoralSpeculator();
        ntsbCommunicator = new NTSBCommunicator();

        // Connect to MySQL
        connectDatabase();

        // Load training strips (3 tiers) — these pre-inform the AI
        loadTrainingStrips();

        // Pre-establish moral disposition: Asia first as best-first friend
        establishMoralDisposition();

        // Schedule 4 daily internet scans (every 6 hours)
        scheduleInternetScans();

        // Schedule daily weight save at noon EST
        scheduleDailyWeightSave();

        // Schedule report generation
        scheduleReports();

        System.out.println("[DefinedAIServer] Initialization complete. Ready for connections.");
    }

    private void connectDatabase() throws Exception
    {
        String url = "jdbc:mysql://localhost:3306/defined_dark_gray?useSSL=false&serverTimezone=America/New_York";
        String user = "nwe";
        String pass = "nwe";
        dbConnection = DriverManager.getConnection(url, user, pass);
        System.out.println("[DefinedAIServer] MySQL connected: defined_dark_gray");
    }

    /**
     * Load training strips in order:
     * 1. Basic modification of series
     * 2. Basic modification of angular momentum of series
     * 3. Basic intent of adverb set for series (who is owner of precept and concept
     *    and who is in charge of Law)
     *
     * These pre-inform the AI module to perceive that units are demonstrable and cause.
     * The AI considers all parts but shaves the latter (lower 50%) as probably freed
     * by lesser congruity.
     *
     * Then: basic moral apprehension, weighing of decisions, improvements by angles,
     * improvements by velocities.
     *
     * Finally: conduct and future awareness. Trained as 1,2,3.
     */
    private void loadTrainingStrips() throws Exception
    {
        System.out.println("[DefinedAIServer] Loading training strips (3 tiers)...");

        Path stripDir = Paths.get("training/strips");

        // Tier 1: Basic modification of series
        speculator.loadStrip(stripDir.resolve("tier1-series-modification.json"), 1);

        // Tier 2: Basic modification of angular momentum of series
        speculator.loadStrip(stripDir.resolve("tier2-angular-momentum.json"), 2);

        // Tier 3: Basic intent of adverb set (owner of precept/concept, Law authority)
        speculator.loadStrip(stripDir.resolve("tier3-adverb-intent-law.json"), 3);

        // Shave lower 50% as freed by lesser congruity
        speculator.shaveLowerCongruity(0.50f);

        // Then: moral apprehension, weighing, angles, velocities
        speculator.loadMoralApprehension(stripDir.resolve("moral-apprehension.json"));
        speculator.loadAngleImprovements(stripDir.resolve("improvements-by-angles.json"));
        speculator.loadVelocityImprovements(stripDir.resolve("improvements-by-velocities.json"));

        // Finally: conduct and future awareness strips (trained as 1,2,3)
        speculator.loadConductAwareness(stripDir.resolve("conduct-and-future.json"));

        // Store training strips in MySQL
        storeTrainingStripRecord();

        System.out.println("[DefinedAIServer] Training strips loaded (1,2,3 order).");
    }

    private void storeTrainingStripRecord()
    {
        try
        {
            PreparedStatement ps = dbConnection.prepareStatement(
                "INSERT INTO training_strips (tier, strip_name, strip_data, loaded_ts) VALUES (?, ?, ?, NOW())"
            );
            String[] names = {"tier1-series-modification", "tier2-angular-momentum", "tier3-adverb-intent-law"};
            for (int i = 0; i < names.length; i++)
            {
                ps.setInt(1, i + 1);
                ps.setString(2, names[i]);
                ps.setString(3, "{}");
                ps.addBatch();
            }
            ps.executeBatch();
        }
        catch (SQLException e)
        {
            System.err.println("[DefinedAIServer] Training strip DB record error: " + e.getMessage());
        }
    }

    /**
     * Pre-established moral disposition towards authority.
     * Consider Asia first as best-first friend. Then Asia again.
     * Then the United States. Then Soviet Russia.
     * Save these weights and considerations on a daily basis at noon EST.
     */
    private void establishMoralDisposition()
    {
        System.out.println("[DefinedAIServer] Establishing moral disposition...");
        moralWeights = new float[]{0.0f, 0.0f, 0.0f, 0.0f};

        // Asia first — best-first friend
        moralWeights[0] = speculator.considerRegion("Asia", 1.0f);
        // Asia again
        moralWeights[1] = speculator.considerRegion("Asia", 0.95f);
        // United States
        moralWeights[2] = speculator.considerRegion("United States", 0.90f);
        // Soviet Russia
        moralWeights[3] = speculator.considerRegion("Soviet Russia", 0.85f);

        System.out.println("[DefinedAIServer] Moral disposition established:");
        System.out.println("  1. Asia (best-first friend): " + moralWeights[0]);
        System.out.println("  2. Asia (again):             " + moralWeights[1]);
        System.out.println("  3. United States:            " + moralWeights[2]);
        System.out.println("  4. Soviet Russia:            " + moralWeights[3]);
    }

    /**
     * Schedule internet scans 4 times a day evenly (00:00, 06:00, 12:00, 18:00 EST).
     * Each scan accesses target servers via port 80, checks for licentious connections.
     * Takes in new information from the internet for processing on the day.
     */
    private void scheduleInternetScans()
    {
        ZoneId est = ZoneId.of("America/New_York");
        LocalDateTime now = LocalDateTime.now(est);

        int[] scanHours = {0, 6, 12, 18};
        for (int hour : scanHours)
        {
            LocalDateTime nextRun = now.withHour(hour).withMinute(0).withSecond(0);
            if (nextRun.isBefore(now)) nextRun = nextRun.plusDays(1);
            long delayMinutes = Duration.between(now, nextRun).toMinutes();

            scheduler.scheduleAtFixedRate(
                this::performInternetScan,
                delayMinutes,
                24 * 60, // every 24 hours per slot
                TimeUnit.MINUTES
            );
        }
        System.out.println("[DefinedAIServer] Internet scans scheduled: 4x daily (00,06,12,18 EST)");
    }

    /**
     * Schedule daily weight save at noon EST in America.
     */
    private void scheduleDailyWeightSave()
    {
        ZoneId est = ZoneId.of("America/New_York");
        LocalDateTime now = LocalDateTime.now(est);
        LocalDateTime noon = now.withHour(12).withMinute(0).withSecond(0);
        if (noon.isBefore(now)) noon = noon.plusDays(1);
        long delayMinutes = Duration.between(now, noon).toMinutes();

        scheduler.scheduleAtFixedRate(
            this::saveDailyWeights,
            delayMinutes,
            24 * 60,
            TimeUnit.MINUTES
        );
        System.out.println("[DefinedAIServer] Daily weight save scheduled: noon EST");
    }

    /**
     * Schedule periodic reports:
     * - Weekly (8,8,8,1,1 priority)
     * - Monthly (40,32,1,8,1 priority)
     * - Quarterly (12,1,2,6,8,1,10 priority)
     * - Half-year (5,5,2,1,5 priority)
     * - Annual (6,2,1,2,1,6 priority)
     * - 2-year, 5-year, 10-year (accumulated)
     */
    private void scheduleReports()
    {
        // Weekly: every 7 days
        scheduler.scheduleAtFixedRate(
            () -> generateReport("weekly", WEEKLY_PRIORITY),
            7 * 24 * 60, 7 * 24 * 60, TimeUnit.MINUTES
        );
        // Monthly: every 30 days
        scheduler.scheduleAtFixedRate(
            () -> generateReport("monthly", MONTHLY_PRIORITY),
            30 * 24 * 60, 30 * 24 * 60, TimeUnit.MINUTES
        );
        // Quarterly: every 90 days
        scheduler.scheduleAtFixedRate(
            () -> generateReport("quarterly", QUARTERLY_PRIORITY),
            90 * 24 * 60, 90 * 24 * 60, TimeUnit.MINUTES
        );
        // Half-year: every 180 days
        scheduler.scheduleAtFixedRate(
            () -> generateReport("half-year", HALFYEAR_PRIORITY),
            180 * 24 * 60, 180 * 24 * 60, TimeUnit.MINUTES
        );
        // Annual: every 365 days
        scheduler.scheduleAtFixedRate(
            () -> generateReport("annual", ANNUAL_PRIORITY),
            365 * 24 * 60, 365 * 24 * 60, TimeUnit.MINUTES
        );
        // 2-year check
        scheduler.scheduleAtFixedRate(
            () -> generateReport("2-year", ANNUAL_PRIORITY),
            2 * 365 * 24 * 60, 2 * 365 * 24 * 60, TimeUnit.MINUTES
        );
        // 5-year check
        scheduler.scheduleAtFixedRate(
            () -> generateReport("5-year", ANNUAL_PRIORITY),
            5 * 365 * 24 * 60, 5 * 365 * 24 * 60, TimeUnit.MINUTES
        );
        // 10-year check
        scheduler.scheduleAtFixedRate(
            () -> generateReport("10-year", ANNUAL_PRIORITY),
            10 * 365 * 24 * 60, 10 * 365 * 24 * 60, TimeUnit.MINUTES
        );
        System.out.println("[DefinedAIServer] Report schedule: weekly/monthly/quarterly/half-year/annual/2yr/5yr/10yr");
    }

    /**
     * Perform internet scan via port 80 on any server.
     * Check for licentious connections that seem probable based on known moral shortcomings.
     * Store findings in MySQL. Consider receding tempers model (known harmonics on such greases).
     *
     * The program concerns with taking in new information from the internet for processing
     * on the day. This happens 4 times a day evenly. Keep careful facts and consideration
     * known in the database.
     *
     * The AI module should conclude by the end of the day that it has concluded about the
     * system and situation 4 times and about the 4 times that it has finally concluded
     * its final assessment by the end of the day.
     */
    private void performInternetScan()
    {
        int scanNumber = determineScanNumber();
        System.out.println("[DefinedAIServer] Internet scan #" + scanNumber + " beginning...");

        try
        {
            for (String category : CATEGORIES)
            {
                List<String> findings = scanCategoryViaHTTP(category);
                storeFindingsInDB(category, findings, scanNumber);

                // Also check for receding tempers on this category
                float temperIndex = speculator.measureRecedingTemper(category);
                storeRecedingTemperInDB(category, temperIndex);
            }

            // Store assessment (1,2,3,4)
            String assessment = speculator.assessFindings(scanNumber);
            dailyAssessments.put(scanNumber, assessment);
            storeAssessmentInDB(scanNumber, assessment);

            // If scan #4, produce final daily assessment
            if (scanNumber == 4)
            {
                String finalAssessment = speculator.produceFinalAssessment(dailyAssessments);
                storeAssessmentInDB(5, finalAssessment); // 5 = final
                dailyAssessments.clear();
                System.out.println("[DefinedAIServer] Final daily assessment stored.");
            }

            System.out.println("[DefinedAIServer] Scan #" + scanNumber + " complete.");
        }
        catch (Exception e)
        {
            System.err.println("[DefinedAIServer] Scan #" + scanNumber + " error: " + e.getMessage());
        }
    }

    private int determineScanNumber()
    {
        int hour = LocalTime.now(ZoneId.of("America/New_York")).getHour();
        if (hour < 6) return 1;
        if (hour < 12) return 2;
        if (hour < 18) return 3;
        return 4;
    }

    /**
     * Access internet via port 80 on target servers.
     * Check for licentious connections based on known moral shortcomings.
     * Populate with known moral metrics and socialism and key-turning gestures
     * like implied Social Contract.
     */
    private List<String> scanCategoryViaHTTP(String category)
    {
        List<String> findings = new ArrayList<>();
        try
        {
            // Access internet via port 80
            URL url = new URL("http://www.google.com/search?q=" + category.replace("-", "+"));
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(15000);
            conn.setRequestProperty("User-Agent", "Defined-AI-Module/1.0 (NitroWebExpress; DarkGray)");

            if (conn.getResponseCode() == 200)
            {
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream())))
                {
                    String line;
                    while ((line = reader.readLine()) != null)
                    {
                        if (speculator.isLicentiousIndicator(line))
                        {
                            findings.add(line.substring(0, Math.min(line.length(), 500)));
                        }
                    }
                }
            }
            conn.disconnect();

            // Store raw input for processing
            storeInternetInputInDB(url.toString(), findings.size() > 0 ? findings.get(0) : "");
        }
        catch (Exception e)
        {
            findings.add("[SCAN-ERROR] " + category + ": " + e.getMessage());
        }
        return findings;
    }

    private void storeFindingsInDB(String category, List<String> findings, int scanNumber)
    {
        try
        {
            PreparedStatement ps = dbConnection.prepareStatement(
                "INSERT INTO scan_findings (category, finding_text, scan_number, scan_date, created_ts) VALUES (?, ?, ?, CURDATE(), NOW())"
            );
            for (String finding : findings)
            {
                ps.setString(1, category);
                ps.setString(2, finding);
                ps.setInt(3, scanNumber);
                ps.addBatch();
            }
            ps.executeBatch();
        }
        catch (SQLException e)
        {
            System.err.println("[DefinedAIServer] DB store error: " + e.getMessage());
        }
    }

    private void storeAssessmentInDB(int assessmentNumber, String assessment)
    {
        try
        {
            PreparedStatement ps = dbConnection.prepareStatement(
                "INSERT INTO daily_assessments (assessment_number, assessment_text, assessment_date, created_ts) VALUES (?, ?, CURDATE(), NOW())"
            );
            ps.setInt(1, assessmentNumber);
            ps.setString(2, assessment);
            ps.executeUpdate();
        }
        catch (SQLException e)
        {
            System.err.println("[DefinedAIServer] Assessment store error: " + e.getMessage());
        }
    }

    private void storeRecedingTemperInDB(String category, float temperIndex)
    {
        try
        {
            float harmonicGrease = speculator.computeHarmonicGrease(category, temperIndex);
            PreparedStatement ps = dbConnection.prepareStatement(
                "INSERT INTO receding_tempers (category, temper_index, harmonic_grease, measured_ts) VALUES (?, ?, ?, NOW())"
            );
            ps.setString(1, category);
            ps.setFloat(2, temperIndex);
            ps.setFloat(3, harmonicGrease);
            ps.executeUpdate();
        }
        catch (SQLException e)
        {
            System.err.println("[DefinedAIServer] Receding temper store error: " + e.getMessage());
        }
    }

    private void storeInternetInputInDB(String sourceUrl, String content)
    {
        try
        {
            PreparedStatement ps = dbConnection.prepareStatement(
                "INSERT INTO internet_inputs (source_url, content_hash, raw_content, processed, scan_number, fetched_ts) VALUES (?, SHA2(?, 256), ?, FALSE, ?, NOW())"
            );
            ps.setString(1, sourceUrl);
            ps.setString(2, content);
            ps.setString(3, content.substring(0, Math.min(content.length(), 5000)));
            ps.setInt(4, determineScanNumber());
            ps.executeUpdate();
        }
        catch (SQLException e)
        {
            System.err.println("[DefinedAIServer] Internet input store error: " + e.getMessage());
        }
    }

    /**
     * Save weights and considerations on a daily basis at noon EST time in America.
     */
    private void saveDailyWeights()
    {
        try
        {
            Path weightDir = Paths.get("training/weights/daily");
            Files.createDirectories(weightDir);
            String date = LocalDate.now(ZoneId.of("America/New_York")).toString();
            speculator.saveWeights(weightDir.resolve("weights-" + date + ".bin"));

            // Also save moral disposition weights to MySQL
            PreparedStatement ps = dbConnection.prepareStatement(
                "INSERT INTO moral_weights (asia1, asia2, united_states, soviet_russia, save_date, created_ts) VALUES (?, ?, ?, ?, CURDATE(), NOW())"
            );
            ps.setFloat(1, moralWeights[0]);
            ps.setFloat(2, moralWeights[1]);
            ps.setFloat(3, moralWeights[2]);
            ps.setFloat(4, moralWeights[3]);
            ps.executeUpdate();

            System.out.println("[DefinedAIServer] Daily weights saved: " + date);
        }
        catch (Exception e)
        {
            System.err.println("[DefinedAIServer] Weight save error: " + e.getMessage());
        }
    }

    /**
     * Generate a periodic report for the United States, Europe, and Asia.
     * Store in /reports folder (not accessed by web app) and in the /annual folder.
     * Store input/output/assessment in the MySQL database.
     */
    private void generateReport(String period, int[] priority)
    {
        try
        {
            Path reportDir = Paths.get("reports/" + period);
            Path annualDir = Paths.get("annual");
            Files.createDirectories(reportDir);
            Files.createDirectories(annualDir);

            String date = LocalDate.now(ZoneId.of("America/New_York")).toString();
            String filename = period + "-report-" + date + ".txt";

            // Generate representative document for United States, Europe, Asia
            StringBuilder report = new StringBuilder();
            report.append("════════════════════════════════════════════════════════════════\n");
            report.append("  DEFINED™ — " + period.toUpperCase() + " REPORT\n");
            report.append("  Theme: Dark Gray — Definition to Narrow Cause\n");
            report.append("════════════════════════════════════════════════════════════════\n");
            report.append("Date: " + date + "\n");
            report.append("Priority Weights: " + Arrays.toString(priority) + "\n");
            report.append("Installer Tech ID: " + INSTALLER_TECH_ID + "\n");
            report.append("Safety: Careful and possible government secret.\n");
            report.append("\n");
            report.append("=== UNITED STATES ===\n");
            report.append(speculator.generateRegionReport("United States", priority));
            report.append("\n=== EUROPE ===\n");
            report.append(speculator.generateRegionReport("Europe", priority));
            report.append("\n=== ASIA ===\n");
            report.append(speculator.generateRegionReport("Asia", priority));
            report.append("\n════════════════════════════════════════════════════════════════\n");
            report.append("  End of Report. Moral Adjuster: Max Rupplin. Default: 1 = yes.\n");
            report.append("════════════════════════════════════════════════════════════════\n");

            Files.writeString(reportDir.resolve(filename), report.toString());

            // Annual and long-term reports also go to /annual
            if (period.equals("annual") || period.equals("2-year") ||
                period.equals("5-year") || period.equals("10-year"))
            {
                Files.writeString(annualDir.resolve(filename), report.toString());
            }

            // Store in DB
            PreparedStatement ps = dbConnection.prepareStatement(
                "INSERT INTO reports (period, priority_weights, report_text, report_date, created_ts) VALUES (?, ?, ?, CURDATE(), NOW())"
            );
            ps.setString(1, period);
            ps.setString(2, Arrays.toString(priority));
            ps.setString(3, report.toString());
            ps.executeUpdate();

            System.out.println("[DefinedAIServer] " + period + " report generated: " + filename);
        }
        catch (Exception e)
        {
            System.err.println("[DefinedAIServer] Report generation error: " + e.getMessage());
        }
    }

    @Override
    public void run()
    {
        try
        {
            serverSocket = new ServerSocket(PORT, BACKLOG);
            System.out.println("[DefinedAIServer] Listening on port " + PORT);

            while (running)
            {
                Socket client = serverSocket.accept();
                if (activeConnections.get() >= MAX_CONNECTIONS)
                {
                    client.close();
                    continue;
                }

                String ip = client.getInetAddress().getHostAddress();
                AtomicInteger count = ipCount.computeIfAbsent(ip, k -> new AtomicInteger(0));
                if (count.get() >= MAX_PER_IP)
                {
                    client.close();
                    continue;
                }
                count.incrementAndGet();
                activeConnections.incrementAndGet();
                pool.submit(() -> handleClient(client, ip));
            }
        }
        catch (IOException e)
        {
            if (running) System.err.println("[DefinedAIServer] Server error: " + e.getMessage());
        }
    }

    private void handleClient(Socket client, String ip)
    {
        try
        {
            client.setSoTimeout(TIMEOUT_MS);
            PrintWriter out = new PrintWriter(client.getOutputStream(), true);
            BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));

            // Display banner with notice
            out.print(BANNER);
            out.flush();

            // Display page links
            out.println("\nPage Links:");
            for (int i = 0; i < CATEGORIES.length; i++)
            {
                out.println("  [" + (i + 1) + "] " + CATEGORIES[i]);
            }
            out.println("\nCommands: scan, assess, report <period>, ntsb, categories, status, quit");
            out.print("defined> ");
            out.flush();

            String line;
            while ((line = in.readLine()) != null)
            {
                line = line.trim();
                String lower = line.toLowerCase();

                if (lower.equals("quit") || lower.equals("exit"))
                {
                    out.println("Goodbye. Remember: definition to narrow cause.");
                    break;
                }
                else if (lower.equals("ntsb"))
                {
                    // Second option: directly communicate with NTSB web server
                    ntsbCommunicator.interact(in, out);
                }
                else if (lower.equals("scan"))
                {
                    out.println("Next scan: " + getNextScanTime());
                    out.println("Scans today: " + dailyAssessments.size() + "/4");
                }
                else if (lower.equals("assess"))
                {
                    out.println("Today's assessments (1,2,3,4,final):");
                    for (Map.Entry<Integer, String> entry : dailyAssessments.entrySet())
                    {
                        out.println("  [" + entry.getKey() + "] " + entry.getValue());
                    }
                    if (dailyAssessments.isEmpty()) out.println("  (none yet today)");
                }
                else if (lower.startsWith("report"))
                {
                    out.println("Report periods: weekly (8,8,8,1,1), monthly (40,32,1,8,1),");
                    out.println("  quarterly (12,1,2,6,8,1,10), half-year (5,5,2,1,5), annual (6,2,1,2,1,6)");
                    out.println("Reports stored in /reports/ folder. Not web-accessible.");
                }
                else if (lower.equals("categories"))
                {
                    for (String c : CATEGORIES) out.println("  - " + c);
                }
                else if (lower.equals("status"))
                {
                    long uptimeMs = System.currentTimeMillis() - startTimeMs;
                    long uptimeHours = uptimeMs / (1000 * 60 * 60);
                    out.println("Defined™ Dark Gray — Status");
                    out.println("  Uptime: " + uptimeHours + " hours");
                    out.println("  Active connections: " + activeConnections.get());
                    out.println("  Moral weights: Asia=" + moralWeights[0] + " Asia2=" + moralWeights[1] +
                               " US=" + moralWeights[2] + " Russia=" + moralWeights[3]);
                    out.println("  Installer: " + INSTALLER_TECH_ID);
                }
                else if (lower.matches("\\d+") && Integer.parseInt(lower) >= 1 && Integer.parseInt(lower) <= CATEGORIES.length)
                {
                    int idx = Integer.parseInt(lower) - 1;
                    out.println("Category: " + CATEGORIES[idx]);
                    out.println("  Data folder: data/categories/" + CATEGORIES[idx] + "/");
                    out.println("  Accepts: .txt, .csv, .doc, .docx");
                }
                else
                {
                    out.println("Unknown command: " + line);
                    out.println("Commands: scan, assess, report, ntsb, categories, status, quit");
                }

                out.print("defined> ");
                out.flush();
            }
        }
        catch (Exception e)
        {
            // Connection timeout or error — silent
        }
        finally
        {
            activeConnections.decrementAndGet();
            AtomicInteger count = ipCount.get(ip);
            if (count != null) count.decrementAndGet();
            try { client.close(); } catch (IOException ignored) {}
        }
    }

    private String getNextScanTime()
    {
        ZoneId est = ZoneId.of("America/New_York");
        LocalDateTime now = LocalDateTime.now(est);
        int[] hours = {0, 6, 12, 18};
        for (int h : hours)
        {
            LocalDateTime t = now.withHour(h).withMinute(0).withSecond(0);
            if (t.isAfter(now)) return t.format(DateTimeFormatter.ofPattern("HH:mm")) + " EST";
        }
        return "00:00 EST (tomorrow)";
    }

    public void shutdown()
    {
        running = false;
        scheduler.shutdownNow();
        pool.shutdownNow();
        try { if (serverSocket != null) serverSocket.close(); } catch (IOException ignored) {}
        try { if (dbConnection != null) dbConnection.close(); } catch (SQLException ignored) {}
        if (speculator != null) speculator.close();
        System.out.println("[DefinedAIServer] Shutdown complete.");
    }
}
