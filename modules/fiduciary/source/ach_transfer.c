/*
 * ach_transfer.c — ACH & Payment Transfer API for FiduciaryServices™
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
 * Usage:
 *   ach_transfer --platform melio --to "routing:account" --amount 500.00
 *   ach_transfer --platform stripe --to "routing:account" --amount 1000.00 --method ach
 *   ach_transfer --platform moov --to "routing:account" --amount 250.00 --speed same-day
 *   ach_transfer --list-platforms
 *   ach_transfer --fee-estimate --platform stripe --amount 5000.00 --method card
 *   ach_transfer --status --reference "txn_abc123"
 *
 * Database: nwe_fiduciary (table: ach_transfers, ach_accounts, ach_platforms)
 *
 * Build:
 *   gcc -O2 -o ach_transfer ach_transfer.c -lmysqlclient -lcurl -lm
 *
 * Author: Max Rupplin — MEARVK LLC
 * Date: August 3 2026
 * License: GPL-2.0
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <math.h>
#include <mysql/mysql.h>
#include <curl/curl.h>

#define VERSION "1.0.0"
#define DB_HOST "127.0.0.1"
#define DB_USER "root"
#define DB_PASS ""
#define DB_NAME "nwe_fiduciary"
#define DB_PORT 3306
#define MAX_INPUT 2048
#define MAX_RESPONSE 8192
#define MAX_URL 512
#define MAX_HEADER 256
#define MAX_BODY 16384

/* ═══════════════════════════════════════════════════════════════════════
   ANSI Colors
   ═══════════════════════════════════════════════════════════════════════ */
#define C_RESET   "\033[0m"
#define C_LTBLUE  "\033[38;5;117m"
#define C_WHITE   "\033[37;1m"
#define C_GOLD    "\033[33;1m"
#define C_GREEN   "\033[32;1m"
#define C_RED     "\033[31;1m"
#define C_CYAN    "\033[36m"
#define C_DIM     "\033[2m"

/* ═══════════════════════════════════════════════════════════════════════
   Platform Definitions
   ═══════════════════════════════════════════════════════════════════════ */

typedef enum {
    PLATFORM_MELIO = 0,
    PLATFORM_MOOV,
    PLATFORM_STRIPE,
    PLATFORM_SQUARE,
    PLATFORM_HELCIM,
    PLATFORM_COUNT
} Platform;

typedef enum {
    METHOD_ACH = 0,
    METHOD_CARD,
    METHOD_FEDNOW,
    METHOD_RTP
} PaymentMethod;

typedef enum {
    SPEED_STANDARD = 0,
    SPEED_SAME_DAY,
    SPEED_INSTANT
} TransferSpeed;

typedef enum {
    STATUS_PENDING = 0,
    STATUS_PROCESSING,
    STATUS_COMPLETED,
    STATUS_FAILED,
    STATUS_RETURNED
} TransferStatus;

typedef struct {
    const char *name;
    const char *display_name;
    const char *api_base_url;
    const char *docs_url;
    double      monthly_fee;
    double      ach_pct;         /* percentage fee for ACH */
    double      ach_flat;        /* flat fee for ACH */
    double      ach_cap;         /* max fee cap for ACH */
    double      ach_min;         /* min fee for ACH */
    double      card_pct;        /* percentage fee for card */
    double      card_flat;       /* flat fee per card transaction */
    int         supports_ach;
    int         supports_card;
    int         supports_fednow;
    int         supports_rtp;
    int         supports_plaid;
    const char *best_for;
    const char *connection_method;
} PlatformInfo;

static const PlatformInfo platforms[PLATFORM_COUNT] = {
    [PLATFORM_MELIO] = {
        .name = "melio",
        .display_name = "Melio",
        .api_base_url = "https://api.melio.com/v1",
        .docs_url = "https://developers.melio.com",
        .monthly_fee = 0.00,
        .ach_pct = 0.00,
        .ach_flat = 0.00,
        .ach_cap = 0.00,
        .ach_min = 0.00,
        .card_pct = 2.90,
        .card_flat = 0.30,
        .supports_ach = 1,
        .supports_card = 1,
        .supports_fednow = 0,
        .supports_rtp = 0,
        .supports_plaid = 1,
        .best_for = "Zero-fee standard business ACH transactions",
        .connection_method = "Plaid instant link to online banking credentials"
    },
    [PLATFORM_MOOV] = {
        .name = "moov",
        .display_name = "Moov",
        .api_base_url = "https://api.moov.io/v1",
        .docs_url = "https://docs.moov.io",
        .monthly_fee = 0.00,
        .ach_pct = 0.00,  /* pure pay-as-you-go, varies */
        .ach_flat = 0.00,
        .ach_cap = 0.00,
        .ach_min = 0.00,
        .card_pct = 0.00,
        .card_flat = 0.00,
        .supports_ach = 1,
        .supports_card = 0,
        .supports_fednow = 1,
        .supports_rtp = 1,
        .supports_plaid = 0,
        .best_for = "API-first automated or per-use software integrations",
        .connection_method = "Developer API for two-legged standard and same-day FedNow/RTP settlement"
    },
    [PLATFORM_STRIPE] = {
        .name = "stripe",
        .display_name = "Stripe",
        .api_base_url = "https://api.stripe.com/v1",
        .docs_url = "https://stripe.com/docs/ach",
        .monthly_fee = 0.00,
        .ach_pct = 0.80,
        .ach_flat = 0.00,
        .ach_cap = 5.00,
        .ach_min = 0.00,
        .card_pct = 2.90,
        .card_flat = 0.30,
        .supports_ach = 1,
        .supports_card = 1,
        .supports_fednow = 0,
        .supports_rtp = 0,
        .supports_plaid = 1,
        .best_for = "E-commerce web checkouts, custom code integrations, international currencies",
        .connection_method = "API key + Plaid for bank verification"
    },
    [PLATFORM_SQUARE] = {
        .name = "square",
        .display_name = "Square",
        .api_base_url = "https://connect.squareup.com/v2",
        .docs_url = "https://developer.squareup.com/docs/payments-api",
        .monthly_fee = 0.00,
        .ach_pct = 1.00,
        .ach_flat = 0.00,
        .ach_cap = 0.00,
        .ach_min = 1.00,
        .card_pct = 2.90,
        .card_flat = 0.30,
        .supports_ach = 1,
        .supports_card = 1,
        .supports_fednow = 0,
        .supports_rtp = 0,
        .supports_plaid = 0,
        .best_for = "Quick invoice links, easy virtual terminals, immediate day-after payouts",
        .connection_method = "OAuth application credentials + bank account on file"
    },
    [PLATFORM_HELCIM] = {
        .name = "helcim",
        .display_name = "Helcim",
        .api_base_url = "https://api.helcim.com/v2",
        .docs_url = "https://devdocs.helcim.com",
        .monthly_fee = 0.00,
        .ach_pct = 0.50,
        .ach_flat = 0.25,
        .ach_cap = 6.00,
        .ach_min = 0.00,
        .card_pct = 2.27,
        .card_flat = 0.25,
        .supports_ach = 1,
        .supports_card = 1,
        .supports_fednow = 0,
        .supports_rtp = 0,
        .supports_plaid = 0,
        .best_for = "Wholesale, B2B invoicing, automated surcharging to pass fees to customer",
        .connection_method = "API token + merchant account"
    }
};

