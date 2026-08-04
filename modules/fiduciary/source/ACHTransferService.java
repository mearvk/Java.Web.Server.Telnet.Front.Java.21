/*
 * ACHTransferService.java — ACH & Payment Transfer API for NitroWebExpress
 *
 * Supports contacting and transferring monies to a known bank account
 * via pay-as-you-go ACH platforms and hybrid credit card/ACH processors.
 *
 * Supported Platforms:
 *
 *   PAY-AS-YOU-GO ACH (No Monthly Fees):
 *     - Melio:  Free standard ACH, 1% same-day. Plaid-linked.
 *     - Moov:   API-first, pay-per-use. FedNow/RTP settlement.
 *
 *   HYBRID PROCESSORS (Credit Card + ACH, No Monthly Fees):
 *     - Stripe: 0.8% ACH (max $5), 2.9% + $0.30 card. E-commerce.
 *     - Square: 1% ACH (min $1), 2.9% + $0.30 card. Invoicing.
 *     - Helcim: 0.5% + $0.25 ACH (max $6), ~2.27% + $0.25 card. B2B.
 *
 * Integration: NitroWebExpress (JWSTF) via Jakarta Servlet on Tomcat 10.1
 *
 * Author: Max Rupplin — MEARVK LLC
 * Date: August 3 2026
 * License: GPL-2.0
 */

package com.mearvk.fiduciary.ach;

import java.io.*;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ACHTransferService — Primary API for initiating, tracking, and managing
 * bank-to-bank transfers across multiple payment platforms.
 *
 * Thread-safe, connection-pooled, and suitable for servlet container deployment.
 */
public class ACHTransferService
{
    /* ═══════════════════════════════════════════════════════════════════
       Constants
       ═══════════════════════════════════════════════════════════════════ */

    private static final String VERSION = "1.0.0";
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_fiduciary";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    /* ═══════════════════════════════════════════════════════════════════
       Enumerations
       ═══════════════════════════════════════════════════════════════════ */

    public enum Platform
    {
        MELIO("melio", "Melio", "https://api.melio.com/v1",
              0.00, 0.00, 0.00, 0.00, 0.00, 2.90, 0.30,
              true, true, false, false, true,
              "Zero-fee standard business ACH transactions",
              "Plaid instant link to online banking credentials"),

        MOOV("moov", "Moov", "https://api.moov.io/v1",
             0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
             true, false, true, true, false,
             "API-first automated or per-use software integrations",
             "Developer API for two-legged standard and same-day FedNow/RTP settlement"),

        STRIPE("stripe", "Stripe", "https://api.stripe.com/v1",
               0.00, 0.80, 0.00, 5.00, 0.00, 2.90, 0.30,
               true, true, false, false, true,
               "E-commerce web checkouts, custom code integrations, international currencies",
               "API key + Plaid for bank verification"),

        SQUARE("square", "Square", "https://connect.squareup.com/v2",
               0.00, 1.00, 0.00, 0.00, 1.00, 2.90, 0.30,
               true, true, false, false, false,
               "Quick invoice links, easy virtual terminals, immediate day-after payouts",
               "OAuth application credentials + bank account on file"),

        HELCIM("helcim", "Helcim", "https://api.helcim.com/v2",
               0.00, 0.50, 0.25, 6.00, 0.00, 2.27, 0.25,
               true, true, false, false, false,
               "Wholesale, B2B invoicing, automated surcharging to pass fees to customer",
               "API token + merchant account");

        public final String id;
        public final String displayName;
        public final String apiBaseUrl;
        public final double monthlyFee;
        public final double achPct;
        public final double achFlat;
        public final double achCap;
        public final double achMin;
        public final double cardPct;
        public final double cardFlat;
        public final boolean supportsAch;
        public final boolean supportsCard;
        public final boolean supportsFedNow;
        public final boolean supportsRtp;
        public final boolean supportsPlaid;
        public final String bestFor;
        public final String connectionMethod;

