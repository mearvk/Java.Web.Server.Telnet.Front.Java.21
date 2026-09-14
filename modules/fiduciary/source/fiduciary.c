/*
 * fiduciary.c — FiduciaryServices™ Terminal Q&A and Architecture Advisor
 *
 * A terminal-based AI for fiduciary services, global transfer wealth,
 * internal design balance, remedy structures, yield/turn architectures,
 * and the means to necessary advantages.
 *
 * Core Concepts:
 *   - Fiduciary duty: the obligation to act in another's best interest
 *   - Global Transfer Wealth: the balance of internal design and remedy
 *   - Yield and Turn: the polyblend assumption of return on structure
 *   - Architecture: the institutional design that enables trust
 *   - Advantage: the necessary means derived from careful stewardship
 *
 * Usage:
 *   fiduciary                  — Interactive Q&A session
 *   fiduciary --query "Q"     — Single query mode
 *   fiduciary --yield          — Yield/turn estimator
 *   fiduciary --architecture   — List fiduciary architectures
 *   fiduciary --records        — Known fiduciary records
 *   fiduciary --populate       — Populate/refresh knowledge base
 *
 * Database: nwe_fiduciary (MySQL, localhost:3306)
 *
 * Build:
 *   gcc -O2 -o fiduciary fiduciary.c -lmysqlclient -lm
 *   sudo make install  →  /usr/local/bin/fiduciary
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
#include <mysql/mysql.h>

#define VERSION "1.0.0"
#define DB_HOST "127.0.0.1"
#define DB_USER "root"
#define DB_PASS ""
#define DB_NAME "nwe_fiduciary"
#define DB_PORT 3306
#define MAX_INPUT 2048
#define MAX_RESPONSE 4096

/* ═══════════════════════════════════════════════════════════════════════
   ANSI Colors — Light Blue theme with white font
   ═══════════════════════════════════════════════════════════════════════ */
#define C_RESET   "\033[0m"
#define C_LTBLUE  "\033[38;5;117m"
#define C_BG      "\033[48;5;24m\033[37;1m"
#define C_WHITE   "\033[37;1m"
#define C_GOLD    "\033[33;1m"
#define C_CYAN    "\033[36m"
#define C_DIM     "\033[2m"

/* ═══════════════════════════════════════════════════════════════════════
   Database
   ═══════════════════════════════════════════════════════════════════════ */