/* ═══════════════════════════════════════════════════════════════════════
   Transfer request structure
   ═══════════════════════════════════════════════════════════════════════ */

typedef struct {
    Platform       platform;
    PaymentMethod  method;
    TransferSpeed  speed;
    char           routing_number[10];   /* 9-digit ABA routing */
    char           account_number[18];   /* up to 17 digits */
    char           account_name[128];    /* beneficiary name */
    double         amount;               /* USD */
    char           memo[256];            /* payment memo */
    char           idempotency_key[64];  /* prevents duplicates */
    char           api_key[256];         /* platform API key */
    char           reference[64];        /* returned transaction ID */
} TransferRequest;

/* ═══════════════════════════════════════════════════════════════════════
   CURL response buffer
   ═══════════════════════════════════════════════════════════════════════ */

typedef struct {
    char   *data;
    size_t  size;
} ResponseBuffer;

static size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb;
    ResponseBuffer *buf = (ResponseBuffer *)userp;
    char *ptr = realloc(buf->data, buf->size + realsize + 1);
    if (!ptr) return 0;
    buf->data = ptr;
    memcpy(&(buf->data[buf->size]), contents, realsize);
    buf->size += realsize;
    buf->data[buf->size] = '\0';
    return realsize;
}

/* ═══════════════════════════════════════════════════════════════════════
   Database
   ═══════════════════════════════════════════════════════════════════════ */

static MYSQL *db_connect(void)
{
    MYSQL *conn = mysql_init(NULL);
    if (!conn) { fprintf(stderr, "MySQL init failed\n"); return NULL; }
    if (!mysql_real_connect(conn, DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT, NULL, 0)) {
        MYSQL *root = mysql_init(NULL);
        if (root && mysql_real_connect(root, DB_HOST, DB_USER, DB_PASS, NULL, DB_PORT, NULL, 0)) {
            mysql_query(root, "CREATE DATABASE IF NOT EXISTS nwe_fiduciary CHARACTER SET utf8mb4");
            mysql_close(root);
            if (mysql_real_connect(conn, DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT, NULL, 0))
                return conn;
        }
        fprintf(stderr, "MySQL connect failed: %s\n", mysql_error(conn));
        mysql_close(conn);
        return NULL;
    }
    return conn;
}

static void create_ach_tables(MYSQL *conn)
{
    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS ach_platforms ("
        "  id INT AUTO_INCREMENT PRIMARY KEY,"
        "  name VARCHAR(32) NOT NULL UNIQUE,"
        "  display_name VARCHAR(64),"
        "  api_base_url VARCHAR(256),"
        "  api_key_encrypted BLOB,"
        "  monthly_fee DECIMAL(10,2) DEFAULT 0.00,"
        "  ach_pct DECIMAL(5,3) DEFAULT 0.000,"
        "  ach_flat DECIMAL(5,2) DEFAULT 0.00,"
        "  ach_cap DECIMAL(10,2) DEFAULT 0.00,"
        "  card_pct DECIMAL(5,3) DEFAULT 0.000,"
        "  card_flat DECIMAL(5,2) DEFAULT 0.00,"
        "  supports_ach TINYINT DEFAULT 1,"
        "  supports_card TINYINT DEFAULT 0,"
        "  supports_fednow TINYINT DEFAULT 0,"
        "  supports_rtp TINYINT DEFAULT 0,"
        "  best_for TEXT,"
        "  active TINYINT DEFAULT 1,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  INDEX idx_name (name)"
        ") ENGINE=InnoDB");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS ach_accounts ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  label VARCHAR(128) NOT NULL,"
        "  routing_number VARCHAR(9) NOT NULL,"
        "  account_number_encrypted BLOB NOT NULL,"
        "  account_type ENUM('checking','savings') DEFAULT 'checking',"
        "  beneficiary_name VARCHAR(256),"
        "  bank_name VARCHAR(128),"
        "  verified TINYINT DEFAULT 0,"
        "  verification_method VARCHAR(32),"
        "  platform VARCHAR(32),"
        "  platform_account_id VARCHAR(128),"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  last_used_at TIMESTAMP NULL,"
        "  INDEX idx_label (label),"
        "  INDEX idx_routing (routing_number)"
        ") ENGINE=InnoDB");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS ach_transfers ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  platform VARCHAR(32) NOT NULL,"
        "  method ENUM('ach','card','fednow','rtp') NOT NULL DEFAULT 'ach',"
        "  speed ENUM('standard','same_day','instant') NOT NULL DEFAULT 'standard',"
        "  direction ENUM('send','receive') NOT NULL DEFAULT 'send',"
        "  amount DECIMAL(12,2) NOT NULL,"
        "  currency VARCHAR(3) DEFAULT 'USD',"
        "  fee_amount DECIMAL(10,2) DEFAULT 0.00,"
        "  fee_calculation TEXT,"
        "  routing_number VARCHAR(9),"
        "  account_id BIGINT,"
        "  beneficiary_name VARCHAR(256),"
        "  memo VARCHAR(256),"
        "  idempotency_key VARCHAR(64),"
        "  platform_reference VARCHAR(128),"
        "  status ENUM('pending','processing','completed','failed','returned') DEFAULT 'pending',"
        "  error_message TEXT,"
        "  initiated_by VARCHAR(64),"
        "  initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  completed_at TIMESTAMP NULL,"
        "  INDEX idx_platform (platform),"
        "  INDEX idx_status (status),"
        "  INDEX idx_reference (platform_reference),"
        "  INDEX idx_idempotency (idempotency_key)"
        ") ENGINE=InnoDB");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS ach_audit_log ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  transfer_id BIGINT,"
        "  event_type VARCHAR(32) NOT NULL,"
        "  event_detail TEXT,"
        "  event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  actor VARCHAR(64),"
        "  INDEX idx_transfer (transfer_id),"
        "  INDEX idx_event_time (event_time)"
        ") ENGINE=InnoDB");
}