        Platform(String id, String displayName, String apiBaseUrl,
                 double monthlyFee, double achPct, double achFlat, double achCap, double achMin,
                 double cardPct, double cardFlat,
                 boolean supportsAch, boolean supportsCard,
                 boolean supportsFedNow, boolean supportsRtp, boolean supportsPlaid,
                 String bestFor, String connectionMethod)
        {
            this.id = id;
            this.displayName = displayName;
            this.apiBaseUrl = apiBaseUrl;
            this.monthlyFee = monthlyFee;
            this.achPct = achPct;
            this.achFlat = achFlat;
            this.achCap = achCap;
            this.achMin = achMin;
            this.cardPct = cardPct;
            this.cardFlat = cardFlat;
            this.supportsAch = supportsAch;
            this.supportsCard = supportsCard;
            this.supportsFedNow = supportsFedNow;
            this.supportsRtp = supportsRtp;
            this.supportsPlaid = supportsPlaid;
            this.bestFor = bestFor;
            this.connectionMethod = connectionMethod;
        }

        public static Platform fromString(String name)
        {
            for (Platform p : values())
                if (p.id.equalsIgnoreCase(name) || p.displayName.equalsIgnoreCase(name))
                    return p;
            throw new IllegalArgumentException("Unknown platform: " + name);
        }
    }

    public enum PaymentMethod { ACH, CARD, FEDNOW, RTP }
    public enum TransferSpeed { STANDARD, SAME_DAY, INSTANT }
    public enum TransferStatus { PENDING, PROCESSING, COMPLETED, FAILED, RETURNED }

    /* ═══════════════════════════════════════════════════════════════════
       Data Transfer Objects
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Transfer request — all parameters needed to initiate a payment.
     */
    public static class TransferRequest
    {
        public Platform platform;
        public PaymentMethod method = PaymentMethod.ACH;
        public TransferSpeed speed = TransferSpeed.STANDARD;
        public String routingNumber;       // 9-digit ABA
        public String accountNumber;       // up to 17 digits
        public String beneficiaryName;
        public BigDecimal amount;          // USD
        public String memo = "";
        public String idempotencyKey;
        public String apiKey;

        public TransferRequest() {}

        public TransferRequest(Platform platform, String routingNumber,
                               String accountNumber, BigDecimal amount)
        {
            this.platform = platform;
            this.routingNumber = routingNumber;
            this.accountNumber = accountNumber;
            this.amount = amount;
        }
    }

    /**
     * Transfer result — returned after initiating or querying a transfer.
     */
    public static class TransferResult
    {
        public long transferId;
        public TransferStatus status;
        public String platformReference;
        public BigDecimal feeAmount;
        public String feeBreakdown;
        public int httpCode;
        public String responseBody;
        public String errorMessage;
        public Instant initiatedAt;

        public boolean isSuccess() { return status == TransferStatus.PROCESSING || status == TransferStatus.COMPLETED; }
    }

    /**
     * Fee estimate — calculated fee for a given platform, method, and amount.
     */
    public static class FeeEstimate
    {
        public Platform platform;
        public PaymentMethod method;
        public BigDecimal amount;
        public BigDecimal fee;
        public String breakdown;
        public BigDecimal total;
    }

    /* ═══════════════════════════════════════════════════════════════════
       Singleton Instance & HTTP Client
       ═══════════════════════════════════════════════════════════════════ */

    private static ACHTransferService instance;
    private final HttpClient httpClient;
    private final Map<String, String> apiKeys = new ConcurrentHashMap<>();

    private ACHTransferService()
    {
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .build();
    }

    public static synchronized ACHTransferService getInstance()
    {
        if (instance == null) instance = new ACHTransferService();
        return instance;
    }

    /* ═══════════════════════════════════════════════════════════════════
       API Key Management
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Register an API key for a platform. Keys are stored in memory only.
     * For production, retrieve from encrypted DB or environment variables.
     */
    public void setApiKey(Platform platform, String key)
    {
        apiKeys.put(platform.id, key);
    }

    /**
     * Resolve API key: explicit request key > registered key > env variable.
     */
    private String resolveApiKey(TransferRequest req)
    {
        if (req.apiKey != null && !req.apiKey.isBlank()) return req.apiKey;
        String registered = apiKeys.get(req.platform.id);
        if (registered != null) return registered;

        // Fall back to environment variables
        return switch (req.platform) {
            case MELIO  -> System.getenv("MELIO_API_KEY");
            case MOOV   -> System.getenv("MOOV_API_KEY");
            case STRIPE -> System.getenv("STRIPE_SECRET_KEY");
            case SQUARE -> System.getenv("SQUARE_ACCESS_TOKEN");
            case HELCIM -> System.getenv("HELCIM_API_TOKEN");
        };
    }