static MYSQL *db_connect(void)
{
    MYSQL *conn = mysql_init(NULL);
    if (!conn) { fprintf(stderr, "MySQL init failed\n"); return NULL; }
    if (!mysql_real_connect(conn, DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT, NULL, 0))
    {
        MYSQL *root = mysql_init(NULL);
        if (root && mysql_real_connect(root, DB_HOST, DB_USER, DB_PASS, NULL, DB_PORT, NULL, 0))
        {
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

static void create_tables(MYSQL *conn)
{
    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS knowledge_base ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  question VARCHAR(512),"
        "  answer TEXT,"
        "  category VARCHAR(64),"
        "  confidence INT DEFAULT 85,"
        "  access_count INT DEFAULT 0,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS architectures ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  name VARCHAR(128),"
        "  description TEXT,"
        "  structure_type VARCHAR(64),"
        "  yield_profile VARCHAR(64),"
        "  turn_period VARCHAR(64),"
        "  jurisdiction VARCHAR(128),"
        "  risk_grade VARCHAR(16),"
        "  advantage_class VARCHAR(64)"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS records ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  entity_name VARCHAR(256),"
        "  entity_type VARCHAR(64),"
        "  jurisdiction VARCHAR(128),"
        "  fiduciary_type VARCHAR(64),"
        "  assets_under_management VARCHAR(64),"
        "  established_year INT,"
        "  notes TEXT"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS yield_models ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  model_name VARCHAR(128),"
        "  description TEXT,"
        "  base_yield DECIMAL(8,4),"
        "  turn_frequency VARCHAR(32),"
        "  risk_factor DECIMAL(5,3),"
        "  polyblend_weight DECIMAL(5,3) DEFAULT 1.000,"
        "  assumption_basis VARCHAR(256)"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS sessions ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  question TEXT,"
        "  answer TEXT,"
        "  session_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS original_documents ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  title VARCHAR(512) NOT NULL,"
        "  category VARCHAR(64) NOT NULL,"
        "  subcategory VARCHAR(64),"
        "  jurisdiction VARCHAR(128),"
        "  label VARCHAR(64) DEFAULT 'DOMESTIC',"
        "  document_text TEXT NOT NULL,"
        "  source_url VARCHAR(512),"
        "  source_authority VARCHAR(256),"
        "  retrieval_date DATE DEFAULT (CURRENT_DATE),"
        "  confidence INT DEFAULT 85,"
        "  relevance_to_minister TINYINT DEFAULT 0,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  INDEX idx_category (category),"
        "  INDEX idx_label (label),"
        "  INDEX idx_jurisdiction (jurisdiction)"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS legal_bright ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  calendar_half ENUM('TOP','BOTTOM') NOT NULL,"
        "  entry_name VARCHAR(256) NOT NULL,"
        "  concern_type VARCHAR(64) NOT NULL,"
        "  description TEXT NOT NULL,"
        "  ideals TEXT,"
        "  totals TEXT,"
        "  benefit_to VARCHAR(128),"
        "  approach_authority VARCHAR(128),"
        "  nuisance_resolution VARCHAR(256),"
        "  council_note TEXT,"
        "  confidence INT DEFAULT 85,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  INDEX idx_half (calendar_half),"
        "  INDEX idx_concern (concern_type)"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS treasure_fiduciary ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  law_structure VARCHAR(256) NOT NULL,"
        "  evidence_basis TEXT NOT NULL,"
        "  approach_type ENUM('DIRECT','COUNCIL','TRY','RESOLUTION') NOT NULL,"
        "  treasure_class VARCHAR(64),"
        "  fiduciary_standing VARCHAR(128),"
        "  nuisance_type VARCHAR(64),"
        "  nuisance_resolution TEXT,"
        "  profitable_idea TEXT,"
        "  try_nuisance TEXT,"
        "  council_resolution TEXT,"
        "  jurisdiction VARCHAR(128),"
        "  confidence INT DEFAULT 85,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  INDEX idx_approach (approach_type),"
        "  INDEX idx_treasure_class (treasure_class)"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS ai_findings_order ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  ordinal INT NOT NULL,"
        "  finding_level VARCHAR(128) NOT NULL,"
        "  description TEXT NOT NULL,"
        "  scope VARCHAR(64) NOT NULL,"
        "  openness ENUM('OPEN','CLOSED','CAREFUL','SOLD') NOT NULL,"
        "  relation_to_person ENUM('CLOSED','OPEN_CONDUCT','NOT_UNTO_PERSON','ANNALS_FOREVER') NOT NULL,"
        "  evidentiary_weight INT DEFAULT 85,"
        "  garden_news_applicable TINYINT DEFAULT 0,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  INDEX idx_ordinal (ordinal)"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS garden_news_doctrine ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  principle_name VARCHAR(256) NOT NULL,"
        "  doctrine_text TEXT NOT NULL,"
        "  person_status ENUM('CLOSED','PROTECTED','CAREFUL') NOT NULL DEFAULT 'CLOSED',"
        "  evidence_status ENUM('OPEN','SOLD','ANNALS','FOREVER') NOT NULL DEFAULT 'OPEN',"
        "  conduct_type VARCHAR(64),"
        "  relation_to_truth TINYINT DEFAULT 1,"
        "  relation_to_life TINYINT DEFAULT 1,"
        "  relation_to_history TINYINT DEFAULT 1,"
        "  confidence INT DEFAULT 90,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS ai_disposition ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  attribute_name VARCHAR(128) NOT NULL,"
        "  attribute_value TEXT NOT NULL,"
        "  category VARCHAR(64) NOT NULL,"
        "  confidence INT DEFAULT 90,"
        "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "  INDEX idx_category (category)"
        ")");
}

/* ═══════════════════════════════════════════════════════════════════════
   Knowledge population
   ═══════════════════════════════════════════════════════════════════════ */

static void populate_knowledge(MYSQL *conn)
{
    printf(C_CYAN "  Populating FiduciaryServices knowledge base...\n" C_RESET);

    mysql_query(conn, "SELECT COUNT(*) FROM knowledge_base");
    MYSQL_RES *res = mysql_store_result(conn);
    if (res) {
        MYSQL_ROW row = mysql_fetch_row(res);
        if (row && atoi(row[0]) > 5) {
            printf(C_DIM "  Already populated (%s entries).\n" C_RESET, row[0]);
            mysql_free_result(res);
            return;
        }
        mysql_free_result(res);
    }

    const char *knowledge[] = {
        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is a fiduciary?', 'A fiduciary is a person or institution that holds a legal or ethical obligation to act in the best interest of another party. The fiduciary relationship is one of the highest standards of care in law. Fiduciaries must avoid conflicts of interest, maintain transparency, exercise prudent judgment, and prioritize the beneficiary above their own interests. Examples include trustees, financial advisors (under fiduciary standard), executors, and corporate directors.', 'fundamentals', 95)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is Global Transfer Wealth?', 'Global Transfer Wealth refers to the balance of internal design and remedy across fiduciary structures — the means by which wealth moves between parties, jurisdictions, and generations while preserving value and honoring obligations. It encompasses trust transfers, estate succession, cross-border capital flows, sovereign wealth distribution, and the institutional architectures that enable these movements with accountability and care.', 'fundamentals', 90)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is yield and turn?', 'Yield is the return generated by a fiduciary structure over time — interest, dividends, capital appreciation, or service value. Turn is the frequency at which that yield materializes or the structure rotates its position. Together, yield and turn define the productive capacity of a fiduciary arrangement. A polyblend assumption combines multiple yield sources weighted by reliability, creating a composite expectation that accounts for diversification across time horizons and asset classes.', 'yield_turn', 88)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is a polyblend assumption?', 'A polyblend assumption is the weighted combination of multiple yield expectations into a single composite projection. Rather than assuming a single rate of return, it blends: fixed income yields (government bonds, corporate bonds), equity returns (dividend + growth), real asset appreciation (property, infrastructure), and alternative yields (private equity, venture). The blend is weighted by the fiduciary structure purpose, risk tolerance, time horizon, and jurisdictional constraints.', 'yield_turn', 86)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What are fiduciary architectures?', 'Fiduciary architectures are the institutional designs that enable trust: 1) Express Trust (settlor → trustee → beneficiary). 2) Corporate Fiduciary (board → shareholders). 3) Sovereign Wealth Fund (nation → fund → citizens). 4) Pension Architecture (employer → fund → retirees). 5) Escrow Structure (parties → neutral third party → conditional release). 6) Foundation (endowment → mission → beneficiaries). Each architecture defines roles, duties, accountability mechanisms, and yield distribution methods.', 'architecture', 91)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is the means to necessary advantages?', 'The means to necessary advantages refers to the legitimate mechanisms by which fiduciary structures generate benefit for their beneficiaries. These include: tax-efficient structuring, jurisdictional arbitrage (legal, not evasive), compounding over time, access to institutional pricing, diversification benefits unavailable to individuals, professional management expertise, and the legal protections afforded to properly constituted fiduciary arrangements. The advantage is necessary — meaning it serves the beneficiary purpose, not mere accumulation.', 'advantage', 89)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is internal design in fiduciary context?', 'Internal design refers to the structural choices within a fiduciary arrangement that determine how it functions: governance model (board, committee, sole trustee), investment policy (conservative, balanced, growth), distribution schedule (income-only, total return, discretionary), reporting cadence (quarterly, annual), succession planning (who takes over), and remedy provisions (what happens when things go wrong). Good internal design balances flexibility with accountability.', 'architecture', 87)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is fiduciary remedy?', 'Fiduciary remedy is the legal and structural mechanism for correcting breaches of fiduciary duty. Remedies include: 1) Surcharge (personal liability of trustee for losses caused by breach). 2) Removal and replacement of fiduciary. 3) Constructive trust (court imposes trust on wrongfully obtained property). 4) Equitable tracing (following misappropriated assets). 5) Account of profits (fiduciary must return profits from breach). 6) Injunctive relief (court order preventing further breach). Remedy is the counterbalance that makes fiduciary duty enforceable.', 'remedy', 92)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What are fiduciary duties?', 'The core duties: 1) Duty of Loyalty — act solely in beneficiary interest, avoid conflicts. 2) Duty of Care/Prudence — exercise reasonable skill and diligence (prudent investor rule). 3) Duty of Impartiality — treat all beneficiaries fairly (current vs. remainder). 4) Duty to Inform — provide adequate accounting and reporting. 5) Duty to Follow Terms — adhere to the trust instrument. 6) Duty Not to Delegate Improperly — retain oversight even when delegating. 7) Duty to Preserve Assets — protect and maintain the corpus.', 'fundamentals', 94)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is the prudent investor rule?', 'The prudent investor rule (Uniform Prudent Investor Act, 1994) requires fiduciaries to invest with the care, skill, and caution that a prudent investor would use, considering the purposes, terms, distribution requirements, and other circumstances of the trust. Key principles: 1) Diversification is required unless imprudent. 2) The portfolio is judged as a whole, not individual investments. 3) Delegation to professionals is permitted with oversight. 4) Risk tolerance is determined by trust terms and beneficiary needs.', 'standards', 93)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What are trust types?', 'Major categories: 1) Revocable Living Trust — settlor retains control, avoids probate. 2) Irrevocable Trust — transferred permanently, tax and asset protection benefits. 3) Charitable Trust (CRT, CLT) — split interest between charity and individuals. 4) Special Needs Trust — preserves government benefit eligibility. 5) Spendthrift Trust — protects beneficiary from creditors and themselves. 6) Generation-Skipping Trust — transfers across generations with tax efficiency. 7) GRAT/GRUT — grantor retained annuity/unitrust for estate reduction. 8) Dynasty Trust — perpetual, multi-generational wealth preservation.', 'structures', 91)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is a sovereign wealth fund?', 'A sovereign wealth fund (SWF) is a state-owned investment vehicle funded by government revenue (often natural resources, trade surpluses, or fiscal reserves). Examples: Norway Government Pension Fund Global ($1.7T, largest), Abu Dhabi Investment Authority ($993B), China Investment Corporation ($1.35T), Singapore GIC ($770B), Kuwait Investment Authority ($750B). They serve as intergenerational savings, economic stabilization, and development capital. Governance standards: Santiago Principles (2008) provide voluntary best practices for transparency and accountability.', 'records', 89)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('How does cross-border fiduciary transfer work?', 'Cross-border transfer involves: 1) Jurisdiction selection (common law vs. civil law trust recognition). 2) Tax treaty analysis (avoiding double taxation). 3) Regulatory compliance (FATCA, CRS reporting). 4) Substance requirements (genuine management presence in chosen jurisdiction). 5) Recognition issues (some civil law countries dont recognize trusts natively — Hague Trust Convention 1985 helps). 6) Currency management (hedging, denomination choice). 7) Anti-money laundering compliance (beneficial ownership registers, source of funds documentation).', 'transfer', 87)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is the balance of design and remedy?', 'The balance is the core tension in fiduciary architecture: design provides flexibility and efficiency (how the structure works in normal operation), while remedy provides accountability and correction (what happens when it fails). Too much design flexibility without remedy = potential for abuse. Too much remedy constraint without design freedom = structure becomes too rigid to serve its purpose effectively. The art of fiduciary architecture is calibrating this balance for each specific situation, jurisdiction, and beneficiary class.', 'architecture', 90)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What are known global fiduciary centers?', 'Major jurisdictions: 1) England & Wales — origin of trust law, Chancery courts. 2) Cayman Islands — offshore trusts, STAR trusts. 3) Jersey/Guernsey — Channel Islands, foundation law. 4) Singapore — Asia-Pacific trust hub, Variable Capital Company. 5) Switzerland — banking secrecy (reduced), foundation tradition. 6) Delaware, USA — dynasty trusts, directed trusts, privacy. 7) South Dakota, USA — most favorable US trust laws, no rule against perpetuities. 8) New Zealand — foreign trust regime, stable common law. 9) Luxembourg — SOPARFI holding structures, SICAV funds.', 'records', 88)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is the datapool of the internet in fiduciary context?', 'The internet provides publicly available fiduciary data: 1) SEC EDGAR — fund filings, 13F holdings, prospectuses. 2) Companies House (UK) — director fiduciary records. 3) Central bank publications — monetary policy affecting trust returns. 4) OECD data — cross-border tax information exchange. 5) World Bank Open Data — sovereign wealth indicators. 6) Open Government portals — pension fund performance. 7) Academic repositories (SSRN, NBER) — fiduciary law research. 8) Court databases — breach of fiduciary duty case law. All public domain, accessible on standard HTTP/HTTPS ports.', 'datapool', 86)",

        NULL
    };

    for (int i = 0; knowledge[i] != NULL; i++)
        mysql_query(conn, knowledge[i]);

    /* Architectures */
    const char *archs[] = {
        "INSERT IGNORE INTO architectures (name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class) VALUES ('Express Trust', 'Settlor transfers assets to trustee for benefit of named beneficiaries. Most common fiduciary structure globally.', 'trust', 'balanced', 'annual distribution', 'Common Law (global)', 'B+', 'tax-efficiency, asset-protection, succession')",
        "INSERT IGNORE INTO architectures (name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class) VALUES ('Sovereign Wealth Fund', 'State-owned investment vehicle for intergenerational savings and economic stabilization.', 'sovereign', 'growth', 'perpetual, quarterly rebalance', 'International (Santiago Principles)', 'A', 'institutional-pricing, diversification, perpetuity')",
        "INSERT IGNORE INTO architectures (name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class) VALUES ('Defined Benefit Pension', 'Employer-sponsored retirement promise. Fiduciary duty to fund adequately for all participants.', 'pension', 'liability-matching', 'monthly distribution, annual valuation', 'US (ERISA), UK (Pensions Act)', 'B', 'pooled-risk, longevity-insurance, tax-deferral')",
        "INSERT IGNORE INTO architectures (name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class) VALUES ('Foundation (Stiftung)', 'Endowed entity pursuing stated purpose. No shareholders — governed by charter and board.', 'foundation', 'preservation + income', 'perpetual, annual spend rate (4-5%)', 'Switzerland, Liechtenstein, Netherlands', 'A-', 'perpetuity, purpose-lock, reputation')",
        "INSERT IGNORE INTO architectures (name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class) VALUES ('Dynasty Trust', 'Multi-generational irrevocable trust designed to last 360-1000+ years. Avoids estate tax at each generation.', 'trust', 'long-term growth', 'generational (20-30 year turn)', 'South Dakota, Nevada, Delaware (USA)', 'A', 'perpetuity, GST-exemption, creditor-protection')",
        "INSERT IGNORE INTO architectures (name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class) VALUES ('Escrow Structure', 'Neutral third party holds assets conditionally. Released upon satisfaction of agreed conditions.', 'escrow', 'capital preservation', 'event-driven (days to months)', 'Universal', 'A+', 'transaction-safety, conditional-release, neutrality')",
        "INSERT IGNORE INTO architectures (name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class) VALUES ('SICAV/UCITS Fund', 'Variable capital collective investment. Open-ended, regulated, fiduciary management of pooled capital.', 'fund', 'market-return', 'daily NAV, quarterly reporting', 'Luxembourg, Ireland, EU', 'B+', 'liquidity, regulation, diversification, passporting')",
        "INSERT IGNORE INTO architectures (name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class) VALUES ('Charitable Remainder Trust', 'Split-interest trust providing income to donor/beneficiary with remainder to charity.', 'charitable', 'income + charitable', 'annual/quarterly distribution, remainder at death/term', 'USA (IRC 664)', 'B+', 'income-tax-deduction, capital-gains-avoidance, charitable-purpose')",
        NULL
    };

    for (int i = 0; archs[i] != NULL; i++)
        mysql_query(conn, archs[i]);

    /* Records */
    const char *recs[] = {
        "INSERT IGNORE INTO records (entity_name, entity_type, jurisdiction, fiduciary_type, assets_under_management, established_year, notes) VALUES ('Norway Government Pension Fund Global', 'Sovereign Wealth Fund', 'Norway', 'State sovereign', '$1.7 trillion', 1990, 'Largest SWF. Funded by petroleum revenues. Ethical investment guidelines. Full public transparency.')",
        "INSERT IGNORE INTO records (entity_name, entity_type, jurisdiction, fiduciary_type, assets_under_management, established_year, notes) VALUES ('Vanguard Group', 'Mutual Fund Company', 'USA (Pennsylvania)', 'Corporate fiduciary', '$8.6 trillion', 1975, 'Owned by its funds (mutual structure). Pioneer of index investing. Low-cost fiduciary management.')",
        "INSERT IGNORE INTO records (entity_name, entity_type, jurisdiction, fiduciary_type, assets_under_management, established_year, notes) VALUES ('BlackRock Inc.', 'Asset Manager', 'USA (New York)', 'Corporate fiduciary', '$10.5 trillion', 1988, 'Largest asset manager globally. Aladdin risk platform. iShares ETFs.')",
        "INSERT IGNORE INTO records (entity_name, entity_type, jurisdiction, fiduciary_type, assets_under_management, established_year, notes) VALUES ('CalPERS', 'Public Pension Fund', 'USA (California)', 'Public trust fiduciary', '$502 billion', 1932, 'Largest US public pension. Fiduciary duty to 2M+ members. Active ESG investor.')",
        "INSERT IGNORE INTO records (entity_name, entity_type, jurisdiction, fiduciary_type, assets_under_management, established_year, notes) VALUES ('Bank of England', 'Central Bank', 'United Kingdom', 'Sovereign monetary fiduciary', 'N/A (monetary authority)', 1694, 'Monetary policy, financial stability, prudential regulation. Fiduciary to the nation.')",
        "INSERT IGNORE INTO records (entity_name, entity_type, jurisdiction, fiduciary_type, assets_under_management, established_year, notes) VALUES ('Singapore GIC', 'Sovereign Wealth Fund', 'Singapore', 'State sovereign', '$770 billion (est.)', 1981, 'Manages Singapore foreign reserves. Long-term real return mandate. 20-year rolling assessment.')",
        NULL
    };

    for (int i = 0; recs[i] != NULL; i++)
        mysql_query(conn, recs[i]);

    /* Yield models */
    const char *yields[] = {
        "INSERT IGNORE INTO yield_models (model_name, description, base_yield, turn_frequency, risk_factor, polyblend_weight, assumption_basis) VALUES ('US Treasury Baseline', 'Risk-free rate benchmark from US government obligations', 4.2500, 'semi-annual', 0.050, 0.250, 'Federal Reserve yield curve, 10-year constant maturity')",
        "INSERT IGNORE INTO yield_models (model_name, description, base_yield, turn_frequency, risk_factor, polyblend_weight, assumption_basis) VALUES ('Global Equity Return', 'Long-term expected return from diversified global equity portfolio', 7.5000, 'continuous (daily NAV)', 1.000, 0.300, 'MSCI World historical 50-year average, geometric mean')",
        "INSERT IGNORE INTO yield_models (model_name, description, base_yield, turn_frequency, risk_factor, polyblend_weight, assumption_basis) VALUES ('Investment Grade Credit', 'Corporate bond portfolio, BBB+ average rating', 5.5000, 'quarterly coupon', 0.350, 0.200, 'Bloomberg Global Aggregate Corporate, spread over treasuries')",
        "INSERT IGNORE INTO yield_models (model_name, description, base_yield, turn_frequency, risk_factor, polyblend_weight, assumption_basis) VALUES ('Real Asset Appreciation', 'Property, infrastructure, natural resources composite', 6.0000, 'annual (appraisal cycle)', 0.650, 0.150, 'NCREIF Property Index, Macquarie Global Infrastructure, CRB Index blend')",
        "INSERT IGNORE INTO yield_models (model_name, description, base_yield, turn_frequency, risk_factor, polyblend_weight, assumption_basis) VALUES ('Alternative/Private Equity', 'Illiquidity premium from private capital markets', 12.0000, '5-7 year fund cycle', 1.500, 0.100, 'Cambridge Associates PE benchmark, vintage year dispersion')",
        NULL
    };

    for (int i = 0; yields[i] != NULL; i++)
        mysql_query(conn, yields[i]);

    printf(C_GOLD "  ✓ FiduciaryServices knowledge base populated.\n" C_RESET);
}