/* ═══════════════════════════════════════════════════════════════════════
   Fee Calculation
   ═══════════════════════════════════════════════════════════════════════ */

typedef struct {
    double fee;
    char   breakdown[256];
} FeeResult;

static FeeResult calculate_fee(Platform platform, PaymentMethod method, double amount)
{
    FeeResult result = { .fee = 0.0 };
    const PlatformInfo *p = &platforms[platform];

    if (method == METHOD_ACH || method == METHOD_FEDNOW || method == METHOD_RTP) {
        double pct_fee = amount * (p->ach_pct / 100.0);
        double total = pct_fee + p->ach_flat;

        /* Apply cap */
        if (p->ach_cap > 0.0 && total > p->ach_cap)
            total = p->ach_cap;

        /* Apply minimum */
        if (p->ach_min > 0.0 && total < p->ach_min)
            total = p->ach_min;

        /* Melio same-day is 1% */
        if (platform == PLATFORM_MELIO && method == METHOD_ACH) {
            /* standard is free; same-day handled by caller */
            total = 0.0;
        }

        result.fee = total;
        snprintf(result.breakdown, sizeof(result.breakdown),
            "ACH: %.3f%% + $%.2f (cap: $%.2f, min: $%.2f) = $%.2f",
            p->ach_pct, p->ach_flat, p->ach_cap, p->ach_min, total);
    }
    else if (method == METHOD_CARD) {
        double total = amount * (p->card_pct / 100.0) + p->card_flat;
        result.fee = total;
        snprintf(result.breakdown, sizeof(result.breakdown),
            "Card: %.2f%% + $%.2f = $%.2f",
            p->card_pct, p->card_flat, total);
    }

    return result;
}

static FeeResult calculate_melio_same_day(double amount)
{
    FeeResult result;
    result.fee = amount * 0.01;  /* 1% for same-day */
    snprintf(result.breakdown, sizeof(result.breakdown),
        "Melio same-day ACH: 1.0%% of $%.2f = $%.2f", amount, result.fee);
    return result;
}

/* ═══════════════════════════════════════════════════════════════════════
   Routing Number Validation (ABA checksum)
   ═══════════════════════════════════════════════════════════════════════ */

static int validate_routing_number(const char *routing)
{
    if (strlen(routing) != 9) return 0;
    for (int i = 0; i < 9; i++) {
        if (!isdigit((unsigned char)routing[i])) return 0;
    }

    /* ABA checksum: 3(d1 + d4 + d7) + 7(d2 + d5 + d8) + (d3 + d6 + d9) mod 10 == 0 */
    int weights[] = {3, 7, 1, 3, 7, 1, 3, 7, 1};
    int sum = 0;
    for (int i = 0; i < 9; i++)
        sum += (routing[i] - '0') * weights[i];

    return (sum % 10) == 0;
}

/* ═══════════════════════════════════════════════════════════════════════
   Generate idempotency key
   ═══════════════════════════════════════════════════════════════════════ */

static void generate_idempotency_key(char *buf, size_t len)
{
    const char charset[] = "abcdefghijklmnopqrstuvwxyz0123456789";
    srand((unsigned int)time(NULL) ^ (unsigned int)getpid());
    snprintf(buf, 6, "ach_");
    for (size_t i = 4; i < len - 1 && i < 36; i++)
        buf[i] = charset[rand() % (sizeof(charset) - 1)];
    buf[len > 36 ? 36 : len - 1] = '\0';
}

/* ═══════════════════════════════════════════════════════════════════════
   Platform API Calls (libcurl)
   ═══════════════════════════════════════════════════════════════════════ */

static int api_call(const char *url, const char *method, const char *api_key,
                    const char *body, ResponseBuffer *response)
{
    CURL *curl = curl_easy_init();
    if (!curl) return -1;

    response->data = malloc(1);
    response->size = 0;
    response->data[0] = '\0';

    struct curl_slist *headers = NULL;
    char auth_header[MAX_HEADER];
    snprintf(auth_header, sizeof(auth_header), "Authorization: Bearer %s", api_key);
    headers = curl_slist_append(headers, auth_header);
    headers = curl_slist_append(headers, "Content-Type: application/json");
    headers = curl_slist_append(headers, "Accept: application/json");

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)response);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);

    if (strcmp(method, "POST") == 0) {
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        if (body) curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
    }

    CURLcode res = curl_easy_perform(curl);
    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);

    if (res != CURLE_OK) {
        fprintf(stderr, C_RED "  CURL error: %s\n" C_RESET, curl_easy_strerror(res));
        return -1;
    }

    return (int)http_code;
}

/* ═══════════════════════════════════════════════════════════════════════
   Platform-specific transfer initiation
   ═══════════════════════════════════════════════════════════════════════ */

static int initiate_stripe_ach(TransferRequest *req, ResponseBuffer *response)
{
    char url[MAX_URL];
    snprintf(url, sizeof(url), "%s/payment_intents", platforms[PLATFORM_STRIPE].api_base_url);

    int amount_cents = (int)(req->amount * 100);
    char body[MAX_BODY];
    snprintf(body, sizeof(body),
        "{"
        "  \"amount\": %d,"
        "  \"currency\": \"usd\","
        "  \"payment_method_types\": [\"us_bank_account\"],"
        "  \"payment_method_data\": {"
        "    \"type\": \"us_bank_account\","
        "    \"us_bank_account\": {"
        "      \"routing_number\": \"%s\","
        "      \"account_number\": \"%s\","
        "      \"account_holder_type\": \"individual\""
        "    }"
        "  },"
        "  \"metadata\": {"
        "    \"memo\": \"%s\","
        "    \"idempotency_key\": \"%s\""
        "  }"
        "}",
        amount_cents, req->routing_number, req->account_number,
        req->memo, req->idempotency_key);

    return api_call(url, "POST", req->api_key, body, response);
}