    /* ═══════════════════════════════════════════════════════════════════
       Fee Calculation
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Calculate fees for a given platform, method, and transfer amount.
     */
    public FeeEstimate calculateFee(Platform platform, PaymentMethod method, BigDecimal amount)
    {
        FeeEstimate est = new FeeEstimate();
        est.platform = platform;
        est.method = method;
        est.amount = amount;

        if (method == PaymentMethod.ACH || method == PaymentMethod.FEDNOW || method == PaymentMethod.RTP) {
            BigDecimal pctFee = amount.multiply(BigDecimal.valueOf(platform.achPct / 100.0));
            BigDecimal total = pctFee.add(BigDecimal.valueOf(platform.achFlat));

            // Apply cap
            if (platform.achCap > 0.0 && total.doubleValue() > platform.achCap)
                total = BigDecimal.valueOf(platform.achCap);

            // Apply minimum
            if (platform.achMin > 0.0 && total.doubleValue() < platform.achMin)
                total = BigDecimal.valueOf(platform.achMin);

            // Melio standard is free
            if (platform == Platform.MELIO)
                total = BigDecimal.ZERO;

            est.fee = total.setScale(2, RoundingMode.HALF_UP);
            est.breakdown = String.format("ACH: %.3f%% + $%.2f (cap: $%.2f, min: $%.2f) = $%s",
                platform.achPct, platform.achFlat, platform.achCap, platform.achMin, est.fee);
        }
        else if (method == PaymentMethod.CARD) {
            BigDecimal total = amount.multiply(BigDecimal.valueOf(platform.cardPct / 100.0))
                .add(BigDecimal.valueOf(platform.cardFlat));
            est.fee = total.setScale(2, RoundingMode.HALF_UP);
            est.breakdown = String.format("Card: %.2f%% + $%.2f = $%s",
                platform.cardPct, platform.cardFlat, est.fee);
        }

        est.total = amount.add(est.fee);
        return est;
    }

    /**
     * Melio same-day ACH is 1% (special case).
     */
    public FeeEstimate calculateMelioSameDay(BigDecimal amount)
    {
        FeeEstimate est = new FeeEstimate();
        est.platform = Platform.MELIO;
        est.method = PaymentMethod.ACH;
        est.amount = amount;
        est.fee = amount.multiply(BigDecimal.valueOf(0.01)).setScale(2, RoundingMode.HALF_UP);
        est.breakdown = String.format("Melio same-day ACH: 1.0%% of $%s = $%s", amount, est.fee);
        est.total = amount.add(est.fee);
        return est;
    }

    /* ═══════════════════════════════════════════════════════════════════
       Routing Number Validation (ABA Checksum)
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Validates a 9-digit ABA routing number using the standard checksum algorithm.
     * 3(d1 + d4 + d7) + 7(d2 + d5 + d8) + (d3 + d6 + d9) mod 10 == 0
     */
    public static boolean validateRoutingNumber(String routing)
    {
        if (routing == null || routing.length() != 9) return false;
        for (char c : routing.toCharArray())
            if (!Character.isDigit(c)) return false;

        int[] weights = {3, 7, 1, 3, 7, 1, 3, 7, 1};
        int sum = 0;
        for (int i = 0; i < 9; i++)
            sum += (routing.charAt(i) - '0') * weights[i];

        return (sum % 10) == 0;
    }