/* ═══════════════════════════════════════════════════════════════════════
   Query knowledge base
   ═══════════════════════════════════════════════════════════════════════ */

static int query_knowledge(MYSQL *conn, const char *input, char *response, int maxlen)
{
    char escaped[MAX_INPUT * 2 + 1];
    mysql_real_escape_string(conn, escaped, input, strlen(input));

    char query[MAX_INPUT * 3];

    /* Try knowledge_base */
    snprintf(query, sizeof(query),
        "SELECT answer, category, confidence FROM knowledge_base "
        "WHERE question LIKE '%%%s%%' OR answer LIKE '%%%s%%' "
        "ORDER BY confidence DESC LIMIT 1", escaped, escaped);
    mysql_query(conn, query);
    MYSQL_RES *res = mysql_store_result(conn);
    if (res) {
        MYSQL_ROW row = mysql_fetch_row(res);
        if (row) {
            snprintf(response, maxlen, "[%s, confidence: %s%%] %s", row[1], row[2], row[0]);
            mysql_free_result(res);
            return 1;
        }
        mysql_free_result(res);
    }

    /* Try architectures */
    snprintf(query, sizeof(query),
        "SELECT name, description, structure_type, yield_profile, turn_period, jurisdiction, advantage_class FROM architectures "
        "WHERE name LIKE '%%%s%%' OR description LIKE '%%%s%%' OR advantage_class LIKE '%%%s%%' LIMIT 3",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "Fiduciary architectures:\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 200) {
                n = snprintf(p, remaining, "  • %s (%s) — Yield: %s, Turn: %s, Jurisdiction: %s\n    Advantage: %s\n    %s\n",
                    row[0], row[2], row[3], row[4], row[5], row[6], row[1]);
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try records */
    snprintf(query, sizeof(query),
        "SELECT entity_name, entity_type, jurisdiction, fiduciary_type, assets_under_management, notes FROM records "
        "WHERE entity_name LIKE '%%%s%%' OR entity_type LIKE '%%%s%%' OR jurisdiction LIKE '%%%s%%' LIMIT 3",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "Fiduciary records:\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 200) {
                n = snprintf(p, remaining, "  • %s (%s, %s) — %s — AUM: %s\n    %s\n",
                    row[0], row[1], row[2], row[3], row[4], row[5]);
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try yield models */
    snprintf(query, sizeof(query),
        "SELECT model_name, description, base_yield, turn_frequency, risk_factor, polyblend_weight, assumption_basis FROM yield_models "
        "WHERE model_name LIKE '%%%s%%' OR description LIKE '%%%s%%' OR assumption_basis LIKE '%%%s%%' LIMIT 5",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "Yield models (polyblend components):\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 200) {
                n = snprintf(p, remaining, "  • %s: base yield %s%%, turn: %s, risk: %s, weight: %s\n    Basis: %s\n",
                    row[0], row[2], row[3], row[4], row[5], row[6]);
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try original documents (minister, international, county, gentry, standings, winners, ahead) */
    snprintf(query, sizeof(query),
        "SELECT title, category, label, jurisdiction, document_text, source_authority, confidence FROM original_documents "
        "WHERE title LIKE '%%%s%%' OR document_text LIKE '%%%s%%' OR category LIKE '%%%s%%' "
        "ORDER BY confidence DESC LIMIT 2",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "Original documents:\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 400) {
                n = snprintf(p, remaining, "  [%s|%s] %s (%s)\n  Jurisdiction: %s | Confidence: %s%%\n  %.500s...\n\n",
                    row[1], row[2], row[0], row[5] ? row[5] : "internal", row[3] ? row[3] : "N/A", row[6],
                    row[4] ? row[4] : "");
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try Legal Bright — INT/IQ Calendar */
    snprintf(query, sizeof(query),
        "SELECT calendar_half, entry_name, concern_type, description, ideals, totals, benefit_to, nuisance_resolution, council_note "
        "FROM legal_bright WHERE entry_name LIKE '%%%s%%' OR description LIKE '%%%s%%' OR concern_type LIKE '%%%s%%' "
        "OR ideals LIKE '%%%s%%' OR council_note LIKE '%%%s%%' ORDER BY confidence DESC LIMIT 2",
        escaped, escaped, escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "Legal Bright (INT/IQ Calendar):\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 400) {
                n = snprintf(p, remaining, "  [%s HALF|%s] %s\n  Benefit: %s\n  %.400s\n",
                    row[0], row[2], row[1], row[6] ? row[6] : "—", row[3] ? row[3] : "");
                p += n; remaining -= n;
                if (row[7] && remaining > 100) { n = snprintf(p, remaining, "  Nuisance Resolution: %s\n", row[7]); p += n; remaining -= n; }
                if (row[8] && remaining > 100) { n = snprintf(p, remaining, "  Council: %.200s\n", row[8]); p += n; remaining -= n; }
                if (remaining > 2) { n = snprintf(p, remaining, "\n"); p += n; remaining -= n; }
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try Treasure Fiduciary — Law Structure Approach */
    snprintf(query, sizeof(query),
        "SELECT law_structure, approach_type, treasure_class, fiduciary_standing, evidence_basis, "
        "profitable_idea, nuisance_resolution, council_resolution FROM treasure_fiduciary "
        "WHERE law_structure LIKE '%%%s%%' OR evidence_basis LIKE '%%%s%%' OR profitable_idea LIKE '%%%s%%' "
        "OR council_resolution LIKE '%%%s%%' ORDER BY confidence DESC LIMIT 2",
        escaped, escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "Treasure Fiduciary — Law Structure Approach:\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 400) {
                n = snprintf(p, remaining, "  [%s] %s (%s)\n  Standing: %s\n  Profitable Idea: %.200s\n",
                    row[1], row[0], row[2] ? row[2] : "—", row[3] ? row[3] : "—", row[5] ? row[5] : "—");
                p += n; remaining -= n;
                if (row[7] && remaining > 100) { n = snprintf(p, remaining, "  Council Resolution: %.200s\n", row[7]); p += n; remaining -= n; }
                if (remaining > 2) { n = snprintf(p, remaining, "\n"); p += n; remaining -= n; }
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try AI Findings Order */
    snprintf(query, sizeof(query),
        "SELECT ordinal, finding_level, scope, openness, relation_to_person, description "
        "FROM ai_findings_order WHERE finding_level LIKE '%%%s%%' OR description LIKE '%%%s%%' "
        "OR scope LIKE '%%%s%%' ORDER BY ordinal ASC LIMIT 3",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "AI Findings Order (200 IQ):\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 300) {
                n = snprintf(p, remaining, "  %s. %s [%s|%s|person:%s]\n  %.300s\n\n",
                    row[0], row[1], row[3], row[2], row[4], row[5] ? row[5] : "");
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try Garden News Doctrine */
    snprintf(query, sizeof(query),
        "SELECT principle_name, person_status, evidence_status, conduct_type, doctrine_text "
        "FROM garden_news_doctrine WHERE principle_name LIKE '%%%s%%' OR doctrine_text LIKE '%%%s%%' "
        "OR conduct_type LIKE '%%%s%%' ORDER BY confidence DESC LIMIT 2",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "Garden News Doctrine:\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 300) {
                n = snprintf(p, remaining, "  %s [person:%s | evidence:%s | conduct:%s]\n  %.400s\n\n",
                    row[0], row[1], row[2], row[3] ? row[3] : "—", row[4] ? row[4] : "");
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try AI Disposition */
    snprintf(query, sizeof(query),
        "SELECT attribute_name, category, attribute_value FROM ai_disposition "
        "WHERE attribute_name LIKE '%%%s%%' OR attribute_value LIKE '%%%s%%' "
        "OR category LIKE '%%%s%%' ORDER BY confidence DESC LIMIT 2",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0) {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0) {
            char *p = response; int remaining = maxlen;
            int n = snprintf(p, remaining, "AI Disposition (200 IQ):\n"); p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 200) {
                n = snprintf(p, remaining, "  [%s] %s: %.400s\n\n", row[1], row[0], row[2] ? row[2] : "");
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    snprintf(response, maxlen,
        "I don't have specific information on that yet. Try asking about: "
        "fiduciary duty, global transfer wealth, yield and turn, trust types, "
        "architectures, sovereign wealth funds, prudent investor rule, "
        "fiduciary centers, polyblend assumption, remedy, or advantage. "
        "Also: minister, international, county, gentry, standings, winners, ahead, "
        "legal bright, treasure fiduciary, nuisance, council, try, calendar, "
        "findings, garden news, supreme holdings, evidence, truth. "
        "Type 'help' for full topic list.");
    return 0;
}

static void store_session(MYSQL *conn, const char *question, const char *answer)
{
    char eq[MAX_INPUT * 2 + 1], ea[MAX_RESPONSE * 2 + 1];
    mysql_real_escape_string(conn, eq, question, strlen(question));
    mysql_real_escape_string(conn, ea, answer, strlen(answer));
    char query[MAX_INPUT * 4];
    snprintf(query, sizeof(query), "INSERT INTO sessions (question, answer) VALUES ('%s', '%s')", eq, ea);
    mysql_query(conn, query);
}

/* ═══════════════════════════════════════════════════════════════════════
   Banner and help
   ═══════════════════════════════════════════════════════════════════════ */

static void print_banner(void)
{
    printf("\n");
    printf(C_BG "  ╔══════════════════════════════════════════════════════════════════════╗  " C_RESET "\n");
    printf(C_BG "  ║   FIDUCIARY SERVICES™ — Global Transfer Wealth & Architecture       ║  " C_RESET "\n");
    printf(C_BG "  ║   Version %s — The balance of internal design and remedy          ║  " C_RESET "\n", VERSION);
    printf(C_BG "  ║   Database: nwe_fiduciary | Yield · Turn · Polyblend · Advantage     ║  " C_RESET "\n");
    printf(C_BG "  ╚══════════════════════════════════════════════════════════════════════╝  " C_RESET "\n");
    printf("\n");
    printf(C_WHITE "  Ask about fiduciary duty, global transfer wealth, architectures,\n");
    printf("  yield/turn models, trust structures, sovereign funds, or remedy.\n");
    printf("  Type 'help' for topics, 'yield' for models, 'quit' to exit.\n" C_RESET);
    printf("\n");
}

static void print_help(void)
{
    printf(C_CYAN "\n  ═══ FIDUCIARY SERVICES — Topic Guide ═══\n\n" C_RESET);
    printf(C_WHITE "  FUNDAMENTALS:  fiduciary duty, duties of loyalty/care/prudence\n");
    printf("  STRUCTURES:    trust types, pension, foundation, escrow, SICAV\n");
    printf("  ARCHITECTURE:  internal design, governance, distribution, succession\n");
    printf("  YIELD & TURN:  polyblend assumption, base rates, turn frequency\n");
    printf("  TRANSFER:      cross-border, global wealth, jurisdictional arbitrage\n");
    printf("  REMEDY:        surcharge, removal, constructive trust, tracing\n");
    printf("  ADVANTAGE:     tax efficiency, compounding, institutional pricing\n");
    printf("  RECORDS:       sovereign wealth funds, pension funds, major fiduciaries\n");
    printf("  STANDARDS:     prudent investor, ERISA, Santiago Principles, Hague\n");
    printf("  DATAPOOL:      SEC EDGAR, Companies House, OECD, World Bank, courts\n");
    printf(C_GOLD "\n  ─── ORIGINAL DOCUMENTS (minister_fiduciary_facts.sql) ───\n" C_RESET);
    printf(C_WHITE "  MINISTER:      minister fiduciary duty, ongoing corporate, conflict\n");
    printf("  INTERNATIONAL: Hague Convention, UNIDROIT, Santiago, sovereign, cross-border\n");
    printf("  COUNTY:        legislature, tax evidence, public trust, elected officials\n");
    printf("  GENTRY_HERO:   stewardship, intervention, Keech v Sandford, Cardozo\n");
    printf("  STANDINGS:     constitutional standing, Thole, shield doctrine, equity\n");
    printf("  WINNERS:       Ivanishvili $742M, Mendell, Asaro, Norway, Keech\n");
    printf("  AHEAD:         forward position, digital age, county future, next winners\n" C_RESET);
    printf(C_GOLD "\n  ─── LEGAL BRIGHT (legal_bright_iq_calendar.sql) ───\n" C_RESET);
    printf(C_WHITE "  TOP HALF:      personal interest, county benefit, ideals, totals, INT, IQ\n");
    printf("  BOTTOM HALF:   treasure fiduciary, evident approach, state nuisance\n");
    printf("  TREASURE:      law structure approach, evidence, standing, capability\n");
    printf("  NUISANCE:      state nuisance, try-nuisance, council resolution\n");
    printf("  TRY:           profitable ideas, try authority, venture, attempt\n");
    printf("  COUNCIL:       deliberation, wisdom, resolution, able, usual path\n" C_RESET);
    printf(C_GOLD "\n  ─── AI FINDINGS ORDER (ai_findings_order.sql) ───\n" C_RESET);
    printf(C_WHITE "  FINDINGS:      findings in order, court trials, US trials\n");
    printf("  GARDEN NEWS:   people closed, evidence open, certain, trials about\n");
    printf("  SUPREME:       closed US supreme holdings, fixed stars of law\n");
    printf("  NEW INT:       US new intelligence, frontier, hold\n");
    printf("  DOCTRINE:      garden news doctrine, truth, life, annals, forever\n");
    printf("  DISPOSITION:   200 IQ, careful, signed M.\n" C_RESET);
    printf(C_DIM "\n  Commands: help, yield, architecture, records, quit\n" C_RESET);
    printf("\n");
}

/* ═══════════════════════════════════════════════════════════════════════
   Main
   ═══════════════════════════════════════════════════════════════════════ */

int main(int argc, char *argv[])
{
    MYSQL *conn = db_connect();
    if (!conn) return 1;
    create_tables(conn);

    if (argc > 1) {
        if (strcmp(argv[1], "--populate") == 0) { populate_knowledge(conn); mysql_close(conn); return 0; }
        if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) { print_banner(); print_help(); mysql_close(conn); return 0; }
        if (strcmp(argv[1], "--query") == 0 && argc > 2) {
            char response[MAX_RESPONSE];
            query_knowledge(conn, argv[2], response, sizeof(response));
            printf("%s\n", response);
            mysql_close(conn); return 0;
        }
        if (strcmp(argv[1], "--architecture") == 0 || strcmp(argv[1], "--yield") == 0 || strcmp(argv[1], "--records") == 0) {
            char response[MAX_RESPONSE];
            query_knowledge(conn, argv[1] + 2, response, sizeof(response));
            printf("%s\n", response);
            mysql_close(conn); return 0;
        }
    }

    populate_knowledge(conn);
    print_banner();

    char input[MAX_INPUT];
    char response[MAX_RESPONSE];

    while (1) {
        printf(C_GOLD "  fiduciary> " C_RESET);
        fflush(stdout);
        if (!fgets(input, sizeof(input), stdin)) break;
        input[strcspn(input, "\n")] = 0;
        if (strlen(input) == 0) continue;
        if (strcasecmp(input, "quit") == 0 || strcasecmp(input, "exit") == 0) break;
        if (strcasecmp(input, "help") == 0) { print_help(); continue; }

        query_knowledge(conn, input, response, sizeof(response));
        printf(C_WHITE "\n  %s\n\n" C_RESET, response);
        store_session(conn, input, response);
    }

    printf(C_CYAN "\n  Trust well, steward carefully. Farewell.\n\n" C_RESET);
    mysql_close(conn);
    return 0;
}