static int initiate_moov_ach(TransferRequest *req, ResponseBuffer *response)
{
    char url[MAX_URL];
    snprintf(url, sizeof(url), "%s/transfers", platforms[PLATFORM_MOOV].api_base_url);

    char body[MAX_BODY];
    snprintf(body, sizeof(body),
        "{"
        "  \"amount\": {"
        "    \"value\": %.0f,"
        "    \"currency\": \"USD\""
        "  },"
        "  \"destination\": {"
        "    \"paymentMethodType\": \"ach-debit-fund\","
        "    \"ach\": {"
        "      \"routingNumber\": \"%s\","
        "      \"accountNumber\": \"%s\""
        "    }"
        "  },"
        "  \"description\": \"%s\""
        "}",
        req->amount * 100, req->routing_number, req->account_number, req->memo);

    return api_call(url, "POST", req->api_key, body, response);
}

static int initiate_square_ach(TransferRequest *req, ResponseBuffer *response)
{
    char url[MAX_URL];
    snprintf(url, sizeof(url), "%s/payments", platforms[PLATFORM_SQUARE].api_base_url);

    int amount_cents = (int)(req->amount * 100);
    char body[MAX_BODY];
    snprintf(body, sizeof(body),
        "{"
        "  \"source_id\": \"EXTERNAL\","
        "  \"idempotency_key\": \"%s\","
        "  \"amount_money\": {"
        "    \"amount\": %d,"
        "    \"currency\": \"USD\""
        "  },"
        "  \"bank_account_details\": {"
        "    \"routing_number\": \"%s\","
        "    \"account_number\": \"%s\""
        "  },"
        "  \"note\": \"%s\""
        "}",
        req->idempotency_key, amount_cents,
        req->routing_number, req->account_number, req->memo);

    return api_call(url, "POST", req->api_key, body, response);
}

static int initiate_helcim_ach(TransferRequest *req, ResponseBuffer *response)
{
    char url[MAX_URL];
    snprintf(url, sizeof(url), "%s/payment/purchase", platforms[PLATFORM_HELCIM].api_base_url);

    char body[MAX_BODY];
    snprintf(body, sizeof(body),
        "{"
        "  \"paymentType\": \"ach\","
        "  \"amount\": %.2f,"
        "  \"currency\": \"USD\","
        "  \"bankAccount\": {"
        "    \"routingNumber\": \"%s\","
        "    \"accountNumber\": \"%s\","
        "    \"accountType\": \"checking\""
        "  },"
        "  \"idempotencyKey\": \"%s\""
        "}",
        req->amount, req->routing_number, req->account_number, req->idempotency_key);

    return api_call(url, "POST", req->api_key, body, response);
}

static int initiate_melio_ach(TransferRequest *req, ResponseBuffer *response)
{
    char url[MAX_URL];
    snprintf(url, sizeof(url), "%s/payments", platforms[PLATFORM_MELIO].api_base_url);

    char body[MAX_BODY];
    snprintf(body, sizeof(body),
        "{"
        "  \"amount\": %.2f,"
        "  \"currency\": \"USD\","
        "  \"deliveryMethod\": \"%s\","
        "  \"vendorBankAccount\": {"
        "    \"routingNumber\": \"%s\","
        "    \"accountNumber\": \"%s\""
        "  },"
        "  \"memo\": \"%s\""
        "}",
        req->amount,
        req->speed == SPEED_SAME_DAY ? "expedited-ach" : "ach",
        req->routing_number, req->account_number, req->memo);

    return api_call(url, "POST", req->api_key, body, response);
}

/* ═══════════════════════════════════════════════════════════════════════
   Transfer execution (dispatches to platform)
   ═══════════════════════════════════════════════════════════════════════ */

static int execute_transfer(MYSQL *conn, TransferRequest *req)
{
    /* Validate routing number */
    if (!validate_routing_number(req->routing_number)) {
        fprintf(stderr, C_RED "  ✗ Invalid routing number: %s (ABA checksum failed)\n" C_RESET,
                req->routing_number);
        return -1;
    }

    /* Generate idempotency key if not provided */
    if (req->idempotency_key[0] == '\0')
        generate_idempotency_key(req->idempotency_key, sizeof(req->idempotency_key));

    /* Calculate fee */
    FeeResult fee;
    if (req->platform == PLATFORM_MELIO && req->speed == SPEED_SAME_DAY)
        fee = calculate_melio_same_day(req->amount);
    else
        fee = calculate_fee(req->platform, req->method, req->amount);

    printf(C_LTBLUE "\n  ╔══════════════════════════════════════════════════════╗\n");
    printf("  ║  ACH Transfer — %s", platforms[req->platform].display_name);
    printf("%*s║\n", (int)(38 - strlen(platforms[req->platform].display_name)), "");
    printf("  ╠══════════════════════════════════════════════════════╣\n");
    printf("  ║  Amount:   $%.2f USD%*s║\n", req->amount, (int)(33 - snprintf(NULL, 0, "%.2f", req->amount)), "");
    printf("  ║  Fee:      $%.2f%*s║\n", fee.fee, (int)(38 - snprintf(NULL, 0, "%.2f", fee.fee)), "");
    printf("  ║  Total:    $%.2f%*s║\n", req->amount + fee.fee, (int)(38 - snprintf(NULL, 0, "%.2f", req->amount + fee.fee)), "");
    printf("  ║  Routing:  %s%*s║\n", req->routing_number, (int)(38 - (int)strlen(req->routing_number)), "");
    printf("  ║  Account:  ****%s%*s║\n",
        req->account_number + (strlen(req->account_number) > 4 ? strlen(req->account_number) - 4 : 0),
        34, "");
    printf("  ║  Speed:    %s%*s║\n",
        req->speed == SPEED_SAME_DAY ? "Same-Day" : req->speed == SPEED_INSTANT ? "Instant" : "Standard",
        req->speed == SPEED_SAME_DAY ? 30 : req->speed == SPEED_INSTANT ? 31 : 30, "");
    printf("  ╚══════════════════════════════════════════════════════╝\n" C_RESET);
    printf("  %s\n\n", fee.breakdown);

    /* Record in database */
    char escaped_memo[512];
    mysql_real_escape_string(conn, escaped_memo, req->memo, strlen(req->memo));

    char query[2048];
    snprintf(query, sizeof(query),
        "INSERT INTO ach_transfers (platform, method, speed, direction, amount, fee_amount, "
        "fee_calculation, routing_number, beneficiary_name, memo, idempotency_key, status, initiated_by) "
        "VALUES ('%s', 'ach', '%s', 'send', %.2f, %.2f, '%s', '%s', '%s', '%s', '%s', 'pending', '%s')",
        platforms[req->platform].name,
        req->speed == SPEED_SAME_DAY ? "same_day" : req->speed == SPEED_INSTANT ? "instant" : "standard",
        req->amount, fee.fee, fee.breakdown,
        req->routing_number, req->account_name, escaped_memo,
        req->idempotency_key,
        getenv("USER") ? getenv("USER") : "system");

    mysql_query(conn, query);
    unsigned long long transfer_id = mysql_insert_id(conn);

    /* Execute API call */
    ResponseBuffer response = { .data = NULL, .size = 0 };
    int http_code = -1;

    switch (req->platform) {
        case PLATFORM_STRIPE: http_code = initiate_stripe_ach(req, &response); break;
        case PLATFORM_MOOV:   http_code = initiate_moov_ach(req, &response);   break;
        case PLATFORM_SQUARE: http_code = initiate_square_ach(req, &response); break;
        case PLATFORM_HELCIM: http_code = initiate_helcim_ach(req, &response); break;
        case PLATFORM_MELIO:  http_code = initiate_melio_ach(req, &response);  break;
        default: break;
    }

    /* Update status based on response */
    const char *status = "pending";
    if (http_code >= 200 && http_code < 300) {
        status = "processing";
        printf(C_GREEN "  ✓ Transfer initiated successfully (HTTP %d)\n" C_RESET, http_code);
        printf(C_DIM "    Reference: %s\n" C_RESET, req->idempotency_key);
    } else if (http_code > 0) {
        status = "failed";
        printf(C_RED "  ✗ Transfer failed (HTTP %d)\n" C_RESET, http_code);
        if (response.data)
            printf(C_DIM "    Response: %.200s\n" C_RESET, response.data);
    } else {
        printf(C_GOLD "  ⚠ Transfer queued (API unreachable, will retry)\n" C_RESET);
    }

    /* Update DB record */
    snprintf(query, sizeof(query),
        "UPDATE ach_transfers SET status='%s', platform_reference='%s' WHERE id=%llu",
        status, req->idempotency_key, transfer_id);
    mysql_query(conn, query);

    /* Audit log */
    snprintf(query, sizeof(query),
        "INSERT INTO ach_audit_log (transfer_id, event_type, event_detail, actor) "
        "VALUES (%llu, 'initiated', 'HTTP %d via %s API', '%s')",
        transfer_id, http_code, platforms[req->platform].name,
        getenv("USER") ? getenv("USER") : "system");
    mysql_query(conn, query);

    if (response.data) free(response.data);
    return http_code >= 200 && http_code < 300 ? 0 : -1;
}