    /* ═══════════════════════════════════════════════════════════════════
       Transfer Execution
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Initiate an ACH transfer to a known bank account.
     *
     * @param req The transfer request with all parameters.
     * @return TransferResult with status, fees, and platform reference.
     * @throws IllegalArgumentException if routing number or parameters are invalid.
     */
    public TransferResult initiateTransfer(TransferRequest req) throws Exception
    {
        // Validate
        if (!validateRoutingNumber(req.routingNumber))
            throw new IllegalArgumentException("Invalid ABA routing number: " + req.routingNumber);
        if (req.amount == null || req.amount.compareTo(BigDecimal.ZERO) <= 0)
            throw new IllegalArgumentException("Amount must be positive");

        // Resolve API key
        String apiKey = resolveApiKey(req);
        if (apiKey == null || apiKey.isBlank())
            throw new IllegalStateException("No API key found for platform: " + req.platform.displayName
                + ". Set via setApiKey(), --api-key, or environment variable.");

        // Generate idempotency key
        if (req.idempotencyKey == null || req.idempotencyKey.isBlank())
            req.idempotencyKey = "ach_" + UUID.randomUUID().toString().replace("-", "").substring(0, 24);

        // Calculate fee
        FeeEstimate fee = (req.platform == Platform.MELIO && req.speed == TransferSpeed.SAME_DAY)
            ? calculateMelioSameDay(req.amount)
            : calculateFee(req.platform, req.method, req.amount);

        // Record in database
        long transferId = recordTransfer(req, fee);

        // Build and send API request
        TransferResult result = new TransferResult();
        result.transferId = transferId;
        result.feeAmount = fee.fee;
        result.feeBreakdown = fee.breakdown;
        result.initiatedAt = Instant.now();

        try {
            HttpResponse<String> response = sendPlatformRequest(req, apiKey);
            result.httpCode = response.statusCode();
            result.responseBody = response.body();

            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                result.status = TransferStatus.PROCESSING;
                result.platformReference = req.idempotencyKey;
            } else {
                result.status = TransferStatus.FAILED;
                result.errorMessage = "HTTP " + response.statusCode() + ": " + response.body();
            }
        } catch (Exception e) {
            result.status = TransferStatus.PENDING;
            result.errorMessage = "API unreachable: " + e.getMessage();
        }

        // Update database
        updateTransferStatus(transferId, result);
        auditLog(transferId, "initiated", "HTTP " + result.httpCode + " via " + req.platform.id);