/* ═══════════════════════════════════════════════════════════════════════
   Display functions
   ═══════════════════════════════════════════════════════════════════════ */

static void print_banner(void)
{
    printf(C_LTBLUE "\n");
    printf("  ┌────────────────────────────────────────────────────────────┐\n");
    printf("  │" C_WHITE "  ACH Transfer — FiduciaryServices™ Payment API v%s  " C_LTBLUE "│\n", VERSION);
    printf("  │" C_DIM "  Bank-to-bank transfers via Melio, Moov, Stripe,         " C_LTBLUE "│\n");
    printf("  │" C_DIM "  Square, and Helcim. Pay-as-you-go. No monthly fees.     " C_LTBLUE "│\n");
    printf("  └────────────────────────────────────────────────────────────┘\n");
    printf(C_RESET "\n");
}

static void list_platforms(void)
{
    print_banner();

    printf(C_GOLD "  ═══ PAY-AS-YOU-GO ACH PLATFORMS (No Monthly Fees) ═══\n\n" C_RESET);

    printf(C_WHITE "  Melio" C_RESET " — %s\n", platforms[PLATFORM_MELIO].best_for);
    printf("    Cost: Standard ACH is " C_GREEN "100%% FREE" C_RESET
           ". Same-day expedited: 1%% fee.\n");
    printf("    Connection: %s\n", platforms[PLATFORM_MELIO].connection_method);
    printf("    Docs: %s\n\n", platforms[PLATFORM_MELIO].docs_url);

    printf(C_WHITE "  Moov" C_RESET " — %s\n", platforms[PLATFORM_MOOV].best_for);
    printf("    Cost: Pure " C_GREEN "pay-as-you-go" C_RESET
           " pricing, no monthly base fees.\n");
    printf("    Connection: %s\n", platforms[PLATFORM_MOOV].connection_method);
    printf("    Supports: ACH + " C_CYAN "FedNow" C_RESET " + " C_CYAN "RTP" C_RESET
           " settlement windows.\n");
    printf("    Docs: %s\n\n", platforms[PLATFORM_MOOV].docs_url);

    printf(C_GOLD "  ═══ HYBRID PROCESSORS (Credit Card + ACH, $0/mo) ═══\n\n" C_RESET);

    printf("  %-10s %-8s %-22s %-22s %s\n",
        "Provider", "Monthly", "ACH Per-Use", "Card Online", "Best For");
    printf("  %-10s %-8s %-22s %-22s %s\n",
        "────────", "───────", "──────────────────────", "──────────────────────", "────────────────────");

    printf("  %-10s " C_GREEN "$0" C_RESET "%6s %-22s %-22s %s\n",
        "Stripe", "", "0.8% (cap $5)", "2.9% + $0.30",
        "E-commerce, custom code, intl currencies");
    printf("  %-10s " C_GREEN "$0" C_RESET "%6s %-22s %-22s %s\n",
        "Square", "", "1% (min $1)", "2.9% + $0.30",
        "Invoices, virtual terminals, quick payouts");
    printf("  %-10s " C_GREEN "$0" C_RESET "%6s %-22s %-22s %s\n",
        "Helcim", "", "0.5% + $0.25 (cap $6)", "~2.27% + $0.25 (I+)",
        "B2B invoicing, automated surcharging");

    printf("\n");
}

static void print_fee_estimate(Platform platform, PaymentMethod method, double amount)
{
    FeeResult fee;
    if (platform == PLATFORM_MELIO && method == METHOD_ACH) {
        printf(C_LTBLUE "\n  Fee Estimate — Melio\n" C_RESET);
        printf("    Standard ACH: " C_GREEN "$0.00 (FREE)" C_RESET "\n");
        fee = calculate_melio_same_day(amount);
        printf("    Same-Day ACH: $%.2f (1%%)\n", fee.fee);
    } else {
        fee = calculate_fee(platform, method, amount);
        printf(C_LTBLUE "\n  Fee Estimate — %s (%s)\n" C_RESET,
            platforms[platform].display_name,
            method == METHOD_CARD ? "Card" : "ACH");
        printf("    Amount: $%.2f\n", amount);
        printf("    Fee:    $%.2f\n", fee.fee);
        printf("    Total:  $%.2f\n", amount + fee.fee);
        printf("    %s\n", fee.breakdown);
    }
    printf("\n");
}

static void print_status(MYSQL *conn, const char *reference)
{
    char escaped[128];
    mysql_real_escape_string(conn, escaped, reference, strlen(reference));
    char query[512];
    snprintf(query, sizeof(query),
        "SELECT id, platform, method, speed, amount, fee_amount, status, "
        "beneficiary_name, initiated_at, completed_at, platform_reference "
        "FROM ach_transfers WHERE idempotency_key='%s' OR platform_reference='%s' "
        "ORDER BY initiated_at DESC LIMIT 1",
        escaped, escaped);

    if (mysql_query(conn, query) == 0) {
        MYSQL_RES *res = mysql_store_result(conn);
        if (res) {
            MYSQL_ROW row = mysql_fetch_row(res);
            if (row) {
                printf(C_LTBLUE "\n  Transfer Status\n" C_RESET);
                printf("    ID:         %s\n", row[0]);
                printf("    Platform:   %s\n", row[1]);
                printf("    Method:     %s\n", row[2]);
                printf("    Speed:      %s\n", row[3]);
                printf("    Amount:     $%s\n", row[4]);
                printf("    Fee:        $%s\n", row[5]);
                printf("    Status:     %s%s%s\n",
                    strcmp(row[6], "completed") == 0 ? C_GREEN :
                    strcmp(row[6], "failed") == 0 ? C_RED : C_GOLD,
                    row[6], C_RESET);
                printf("    Beneficiary: %s\n", row[7] ? row[7] : "—");
                printf("    Initiated:  %s\n", row[8]);
                if (row[9]) printf("    Completed:  %s\n", row[9]);
                printf("    Reference:  %s\n", row[10] ? row[10] : "—");
            } else {
                printf(C_RED "  ✗ No transfer found for reference: %s\n" C_RESET, reference);
            }
            mysql_free_result(res);
        }
    }
    printf("\n");
}

static void print_usage(void)
{
    printf("\n  Usage:\n");
    printf("    ach_transfer --platform <name> --to <routing:account> --amount <USD>\n");
    printf("                 [--method ach|card] [--speed standard|same-day|instant]\n");
    printf("                 [--memo \"Payment note\"] [--name \"Beneficiary\"]\n");
    printf("                 [--api-key <key>]\n\n");
    printf("    ach_transfer --list-platforms\n");
    printf("    ach_transfer --fee-estimate --platform <name> --amount <USD> [--method ach|card]\n");
    printf("    ach_transfer --status --reference <txn_id>\n");
    printf("    ach_transfer --history [--limit N]\n");
    printf("    ach_transfer --ports\n");
    printf("    ach_transfer --nat <platform>\n\n");
    printf("  Platforms: melio, moov, stripe, square, helcim\n\n");
    printf("  Outbound Connectivity:\n");
    printf("    --ports            Show permitted outbound ports and NAT awareness\n");
    printf("    --nat <platform>   Explain return-path strategy for a platform\n\n");
    printf("  Examples:\n");
    printf("    ach_transfer --platform melio --to 021000021:123456789 --amount 500.00\n");
    printf("    ach_transfer --platform stripe --to 021000021:123456789 --amount 1000 --method ach\n");
    printf("    ach_transfer --platform moov --to 021000021:123456789 --amount 250 --speed same-day\n");
    printf("    ach_transfer --fee-estimate --platform helcim --amount 5000 --method card\n");
    printf("    ach_transfer --nat stripe\n");
    printf("\n");
}

static void print_history(MYSQL *conn, int limit)
{
    char query[256];
    snprintf(query, sizeof(query),
        "SELECT id, platform, amount, fee_amount, status, initiated_at, beneficiary_name "
        "FROM ach_transfers ORDER BY initiated_at DESC LIMIT %d", limit);

    if (mysql_query(conn, query) != 0) return;
    MYSQL_RES *res = mysql_store_result(conn);
    if (!res) return;

    printf(C_LTBLUE "\n  Transfer History (last %d)\n" C_RESET, limit);
    printf("  %-6s %-8s %-10s %-8s %-12s %-20s %s\n",
        "ID", "Platform", "Amount", "Fee", "Status", "Date", "Beneficiary");
    printf("  %-6s %-8s %-10s %-8s %-12s %-20s %s\n",
        "──────", "────────", "──────────", "────────", "────────────", "────────────────────", "───────────");

    MYSQL_ROW row;
    while ((row = mysql_fetch_row(res))) {
        printf("  %-6s %-8s $%-9s $%-7s %s%-12s%s %-20s %s\n",
            row[0], row[1], row[2], row[3],
            strcmp(row[4], "completed") == 0 ? C_GREEN :
            strcmp(row[4], "failed") == 0 ? C_RED : C_GOLD,
            row[4], C_RESET, row[5], row[6] ? row[6] : "—");
    }
    mysql_free_result(res);
    printf("\n");
}

/* ═══════════════════════════════════════════════════════════════════════
   Main
   ═══════════════════════════════════════════════════════════════════════ */

static Platform parse_platform(const char *name)
{
    if (strcasecmp(name, "melio") == 0) return PLATFORM_MELIO;
    if (strcasecmp(name, "moov") == 0) return PLATFORM_MOOV;
    if (strcasecmp(name, "stripe") == 0) return PLATFORM_STRIPE;
    if (strcasecmp(name, "square") == 0) return PLATFORM_SQUARE;
    if (strcasecmp(name, "helcim") == 0) return PLATFORM_HELCIM;
    return PLATFORM_COUNT; /* invalid */
}

/* ═══════════════════════════════════════════════════════════════════════
   Outbound Ports & NAT Strategy
   ═══════════════════════════════════════════════════════════════════════ */