        return result;
    }

    /* ═══════════════════════════════════════════════════════════════════
       Platform-Specific Request Builders
       ═══════════════════════════════════════════════════════════════════ */

    private HttpResponse<String> sendPlatformRequest(TransferRequest req, String apiKey) throws Exception
    {
        String url;
        String body;

        switch (req.platform) {
            case STRIPE -> {
                url = req.platform.apiBaseUrl + "/payment_intents";
                int amountCents = req.amount.multiply(BigDecimal.valueOf(100)).intValue();
                body = String.format("""
                    {
                      "amount": %d,
                      "currency": "usd",
                      "payment_method_types": ["us_bank_account"],
                      "payment_method_data": {
                        "type": "us_bank_account",
                        "us_bank_account": {
                          "routing_number": "%s",
                          "account_number": "%s",
                          "account_holder_type": "individual"
                        }
                      },
                      "metadata": {
                        "memo": "%s",
                        "idempotency_key": "%s"
                      }
                    }""", amountCents, req.routingNumber, req.accountNumber,
                    escapeJson(req.memo), req.idempotencyKey);
            }
            case MOOV -> {
                url = req.platform.apiBaseUrl + "/transfers";
                body = String.format("""
                    {
                      "amount": {
                        "value": %d,
                        "currency": "USD"
                      },
                      "destination": {
                        "paymentMethodType": "ach-debit-fund",
                        "ach": {
                          "routingNumber": "%s",
                          "accountNumber": "%s"
                        }
                      },
                      "description": "%s"
                    }""", req.amount.multiply(BigDecimal.valueOf(100)).intValue(),
                    req.routingNumber, req.accountNumber, escapeJson(req.memo));
            }
            case SQUARE -> {
                url = req.platform.apiBaseUrl + "/payments";
                int amountCents = req.amount.multiply(BigDecimal.valueOf(100)).intValue();
                body = String.format("""
                    {
                      "source_id": "EXTERNAL",
                      "idempotency_key": "%s",
                      "amount_money": {
                        "amount": %d,
                        "currency": "USD"
                      },
                      "bank_account_details": {
                        "routing_number": "%s",
                        "account_number": "%s"
                      },
                      "note": "%s"
                    }""", req.idempotencyKey, amountCents,
                    req.routingNumber, req.accountNumber, escapeJson(req.memo));
            }
            case HELCIM -> {
                url = req.platform.apiBaseUrl + "/payment/purchase";
                body = String.format("""
                    {
                      "paymentType": "ach",
                      "amount": %.2f,
                      "currency": "USD",
                      "bankAccount": {
                        "routingNumber": "%s",
                        "accountNumber": "%s",
                        "accountType": "checking"
                      },
                      "idempotencyKey": "%s"
                    }""", req.amount, req.routingNumber, req.accountNumber, req.idempotencyKey);
            }
            case MELIO -> {
                url = req.platform.apiBaseUrl + "/payments";
                String deliveryMethod = req.speed == TransferSpeed.SAME_DAY ? "expedited-ach" : "ach";
                body = String.format("""
                    {
                      "amount": %.2f,
                      "currency": "USD",
                      "deliveryMethod": "%s",
                      "vendorBankAccount": {
                        "routingNumber": "%s",
                        "accountNumber": "%s"
                      },
                      "memo": "%s"
                    }""", req.amount, deliveryMethod,
                    req.routingNumber, req.accountNumber, escapeJson(req.memo));
            }
            default -> throw new IllegalStateException("Unsupported platform: " + req.platform);
        }

        HttpRequest httpReq = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .header("Authorization", "Bearer " + apiKey)
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .header("Idempotency-Key", req.idempotencyKey)
            .timeout(Duration.ofSeconds(30))
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build();

        return httpClient.send(httpReq, HttpResponse.BodyHandlers.ofString());
    }

    /* ═══════════════════════════════════════════════════════════════════
       Database Operations
       ═══════════════════════════════════════════════════════════════════ */

    private Connection getConnection() throws SQLException
    {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    /**
     * Initialize database tables (call once at startup).
     */
    public void initializeDatabase() throws SQLException
    {
        try (Connection conn = getConnection(); Statement stmt = conn.createStatement()) {
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS ach_platforms (
                  id INT AUTO_INCREMENT PRIMARY KEY,
                  name VARCHAR(32) NOT NULL UNIQUE,
                  display_name VARCHAR(64),
                  api_base_url VARCHAR(256),
                  monthly_fee DECIMAL(10,2) DEFAULT 0.00,
                  ach_pct DECIMAL(5,3) DEFAULT 0.000,
                  ach_flat DECIMAL(5,2) DEFAULT 0.00,
                  ach_cap DECIMAL(10,2) DEFAULT 0.00,
                  card_pct DECIMAL(5,3) DEFAULT 0.000,
                  card_flat DECIMAL(5,2) DEFAULT 0.00,
                  supports_ach TINYINT DEFAULT 1,
                  supports_card TINYINT DEFAULT 0,
                  supports_fednow TINYINT DEFAULT 0,
                  supports_rtp TINYINT DEFAULT 0,
                  best_for TEXT,
                  active TINYINT DEFAULT 1,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_name (name)
                ) ENGINE=InnoDB""");

            stmt.execute("""
                CREATE TABLE IF NOT EXISTS ach_accounts (
                  id BIGINT AUTO_INCREMENT PRIMARY KEY,
                  label VARCHAR(128) NOT NULL,
                  routing_number VARCHAR(9) NOT NULL,
                  account_number_encrypted BLOB NOT NULL,
                  account_type ENUM('checking','savings') DEFAULT 'checking',
                  beneficiary_name VARCHAR(256),
                  bank_name VARCHAR(128),
                  verified TINYINT DEFAULT 0,
                  verification_method VARCHAR(32),
                  platform VARCHAR(32),
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_label (label)
                ) ENGINE=InnoDB""");

            stmt.execute("""
                CREATE TABLE IF NOT EXISTS ach_transfers (
                  id BIGINT AUTO_INCREMENT PRIMARY KEY,
                  platform VARCHAR(32) NOT NULL,
                  method ENUM('ach','card','fednow','rtp') NOT NULL DEFAULT 'ach',
                  speed ENUM('standard','same_day','instant') NOT NULL DEFAULT 'standard',
                  direction ENUM('send','receive') NOT NULL DEFAULT 'send',
                  amount DECIMAL(12,2) NOT NULL,
                  currency VARCHAR(3) DEFAULT 'USD',
                  fee_amount DECIMAL(10,2) DEFAULT 0.00,
                  fee_calculation TEXT,
                  routing_number VARCHAR(9),
                  beneficiary_name VARCHAR(256),
                  memo VARCHAR(256),
                  idempotency_key VARCHAR(64),
                  platform_reference VARCHAR(128),
                  status ENUM('pending','processing','completed','failed','returned') DEFAULT 'pending',
                  error_message TEXT,
                  initiated_by VARCHAR(64),
                  initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  completed_at TIMESTAMP NULL,
                  INDEX idx_platform (platform),
                  INDEX idx_status (status),
                  INDEX idx_idempotency (idempotency_key)
                ) ENGINE=InnoDB""");

            stmt.execute("""
                CREATE TABLE IF NOT EXISTS ach_audit_log (
                  id BIGINT AUTO_INCREMENT PRIMARY KEY,
                  transfer_id BIGINT,
                  event_type VARCHAR(32) NOT NULL,
                  event_detail TEXT,
                  event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  actor VARCHAR(64),
                  INDEX idx_transfer (transfer_id)
                ) ENGINE=InnoDB""");
        }
    }

    private long recordTransfer(TransferRequest req, FeeEstimate fee) throws SQLException
    {
        String sql = "INSERT INTO ach_transfers (platform, method, speed, direction, amount, " +
            "fee_amount, fee_calculation, routing_number, beneficiary_name, memo, " +
            "idempotency_key, status, initiated_by) " +
            "VALUES (?, ?, ?, 'send', ?, ?, ?, ?, ?, ?, ?, 'pending', ?)";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS))
        {
            ps.setString(1, req.platform.id);
            ps.setString(2, req.method.name().toLowerCase());
            ps.setString(3, req.speed.name().toLowerCase().replace("_", "_"));
            ps.setBigDecimal(4, req.amount);
            ps.setBigDecimal(5, fee.fee);
            ps.setString(6, fee.breakdown);
            ps.setString(7, req.routingNumber);
            ps.setString(8, req.beneficiaryName);
            ps.setString(9, req.memo);
            ps.setString(10, req.idempotencyKey);
            ps.setString(11, System.getProperty("user.name", "system"));
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getLong(1);
            }
        }
        return -1;
    }

    private void updateTransferStatus(long transferId, TransferResult result) throws SQLException
    {
        String sql = "UPDATE ach_transfers SET status=?, platform_reference=?, error_message=? WHERE id=?";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, result.status.name().toLowerCase());
            ps.setString(2, result.platformReference);
            ps.setString(3, result.errorMessage);
            ps.setLong(4, transferId);
            ps.executeUpdate();
        }
    }

    private void auditLog(long transferId, String eventType, String detail) throws SQLException
    {
        String sql = "INSERT INTO ach_audit_log (transfer_id, event_type, event_detail, actor) VALUES (?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, transferId);
            ps.setString(2, eventType);
            ps.setString(3, detail);
            ps.setString(4, System.getProperty("user.name", "system"));
            ps.executeUpdate();
        }
    }

    /* ═══════════════════════════════════════════════════════════════════
       Query Operations
       ═══════════════════════════════════════════════════════════════════ */

    /**
     * Get transfer status by idempotency key or platform reference.
     */
    public TransferResult getTransferStatus(String reference) throws SQLException
    {
        String sql = "SELECT id, platform, method, speed, amount, fee_amount, status, " +
            "beneficiary_name, initiated_at, completed_at, platform_reference, error_message " +
            "FROM ach_transfers WHERE idempotency_key=? OR platform_reference=? " +
            "ORDER BY initiated_at DESC LIMIT 1";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, reference);
            ps.setString(2, reference);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    TransferResult result = new TransferResult();
                    result.transferId = rs.getLong("id");
                    result.status = TransferStatus.valueOf(rs.getString("status").toUpperCase());
                    result.feeAmount = rs.getBigDecimal("fee_amount");
                    result.platformReference = rs.getString("platform_reference");
                    result.errorMessage = rs.getString("error_message");
                    result.initiatedAt = rs.getTimestamp("initiated_at").toInstant();
                    return result;
                }
            }
        }
        return null;
    }

    /**
     * Get transfer history.
     */
    public List<TransferResult> getTransferHistory(int limit) throws SQLException
    {
        List<TransferResult> results = new ArrayList<>();
        String sql = "SELECT id, platform, amount, fee_amount, status, initiated_at, " +
            "platform_reference, error_message FROM ach_transfers ORDER BY initiated_at DESC LIMIT ?";

        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TransferResult r = new TransferResult();
                    r.transferId = rs.getLong("id");
                    r.status = TransferStatus.valueOf(rs.getString("status").toUpperCase());
                    r.feeAmount = rs.getBigDecimal("fee_amount");
                    r.platformReference = rs.getString("platform_reference");
                    r.errorMessage = rs.getString("error_message");
                    r.initiatedAt = rs.getTimestamp("initiated_at").toInstant();
                    results.add(r);
                }
            }
        }
        return results;
    }

    /**
     * Get all platform info as a list of maps (for API responses / JSON serialization).
     */
    public List<Map<String, Object>> listPlatforms()
    {
        List<Map<String, Object>> list = new ArrayList<>();
        for (Platform p : Platform.values()) {
            Map<String, Object> info = new LinkedHashMap<>();
            info.put("id", p.id);
            info.put("displayName", p.displayName);
            info.put("monthlyFee", p.monthlyFee);
            info.put("achPct", p.achPct);
            info.put("achFlat", p.achFlat);
            info.put("achCap", p.achCap);
            info.put("achMin", p.achMin);
            info.put("cardPct", p.cardPct);
            info.put("cardFlat", p.cardFlat);
            info.put("supportsAch", p.supportsAch);
            info.put("supportsCard", p.supportsCard);
            info.put("supportsFedNow", p.supportsFedNow);
            info.put("supportsRtp", p.supportsRtp);
            info.put("supportsPlaid", p.supportsPlaid);
            info.put("bestFor", p.bestFor);
            info.put("connectionMethod", p.connectionMethod);
            list.add(info);
        }
        return list;
    }

    /* ═══════════════════════════════════════════════════════════════════
       Utility
       ═══════════════════════════════════════════════════════════════════ */

    private static String escapeJson(String s)
    {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    /* ═══════════════════════════════════════════════════════════════════
       CLI Main (standalone execution)
       ═══════════════════════════════════════════════════════════════════ */

    public static void main(String[] args) throws Exception
    {
        ACHTransferService service = getInstance();

        if (args.length == 0 || "--help".equals(args[0]) || "-h".equals(args[0])) {
            printUsage();
            return;
        }

        if ("--list-platforms".equals(args[0]) || "-l".equals(args[0])) {
            printPlatformTable();
            return;
        }

        // Parse command-line arguments
        Platform platform = null;
        PaymentMethod method = PaymentMethod.ACH;
        TransferSpeed speed = TransferSpeed.STANDARD;
        String routing = null, account = null, memo = "", name = "", apiKey = null, reference = null;
        BigDecimal amount = null;
        boolean doFee = false, doStatus = false, doHistory = false;
        int historyLimit = 20;

        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--platform" -> platform = Platform.fromString(args[++i]);
                case "--to" -> {
                    String[] parts = args[++i].split(":");
                    routing = parts[0];
                    account = parts.length > 1 ? parts[1] : "";
                }
                case "--amount" -> amount = new BigDecimal(args[++i]);
                case "--method" -> method = PaymentMethod.valueOf(args[++i].toUpperCase());
                case "--speed" -> speed = TransferSpeed.valueOf(args[++i].toUpperCase().replace("-", "_"));
                case "--memo" -> memo = args[++i];
                case "--name" -> name = args[++i];
                case "--api-key" -> apiKey = args[++i];
                case "--fee-estimate" -> doFee = true;
                case "--status" -> doStatus = true;
                case "--reference" -> reference = args[++i];
                case "--history" -> doHistory = true;
                case "--limit" -> historyLimit = Integer.parseInt(args[++i]);
            }
        }

        if (doFee && platform != null && amount != null) {
            FeeEstimate fee = (platform == Platform.MELIO && speed == TransferSpeed.SAME_DAY)
                ? service.calculateMelioSameDay(amount)
                : service.calculateFee(platform, method, amount);
            System.out.printf("\n  Fee Estimate — %s (%s)%n", platform.displayName,
                method == PaymentMethod.CARD ? "Card" : "ACH");
            System.out.printf("    Amount: $%s%n", amount);
            System.out.printf("    Fee:    $%s%n", fee.fee);
            System.out.printf("    Total:  $%s%n", fee.total);
            System.out.printf("    %s%n%n", fee.breakdown);
            return;
        }

        // Initialize DB for transfer/status/history operations
        service.initializeDatabase();

        if (doStatus && reference != null) {
            TransferResult r = service.getTransferStatus(reference);
            if (r != null) {
                System.out.printf("\n  Transfer #%d — Status: %s%n", r.transferId, r.status);
                System.out.printf("    Fee: $%s | Reference: %s%n", r.feeAmount, r.platformReference);
                System.out.printf("    Initiated: %s%n%n", r.initiatedAt);
            } else {
                System.out.printf("\n  No transfer found for: %s%n%n", reference);
            }
            return;
        }

        if (doHistory) {
            List<TransferResult> history = service.getTransferHistory(historyLimit);
            System.out.printf("\n  Transfer History (last %d):%n", historyLimit);
            for (TransferResult r : history) {
                System.out.printf("    #%d  %s  $%s  fee=$%s  %s%n",
                    r.transferId, r.platformReference, r.feeAmount, r.feeAmount, r.status);
            }
            System.out.println();
            return;
        }

        // Execute transfer
        if (platform == null || routing == null || account == null || amount == null) {
            System.err.println("Error: --platform, --to, and --amount are required.");
            printUsage();
            return;
        }

        TransferRequest req = new TransferRequest(platform, routing, account, amount);
        req.method = method;
        req.speed = speed;
        req.memo = memo;
        req.beneficiaryName = name;
        req.apiKey = apiKey;

        TransferResult result = service.initiateTransfer(req);
        System.out.printf("\n  Transfer %s — %s%n",
            result.isSuccess() ? "✓ INITIATED" : "✗ FAILED", platform.displayName);
        System.out.printf("    Amount: $%s | Fee: $%s | Status: %s%n",
            amount, result.feeAmount, result.status);
        if (result.errorMessage != null)
            System.out.printf("    Error: %s%n", result.errorMessage);
        System.out.printf("    Reference: %s%n%n", result.platformReference);
    }

    private static void printUsage()
    {
        System.out.println("""

          ACH Transfer — FiduciaryServices™ Payment API (Java) v""" + VERSION + """


          Usage:
            java ACHTransferService --platform <name> --to <routing:account> --amount <USD>
                                    [--method ach|card] [--speed standard|same-day|instant]
                                    [--memo "note"] [--name "Beneficiary"] [--api-key <key>]

            java ACHTransferService --list-platforms
            java ACHTransferService --fee-estimate --platform <name> --amount <USD> [--method ach|card]
            java ACHTransferService --status --reference <txn_id>
            java ACHTransferService --history [--limit N]

          Platforms: melio, moov, stripe, square, helcim

          Examples:
            --platform melio --to 021000021:123456789 --amount 500.00
            --platform stripe --to 021000021:123456789 --amount 1000 --method ach
            --fee-estimate --platform helcim --amount 5000 --method card
        """);
    }

    private static void printPlatformTable()
    {
        System.out.println("""

          ═══ PAY-AS-YOU-GO ACH PLATFORMS (No Monthly Fees) ═══

          Melio — Zero-fee standard business ACH transactions
            Cost: Standard ACH is 100% FREE. Same-day expedited: 1% fee.
            Connection: Plaid instant link to online banking credentials.

          Moov — API-first automated or per-use software integrations
            Cost: Pure pay-as-you-go pricing, no monthly base fees.
            Connection: Developer API for two-legged standard and same-day FedNow/RTP settlement.
            Supports: ACH + FedNow + RTP settlement windows.

          ═══ HYBRID PROCESSORS (Credit Card + ACH, $0/mo) ═══

          Provider   Monthly  ACH Per-Use           Card Online           Best For
          ────────   ───────  ──────────────────    ──────────────────    ──────────────────────────
          Stripe     $0       0.8% (cap $5)         2.9% + $0.30         E-commerce, custom code, intl
          Square     $0       1% (min $1)           2.9% + $0.30         Invoices, virtual terminals
          Helcim     $0       0.5% + $0.25 (cap $6) ~2.27% + $0.25 (I+)  B2B invoicing, surcharging
        """);
    }
}