static void print_outbound_ports(void)
{
    printf(C_LTBLUE "\n  ╔══════════════════════════════════════════════════════════════════════╗\n");
    printf("  ║  OUTBOUND PORT MANIFEST — FiduciaryServices™                        ║\n");
    printf("  ╠══════════════════════════════════════════════════════════════════════╣\n");
    printf("  ║                                                                      ║\n");
    printf("  ║  Port   Protocol      Purpose                                        ║\n");
    printf("  ║  ─────  ────────────  ───────────────────────────────────────────    ║\n");
    printf("  ║  20     FTP Data      File transfer (active mode data channel)       ║\n");
    printf("  ║  21     FTP Control   File transfer (command channel)                ║\n");
    printf("  ║  22     SSH           Secure shell, SFTP, tunnel establishment       ║\n");
    printf("  ║  25     SMTP          Email relay (ISPs may block; use 587)          ║\n");
    printf("  ║  80     HTTP          Plaintext web (→ redirect to 443 typical)      ║\n");
    printf("  ║  443    HTTPS         Encrypted web, API calls, payment platforms    ║\n");
    printf("  ║  465    SMTPS         SMTP over implicit TLS (submission)            ║\n");
    printf("  ║  587    SMTP Sub      SMTP with STARTTLS (authenticated mail send)   ║\n");
    printf("  ║  8080   HTTP Alt      Application servers, proxies, dev endpoints    ║\n");
    printf("  ║  8443   HTTPS Alt     Application servers over TLS, admin panels     ║\n");
    printf("  ║                                                                      ║\n");
    printf("  ╠══════════════════════════════════════════════════════════════════════╣\n");
    printf("  ║  NAT AWARENESS:                                                      ║\n");
    printf("  ║  • Outbound ports are OPEN by default on home internet               ║\n");
    printf("  ║  • Inbound ports are BLOCKED by NAT (router)                         ║\n");
    printf("  ║  • Return packets work via NAT table mapping (auto, 60-300s TTL)     ║\n");
    printf("  ║  • Keepalive every 45s prevents NAT expiry on persistent conns       ║\n");
    printf("  ║  • ISPs commonly block outbound port 25 (use 587/465 for email)      ║\n");
    printf("  ╚══════════════════════════════════════════════════════════════════════╝\n" C_RESET);
    printf("\n");
    printf(C_DIM "  TLS/SSL Intelligence: Fiduciary captures public key, cipher suite, cert chain,\n");
    printf("  key exchange method (ECDHE/DHE/RSA), and certificate fingerprint for every\n");
    printf("  outbound HTTPS connection. Key changes are detected (fiduciary hold).\n" C_RESET);
    printf("\n");
}

static void print_nat_strategy(const char *platform_name)
{
    printf(C_LTBLUE "\n  NAT Return-Path Strategy — %s\n" C_RESET, platform_name);
    printf("  ────────────────────────────────────────────────────────────────\n\n");

    printf("  " C_WHITE "Problem:" C_RESET " Most home internet is behind NAT.\n");
    printf("    • Outbound 80/443/587 are open (we connect TO payment APIs)\n");
    printf("    • Inbound ports are CLOSED (APIs cannot connect back to us)\n");
    printf("    • NAT table maps return packets for active connections only\n");
    printf("    • NAT entries expire after 60-300s of inactivity\n\n");

    if (strcasecmp(platform_name, "stripe") == 0) {
        printf("  " C_GREEN "Strategy: PERSISTENT OUTBOUND" C_RESET "\n");
        printf("    Stripe supports server-sent events and long-poll on /v1/events.\n");
        printf("    Maintain a persistent TLS connection to api.stripe.com:443.\n");
        printf("    Send TCP keepalive every 45s to prevent NAT table expiry.\n");
        printf("    All transfer status updates arrive on this persistent channel.\n");
        printf("    No inbound port required.\n");
    } else if (strcasecmp(platform_name, "moov") == 0) {
        printf("  " C_GREEN "Strategy: PERSISTENT OUTBOUND" C_RESET "\n");
        printf("    Moov has streaming API and supports webhook-via-websocket.\n");
        printf("    Maintain a persistent TLS/WebSocket to api.moov.io:443.\n");
        printf("    FedNow/RTP settlement confirmations arrive via this stream.\n");
        printf("    TCP keepalive every 45s. No inbound port required.\n");
    } else if (strcasecmp(platform_name, "melio") == 0) {
        printf("  " C_GOLD "Strategy: WEBHOOK RELAY" C_RESET "\n");
        printf("    Melio requires a webhook URL for payment status callbacks.\n");
        printf("    Register relay.mearvk.us as webhook endpoint with Melio.\n");
        printf("    Relay has a public IP and accepts callbacks from Melio.\n");
        printf("    We maintain persistent outbound TLS to relay.mearvk.us:443.\n");
        printf("    When Melio POSTs to relay, relay forwards to us on our\n");
        printf("    already-open outbound connection. No inbound port needed.\n");
    } else if (strcasecmp(platform_name, "helcim") == 0) {
        printf("  " C_GOLD "Strategy: WEBHOOK RELAY" C_RESET "\n");
        printf("    Helcim requires a webhook URL for transaction notifications.\n");
        printf("    Same relay pattern as Melio: relay.mearvk.us forwards events.\n");
        printf("    Persistent outbound TLS connection to relay handles delivery.\n");
    } else if (strcasecmp(platform_name, "square") == 0) {
        printf("  " C_CYAN "Strategy: POLLING" C_RESET "\n");
        printf("    Square — poll GET /v2/payments/{id} for status updates.\n");
        printf("    Poll every 15s during active transfers, 5min during idle.\n");
        printf("    Each poll is a fresh outbound HTTPS request to port 443.\n");
        printf("    Works universally, no inbound port or relay needed.\n");
    } else {
        printf("  " C_CYAN "Strategy: POLLING (default)" C_RESET "\n");
        printf("    Periodically query platform API for transfer status.\n");
        printf("    Active: every 15s. Idle: every 5min. Outbound port 443.\n");
    }

    printf("\n  " C_DIM "SSL/TLS: On each outbound connection, Fiduciary captures the server's\n");
    printf("  public key, certificate chain, cipher suite, and key exchange method.\n");
    printf("  If the public key changes unexpectedly → fiduciary hold BROKEN (alert).\n");
    printf("  Private keys are NEVER captured (impossible). Only public handshake data.\n" C_RESET);
    printf("\n");
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        print_banner();
        print_usage();
        return 0;
    }

    /* Parse arguments */
    int do_list = 0, do_fee = 0, do_status = 0, do_history = 0;
    int do_ports = 0, do_nat = 0;
    char nat_platform[32] = {0};
    TransferRequest req = {0};
    req.platform = PLATFORM_COUNT;
    req.method = METHOD_ACH;
    req.speed = SPEED_STANDARD;
    double fee_amount = 0.0;
    char reference[64] = {0};
    int history_limit = 20;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--list-platforms") == 0 || strcmp(argv[i], "-l") == 0) {
            do_list = 1;
        } else if (strcmp(argv[i], "--fee-estimate") == 0) {
            do_fee = 1;
        } else if (strcmp(argv[i], "--status") == 0) {
            do_status = 1;
        } else if (strcmp(argv[i], "--history") == 0) {
            do_history = 1;
        } else if (strcmp(argv[i], "--ports") == 0) {
            do_ports = 1;
        } else if (strcmp(argv[i], "--nat") == 0 && i + 1 < argc) {
            do_nat = 1;
            strncpy(nat_platform, argv[++i], sizeof(nat_platform) - 1);
        } else if (strcmp(argv[i], "--platform") == 0 && i + 1 < argc) {
            req.platform = parse_platform(argv[++i]);
        } else if (strcmp(argv[i], "--to") == 0 && i + 1 < argc) {
            i++;
            char *colon = strchr(argv[i], ':');
            if (colon) {
                size_t rlen = colon - argv[i];
                if (rlen < sizeof(req.routing_number)) {
                    strncpy(req.routing_number, argv[i], rlen);
                    req.routing_number[rlen] = '\0';
                }
                strncpy(req.account_number, colon + 1, sizeof(req.account_number) - 1);
            } else {
                fprintf(stderr, "Error: --to must be routing:account (e.g., 021000021:123456789)\n");
                return 1;
            }
        } else if (strcmp(argv[i], "--amount") == 0 && i + 1 < argc) {
            req.amount = atof(argv[++i]);
            fee_amount = req.amount;
        } else if (strcmp(argv[i], "--method") == 0 && i + 1 < argc) {
            i++;
            if (strcasecmp(argv[i], "card") == 0) req.method = METHOD_CARD;
            else if (strcasecmp(argv[i], "fednow") == 0) req.method = METHOD_FEDNOW;
            else if (strcasecmp(argv[i], "rtp") == 0) req.method = METHOD_RTP;
            else req.method = METHOD_ACH;
        } else if (strcmp(argv[i], "--speed") == 0 && i + 1 < argc) {
            i++;
            if (strcasecmp(argv[i], "same-day") == 0 || strcasecmp(argv[i], "sameday") == 0)
                req.speed = SPEED_SAME_DAY;
            else if (strcasecmp(argv[i], "instant") == 0)
                req.speed = SPEED_INSTANT;
            else
                req.speed = SPEED_STANDARD;
        } else if (strcmp(argv[i], "--memo") == 0 && i + 1 < argc) {
            strncpy(req.memo, argv[++i], sizeof(req.memo) - 1);
        } else if (strcmp(argv[i], "--name") == 0 && i + 1 < argc) {
            strncpy(req.account_name, argv[++i], sizeof(req.account_name) - 1);
        } else if (strcmp(argv[i], "--api-key") == 0 && i + 1 < argc) {
            strncpy(req.api_key, argv[++i], sizeof(req.api_key) - 1);
        } else if (strcmp(argv[i], "--reference") == 0 && i + 1 < argc) {
            strncpy(reference, argv[++i], sizeof(reference) - 1);
        } else if (strcmp(argv[i], "--limit") == 0 && i + 1 < argc) {
            history_limit = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            print_banner();
            print_usage();
            return 0;
        }
    }

    /* Handle list-platforms (no DB needed) */
    if (do_list) {
        list_platforms();
        return 0;
    }

    /* Handle outbound ports display (no DB needed) */
    if (do_ports) {
        print_outbound_ports();
        return 0;
    }

    /* Handle NAT strategy display (no DB needed) */
    if (do_nat) {
        print_nat_strategy(nat_platform);
        return 0;
    }

    /* Handle fee estimate (no DB needed) */
    if (do_fee) {
        if (req.platform == PLATFORM_COUNT) {
            fprintf(stderr, "Error: --platform required for fee estimate\n");
            return 1;
        }
        if (fee_amount <= 0.0) {
            fprintf(stderr, "Error: --amount required for fee estimate\n");
            return 1;
        }
        print_fee_estimate(req.platform, req.method, fee_amount);
        return 0;
    }

    /* Connect to DB for transfer, status, history */
    curl_global_init(CURL_GLOBAL_ALL);
    MYSQL *conn = db_connect();
    if (!conn) {
        fprintf(stderr, "Cannot connect to MySQL. ACH transfers require database.\n");
        curl_global_cleanup();
        return 1;
    }
    create_ach_tables(conn);

    if (do_status) {
        if (reference[0] == '\0') {
            fprintf(stderr, "Error: --reference required for status query\n");
        } else {
            print_status(conn, reference);
        }
    } else if (do_history) {
        print_history(conn, history_limit);
    } else {
        /* Execute transfer */
        if (req.platform == PLATFORM_COUNT) {
            fprintf(stderr, "Error: --platform required (melio, moov, stripe, square, helcim)\n");
            mysql_close(conn);
            curl_global_cleanup();
            return 1;
        }
        if (req.amount <= 0.0) {
            fprintf(stderr, "Error: --amount must be positive\n");
            mysql_close(conn);
            curl_global_cleanup();
            return 1;
        }
        if (req.routing_number[0] == '\0' || req.account_number[0] == '\0') {
            fprintf(stderr, "Error: --to routing:account required\n");
            mysql_close(conn);
            curl_global_cleanup();
            return 1;
        }
        if (req.api_key[0] == '\0') {
            /* Try environment variable */
            const char *env_key = NULL;
            switch (req.platform) {
                case PLATFORM_MELIO:  env_key = getenv("MELIO_API_KEY"); break;
                case PLATFORM_MOOV:   env_key = getenv("MOOV_API_KEY"); break;
                case PLATFORM_STRIPE: env_key = getenv("STRIPE_SECRET_KEY"); break;
                case PLATFORM_SQUARE: env_key = getenv("SQUARE_ACCESS_TOKEN"); break;
                case PLATFORM_HELCIM: env_key = getenv("HELCIM_API_TOKEN"); break;
                default: break;
            }
            if (env_key) {
                strncpy(req.api_key, env_key, sizeof(req.api_key) - 1);
            } else {
                fprintf(stderr, "Error: --api-key required or set environment variable:\n");
                fprintf(stderr, "  MELIO_API_KEY, MOOV_API_KEY, STRIPE_SECRET_KEY,\n");
                fprintf(stderr, "  SQUARE_ACCESS_TOKEN, HELCIM_API_TOKEN\n");
                mysql_close(conn);
                curl_global_cleanup();
                return 1;
            }
        }

        execute_transfer(conn, &req);
    }

    mysql_close(conn);
    curl_global_cleanup();
    return 0;
}
