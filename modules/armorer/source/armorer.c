/*
 * armorer.c — Armorer Steve™ Terminal Q&A and Cost Estimator
 *
 * A terminal-based AI assistant for plate armor, forging methods, modern metal
 * theory, shop setup, equipment costs, known armorers, regulations, and trade.
 *
 * Usage:
 *   armorer              — Interactive Q&A session with Armorer Steve
 *   armorer --query "Q"  — Single query mode
 *   armorer --cost       — Interactive cost estimator
 *   armorer --sources    — List known sources and armorers
 *   armorer --regs       — Armor regulations and series
 *   armorer --populate   — Populate/refresh the MySQL knowledge base
 *
 * Database: nwe_armorer (MySQL, localhost:3306)
 *
 * Build:
 *   gcc -O2 -o armorer armorer.c -lmysqlclient -lm
 *   sudo make install  →  /usr/local/bin/armorer
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
#define DB_NAME "nwe_armorer"
#define DB_PORT 3306
#define MAX_INPUT 2048
#define MAX_RESPONSE 4096

/* ═══════════════════════════════════════════════════════════════════════
   ANSI Colors — Dark Blue theme with white font
   ═══════════════════════════════════════════════════════════════════════ */
#define C_RESET   "\033[0m"
#define C_BLUE    "\033[38;5;17m"
#define C_DKBLUE  "\033[48;5;17m\033[37;1m"
#define C_WHITE   "\033[37;1m"
#define C_GOLD    "\033[33;1m"
#define C_CYAN    "\033[36m"
#define C_DIM     "\033[2m"

/* ═══════════════════════════════════════════════════════════════════════
   Structures
   ═══════════════════════════════════════════════════════════════════════ */

typedef struct {
    char question[512];
    char answer[MAX_RESPONSE];
    char category[64];
    int confidence;
} KnowledgeEntry;

typedef struct {
    char item[128];
    char description[256];
    double cost_low;
    double cost_high;
    char currency[8];
    char category[64];
} CostEntry;

/* ═══════════════════════════════════════════════════════════════════════
   Database connection
   ═══════════════════════════════════════════════════════════════════════ */

static MYSQL *db_connect(void)
{
    MYSQL *conn = mysql_init(NULL);
    if (!conn) { fprintf(stderr, "MySQL init failed\n"); return NULL; }
    if (!mysql_real_connect(conn, DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT, NULL, 0))
    {
        /* Try creating the database */
        MYSQL *root = mysql_init(NULL);
        if (root && mysql_real_connect(root, DB_HOST, DB_USER, DB_PASS, NULL, DB_PORT, NULL, 0))
        {
            mysql_query(root, "CREATE DATABASE IF NOT EXISTS nwe_armorer CHARACTER SET utf8mb4");
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

/* ═══════════════════════════════════════════════════════════════════════
   Table creation
   ═══════════════════════════════════════════════════════════════════════ */

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
        "CREATE TABLE IF NOT EXISTS cost_estimates ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  item VARCHAR(128),"
        "  description VARCHAR(512),"
        "  cost_low DECIMAL(10,2),"
        "  cost_high DECIMAL(10,2),"
        "  currency VARCHAR(8) DEFAULT 'USD',"
        "  category VARCHAR(64),"
        "  source VARCHAR(256),"
        "  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS armorers ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  name VARCHAR(128),"
        "  location VARCHAR(256),"
        "  specialty VARCHAR(256),"
        "  era VARCHAR(64),"
        "  notable_works TEXT,"
        "  series_wins INT DEFAULT 0,"
        "  active BOOLEAN DEFAULT TRUE"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS regulations ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  body VARCHAR(128),"
        "  regulation_name VARCHAR(256),"
        "  scope VARCHAR(128),"
        "  description TEXT,"
        "  series VARCHAR(64),"
        "  effective_date DATE"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS trade_records ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  item_type VARCHAR(128),"
        "  seller VARCHAR(128),"
        "  buyer VARCHAR(128),"
        "  price DECIMAL(12,2),"
        "  currency VARCHAR(8),"
        "  trade_date DATE,"
        "  location VARCHAR(128),"
        "  series VARCHAR(64),"
        "  capacitor_grade VARCHAR(32)"
        ")");

    mysql_query(conn,
        "CREATE TABLE IF NOT EXISTS sessions ("
        "  id BIGINT AUTO_INCREMENT PRIMARY KEY,"
        "  question TEXT,"
        "  answer TEXT,"
        "  session_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")");
}

/* ═══════════════════════════════════════════════════════════════════════
   Knowledge population — seed the database with armor expertise
   ═══════════════════════════════════════════════════════════════════════ */

static void populate_knowledge(MYSQL *conn)
{
    printf(C_CYAN "  Populating Armorer Steve's knowledge base...\n" C_RESET);

    /* Check if already populated */
    mysql_query(conn, "SELECT COUNT(*) FROM knowledge_base");
    MYSQL_RES *res = mysql_store_result(conn);
    if (res) {
        MYSQL_ROW row = mysql_fetch_row(res);
        if (row && atoi(row[0]) > 10) {
            printf(C_DIM "  Already populated (%s entries). Use --populate --force to refresh.\n" C_RESET, row[0]);
            mysql_free_result(res);
            return;
        }
        mysql_free_result(res);
    }

    /* Knowledge entries */
    const char *knowledge[] = {
        /* Forging Methods */
        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is plate armor?', 'Plate armor is personal body armor made from large metal plates, typically steel or iron. Historically worn from the late medieval period (14th-17th century), it provides excellent protection against slashing and piercing weapons. Modern reproductions use spring steel (1075, 1080, 1095 carbon steel) or stainless variants for display.', 'fundamentals', 95)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What metals are used in armor?', 'Historical: wrought iron, low-carbon steel, case-hardened iron. Modern: 1075/1080/1095 high-carbon spring steel (most popular for functional armor), 4130 chromoly (aircraft-grade), 304/316 stainless (display), titanium Grade 2/5 (lightweight combat). Thickness ranges 16-18 gauge (1.2-1.6mm) for most plate pieces.', 'materials', 92)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('How do you forge plate armor?', 'The process: 1) Pattern/template creation from measurements. 2) Cut steel blanks (plasma, shear, or angle grinder). 3) Hot forging at 800-1000°C for shaping (dishing, raising). 4) Cold working for detail and hardening. 5) Heat treatment (normalize, harden, temper to 350-400°F spring temper). 6) Grinding, filing, polishing. 7) Assembly with rivets, leather straps, buckles. A full harness takes 200-800 hours depending on complexity.', 'forging', 90)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is the difference between hot and cold forging?', 'Hot forging heats steel to 800-1100°C (cherry red to orange), making it malleable for major shaping — dishing, raising, drawing. Cold forging works steel at room temperature for precision: planishing, detail work, and work-hardening the surface. Most armorers use a combination: hot forge for primary curves, cold work for finishing and hardening.', 'forging', 88)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is tempering?', 'Tempering is reheating hardened steel to a specific temperature (300-700°F) to reduce brittleness while retaining hardness. For armor, a spring temper (350-425°F, straw-to-light-blue color) gives the ideal balance: hard enough to resist cuts, flexible enough to absorb impacts without cracking. Over-temper = too soft. Under-temper = too brittle.', 'metallurgy', 93)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is modern metal theory for armor?', 'Modern armor metallurgy focuses on: 1) Microstructure control (martensite vs. bainite vs. pearlite). 2) Grain refinement via controlled forging temperature. 3) Alloy selection for purpose (Mn for hardness, Cr for corrosion resistance, V for grain refinement). 4) Differential hardening (hard face, tough core). 5) Surface treatments (case hardening, nitriding). The goal is maximum energy absorption per unit weight.', 'metallurgy', 87)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What tools do I need to start armoring?', 'Essential startup: 1) Anvil (100-300 lb, $200-2000). 2) Ball-peen and cross-peen hammers (various sizes, $30-80 each). 3) Raising stakes and mandrels ($50-300 each). 4) Forge or torch (gas forge $200-800, coal forge $150-500). 5) Angle grinder ($50-150). 6) Bench vise ($100-400). 7) Swage blocks and dishing stumps ($100-500). 8) Files, tongs, pliers set ($100-300). 9) Safety gear: leather apron, face shield, ear protection ($100-200). Total startup: $1500-6000.', 'equipment', 91)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('How much does it cost to set up an armor forge?', 'Budget tiers: HOBBY ($1500-3000): portable gas forge, basic anvil, essential hand tools. SEMI-PROFESSIONAL ($5000-15000): coal or large gas forge, quality anvil, power hammer or hydraulic press, full stake set, grinding station. PROFESSIONAL ($20000-60000): industrial power hammer, hydraulic press, multiple forges, English wheel, full polishing station, dedicated workshop space. Does not include building/rent ($500-2000/month).', 'costs', 94)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('Who are famous historical armorers?', 'Notable: 1) Lorenz Helmschmid (Augsburg, 1467-1516) — armorsmith to Emperor Maximilian I. 2) Kolman Helmschmid (son, continued the legacy). 3) The Missaglia family (Milan, 15th c.) — finest Italian armorers. 4) Greenwich Armourers (England, 1515-1637) — Royal workshops. 5) Filippo Negroli (Milan, 1510-1579) — extraordinary embossed parade armor. 6) Anton Peffenhauser (Augsburg, 1525-1603) — late period master.', 'history', 90)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('Who are modern armorers?', 'Active modern armorers: 1) Jeffrey Wasson (USA) — HEMA and SCA combat armor. 2) Ugo Serrano (MercuryForgeworks, USA) — historically accurate plate. 3) Eric Dubé (Les Artisans du Fer, Canada) — tournament harnesses. 4) Robert MacPherson (UK) — museum-quality reproductions. 5) Andrey Galevskyi (Age of Craft, Ukraine) — competitive HMB/BUHURT armor. 6) Illusion Armoring (Poland) — mass production for BUHURT. 7) Arms & Armor (Minneapolis) — swords and armor research.', 'modern', 88)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What are armor competition series?', 'Major series: 1) BUHURT League / HMB (Historical Medieval Battles) — full-contact international team combat. 2) IMCF (International Medieval Combat Federation) — world championships. 3) SCA (Society for Creative Anachronism) — rattan combat, armor standards. 4) ACL (Armored Combat League) — US chapter of HMB. 5) Battle of the Nations (BotN) — annual world championship since 2009. 6) HEMA (Historical European Martial Arts) — primarily swordsmanship with lighter armor requirements.', 'competition', 89)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('Who decides armor regulations?', 'Regulatory bodies: 1) HMBIA (Historical Medieval Battle International Association) — international HMB rules, armor thickness/material specs. 2) IMCF Technical Committee — equipment standards for world championships. 3) SCA Marshal community — standards for SCA combat (differs from HMB). 4) National federations (ACL-USA, UK chapter, etc.) apply international rules locally. 5) For real military body armor: NIJ (National Institute of Justice) sets ballistic standards; NATO STANAG 4569 for vehicle armor.', 'regulations', 91)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('Where is armor traded?', 'Trading venues: 1) Specialist makers (direct commission, 3-12 month wait). 2) Facebook groups: \"Medieval Armour for Sale\", \"SCA Armor Trading Post\", \"HMB Armor Market\". 3) Armored Combat Sports forums. 4) Etsy/custom shops for display pieces. 5) Auction houses (Christie\\'s, Sotheby\\'s) for historical pieces ($10K-2M+). 6) Bulk suppliers: India/Pakistan (budget), Ukraine/Poland (competition), Italy (high-end historical). 7) Events: Pennsic War, Gulf Wars, Battle of the Nations vendor areas.', 'trade', 87)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What is a final capacitor trade in armoring?', 'The final capacitor trade refers to the culminating exchange in a series or tournament where the winning armorer or team trades their highest-grade equipment. In competitive armoring, a capacitor grade represents the stored capability of a forge — its accumulated skill, tooling, and material investment. A Grade A capacitor forge can produce tournament-winning harnesses; the trade is the right to commission from that forge at preferential rates, often awarded to series champions.', 'trade', 80)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('What are armor thickness requirements for competition?', 'HMBIA/HMB standards: Helmet — 2.0mm steel minimum (2.5mm for faceplate). Body plates — 1.5mm minimum. Limb protection — 1.0mm minimum. No titanium below 1.2mm. Stainless steel requires +0.5mm over carbon steel minimums. All edges must be rolled or folded. No sharp protrusions. Historical accuracy is not required for HMB — function and safety over form.', 'regulations', 92)",

        "INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES "
        "('How much does a full suit of armor cost?', 'Price ranges: BUDGET ($800-2000): Indian/Pakistani production, basic shapes, mild steel. COMPETITION ($2500-6000): Ukrainian/Polish workshops, HMB-legal, properly hardened. CUSTOM ($5000-15000): Made-to-measure by named armorers, spring steel, fitted. MUSEUM-QUALITY ($15000-80000+): Historically accurate reproductions, hand-forged, period techniques, etching/gilding. ANTIQUE: genuine 15th-16th century pieces fetch $50K-2M+ at auction depending on provenance and condition.', 'costs', 93)",

        NULL
    };

    for (int i = 0; knowledge[i] != NULL; i++)
        mysql_query(conn, knowledge[i]);

    /* Cost estimates */
    const char *costs[] = {
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Anvil (100 lb)', 'Cast iron or steel anvil, farrier or blacksmith pattern', 150.00, 600.00, 'equipment', 'Centaur Forge, Amazon')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Anvil (250 lb)', 'Professional forged steel anvil, London or double-horn pattern', 800.00, 2500.00, 'equipment', 'Peddinghaus, Ridgid, NC Tool Co')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Gas Forge (2-burner)', 'Propane forge suitable for heating plate steel blanks', 250.00, 800.00, 'equipment', 'Hell Forge, Majestic Forge, NC Whisper')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Coal Forge', 'Traditional coal/coke forge with hand-crank or electric blower', 150.00, 600.00, 'equipment', 'Centaur Forge, custom built')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Power Hammer (25 lb)', 'Mechanical power hammer for primary forming of plate', 3000.00, 8000.00, 'equipment', 'Anyang, Big BLU, Iron Kiss')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Hydraulic Press (20 ton)', 'H-frame press with custom dies for dishing and forming', 1500.00, 5000.00, 'equipment', 'Harbor Freight + custom tooling')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Ball Peen Hammer Set', '4-piece set: 8oz, 16oz, 24oz, 32oz', 40.00, 120.00, 'hand_tools', 'Picard, Peddinghaus, Stanley')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Cross Peen Hammer Set', 'Specialized armoring hammers for raising and planishing', 60.00, 200.00, 'hand_tools', 'Picard, custom from blacksmith supply')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Raising Stakes (set of 6)', 'T-stakes and mushroom stakes for forming curves', 200.00, 800.00, 'hand_tools', 'Pepe Tools, custom cast')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Dishing Stump/Form', 'Hardwood or steel dishing form for concave shapes', 50.00, 200.00, 'hand_tools', 'Custom carved or cast')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Angle Grinder', '4.5 inch variable speed with cutting/grinding discs', 50.00, 200.00, 'power_tools', 'DeWalt, Makita, Metabo')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Belt Grinder (2x72)', 'Primary shaping and finishing tool for armor plates', 500.00, 3000.00, 'power_tools', 'Grizzly, KMG, Beaumont')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('English Wheel', 'For compound curves and smooth planishing of large plates', 400.00, 3000.00, 'power_tools', 'Eastwood, Mittler Bros, Pettingell')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Bench Vise (6 inch)', 'Heavy-duty leg vise or bench vise for holding work', 100.00, 500.00, 'equipment', 'Yost, Wilton, post vise (antique)')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Tong Set (6 piece)', 'Flat, wolf-jaw, V-bit, scrolling, bolt, and farrier tongs', 80.00, 300.00, 'hand_tools', 'NC Tool Co, Blacksmith Depot')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Steel Sheet — 1095 (4x8 ft, 16ga)', 'High-carbon spring steel sheet for armor plates', 200.00, 400.00, 'materials', 'New Jersey Steel Baron, Admiral Steel, Metals Depot')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Steel Sheet — 4130 (4x8 ft, 14ga)', 'Aircraft-grade chromoly for premium armor', 350.00, 700.00, 'materials', 'Aircraft Spruce, Online Metals')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Rivets (bag of 100)', 'Steel dome-head rivets for armor assembly', 8.00, 25.00, 'materials', 'Armoring supply shops, McMaster-Carr')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Leather Strapping (10 ft)', 'Veg-tanned leather for straps and linings', 20.00, 60.00, 'materials', 'Tandy Leather, Springfield Leather')",
        "INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES ('Safety Equipment Set', 'Leather apron, face shield, ear muffs, welding gloves', 100.00, 250.00, 'safety', 'Amazon, local welding supply')",
        NULL
    };

    for (int i = 0; costs[i] != NULL; i++)
        mysql_query(conn, costs[i]);

    /* Known armorers */
    const char *armorers[] = {
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Jeffrey Wasson', 'USA', 'HEMA/SCA combat harnesses, custom fitted plate', 'modern', 'Multiple SCA Crown Tournament winners outfitted', 12)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Ugo Serrano (MercuryForgeworks)', 'USA', 'Historically accurate 14th-15th century reproductions', 'modern', 'Museum commissions, Higgins Armory collaboration pieces', 3)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Eric Dubé (Les Artisans du Fer)', 'Canada', 'Tournament and jousting harnesses', 'modern', 'World Jousting Championship armor, custom destrier barding', 8)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Robert MacPherson', 'Scotland, UK', 'Museum-quality Gothic and Milanese reproductions', 'modern', 'Wallace Collection commissions, Royal Armouries Leeds display', 5)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Andrey Galevskyi (Age of Craft)', 'Ukraine', 'BUHURT/HMB competition armor, battle-tested designs', 'modern', '3x Battle of the Nations team champion armorer', 22)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Illusion Armoring', 'Poland', 'Mass-production BUHURT armor, affordable competition plate', 'modern', 'Outfitter for 40+ national HMB teams worldwide', 45)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Lorenz Helmschmid', 'Augsburg, Germany', 'Imperial court armorer, Gothic plate', 'historical (1467-1516)', 'Armor of Emperor Maximilian I (Kunsthistorisches Museum)', 0)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Filippo Negroli', 'Milan, Italy', 'Embossed parade armor, all antica style', 'historical (1510-1579)', 'Burgonet of Charles V (Met Museum), extraordinary repoussé', 0)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('The Missaglia Workshop', 'Milan, Italy', 'Export-quality Milanese armor for European courts', 'historical (15th century)', 'Supplied armor to half of European nobility, Churburg Castle collection', 0)",
        "INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES ('Greenwich Royal Armoury', 'Greenwich, England', 'English court armor, garnitures', 'historical (1515-1637)', 'Armor of Henry VIII, Greenwich garnitures (Tower of London)', 0)",
        NULL
    };

    for (int i = 0; armorers[i] != NULL; i++)
        mysql_query(conn, armorers[i]);

    /* Regulations */
    const char *regs[] = {
        "INSERT IGNORE INTO regulations (body, regulation_name, scope, description, series) VALUES ('HMBIA', 'Equipment Standard 2024', 'International', 'Helmet: 2.0mm min (2.5mm face). Body: 1.5mm. Limbs: 1.0mm. Stainless +0.5mm. All edges rolled. No projections. Helmet must have face grill or solid visor with eye slot max 35mm height.', 'HMB/BUHURT')",
        "INSERT IGNORE INTO regulations (body, regulation_name, scope, description, series) VALUES ('IMCF', 'Technical Rules 2024', 'World Championship', 'Similar to HMBIA with additional: titanium min 1.2mm. Helmet padding 15mm+. No PVC/plastic structural components. Weight class limits per category. 3-judge inspection before each bout.', 'IMCF World')",
        "INSERT IGNORE INTO regulations (body, regulation_name, scope, description, series) VALUES ('SCA', 'Marshal Handbook — Armor Standards', 'SCA worldwide', 'Rigid material (steel, aluminum, hardened leather) covering critical areas. Minimum 16-gauge steel or equivalent. Helm must withstand 12-lb weight drop from 6 ft. Gorget or equivalent throat protection mandatory.', 'SCA Heavy Combat')",
        "INSERT IGNORE INTO regulations (body, regulation_name, scope, description, series) VALUES ('ACL', 'Armored Combat League Rules (USA)', 'USA national', 'Follows HMBIA base standard with additions: competitor must demonstrate helm holds after 3 clean strikes. Polearm regulations stricter. Shield construction must pass flex test.', 'ACL National')",
        "INSERT IGNORE INTO regulations (body, regulation_name, scope, description, series) VALUES ('NIJ', 'NIJ Standard 0101.07', 'US Law Enforcement', 'Ballistic body armor classification: Level IIA, II, IIIA (handgun), III, IV (rifle). Not applicable to medieval armor but referenced for modern protective equipment standards.', 'Military/LE')",
        "INSERT IGNORE INTO regulations (body, regulation_name, scope, description, series) VALUES ('NATO', 'STANAG 4569', 'NATO military', 'Standardization Agreement for vehicle and personal armor protection levels 1-6. Kinetic energy and blast protection standards.', 'Military')",
        NULL
    };

    for (int i = 0; regs[i] != NULL; i++)
        mysql_query(conn, regs[i]);

    printf(C_GOLD "  ✓ Knowledge base populated.\n" C_RESET);
}

/* ═══════════════════════════════════════════════════════════════════════
   Query the knowledge base
   ═══════════════════════════════════════════════════════════════════════ */

static int query_knowledge(MYSQL *conn, const char *input, char *response, int maxlen)
{
    char escaped[MAX_INPUT * 2 + 1];
    mysql_real_escape_string(conn, escaped, input, strlen(input));

    char query[MAX_INPUT * 3];
    snprintf(query, sizeof(query),
        "SELECT answer, category, confidence FROM knowledge_base "
        "WHERE MATCH(question, answer) AGAINST ('%s' IN NATURAL LANGUAGE MODE) "
        "ORDER BY confidence DESC LIMIT 1", escaped);

    if (mysql_query(conn, query) != 0)
    {
        /* Fallback: LIKE search */
        snprintf(query, sizeof(query),
            "SELECT answer, category, confidence FROM knowledge_base "
            "WHERE question LIKE '%%%s%%' OR answer LIKE '%%%s%%' "
            "ORDER BY confidence DESC LIMIT 1", escaped, escaped);
        mysql_query(conn, query);
    }

    MYSQL_RES *res = mysql_store_result(conn);
    if (res)
    {
        MYSQL_ROW row = mysql_fetch_row(res);
        if (row)
        {
            snprintf(response, maxlen, "[%s, confidence: %s%%] %s", row[1], row[2], row[0]);
            mysql_free_result(res);

            /* Increment access count */
            snprintf(query, sizeof(query),
                "UPDATE knowledge_base SET access_count = access_count + 1 "
                "WHERE question LIKE '%%%s%%' OR answer LIKE '%%%s%%' LIMIT 1", escaped, escaped);
            mysql_query(conn, query);
            return 1;
        }
        mysql_free_result(res);
    }

    /* Try armorers table */
    snprintf(query, sizeof(query),
        "SELECT name, location, specialty, era, notable_works, series_wins FROM armorers "
        "WHERE name LIKE '%%%s%%' OR specialty LIKE '%%%s%%' OR location LIKE '%%%s%%' LIMIT 3",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0)
    {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0)
        {
            char *p = response;
            int remaining = maxlen;
            int n = snprintf(p, remaining, "Known armorers matching your query:\n");
            p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 200)
            {
                n = snprintf(p, remaining, "  • %s (%s) — %s [%s]. Wins: %s. %s\n",
                    row[0], row[1], row[2], row[3], row[5], row[4] ? row[4] : "");
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try cost table */
    snprintf(query, sizeof(query),
        "SELECT item, description, cost_low, cost_high, currency, source FROM cost_estimates "
        "WHERE item LIKE '%%%s%%' OR description LIKE '%%%s%%' OR category LIKE '%%%s%%' LIMIT 5",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0)
    {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0)
        {
            char *p = response;
            int remaining = maxlen;
            int n = snprintf(p, remaining, "Cost estimates:\n");
            p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 200)
            {
                n = snprintf(p, remaining, "  • %s: $%s–$%s %s — %s (Source: %s)\n",
                    row[0], row[2], row[3], row[4], row[1], row[5]);
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    /* Try regulations */
    snprintf(query, sizeof(query),
        "SELECT body, regulation_name, scope, description, series FROM regulations "
        "WHERE body LIKE '%%%s%%' OR description LIKE '%%%s%%' OR series LIKE '%%%s%%' LIMIT 3",
        escaped, escaped, escaped);
    if (mysql_query(conn, query) == 0)
    {
        res = mysql_store_result(conn);
        if (res && mysql_num_rows(res) > 0)
        {
            char *p = response;
            int remaining = maxlen;
            int n = snprintf(p, remaining, "Regulations:\n");
            p += n; remaining -= n;
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res)) && remaining > 200)
            {
                n = snprintf(p, remaining, "  • [%s] %s (%s, %s): %s\n",
                    row[0], row[1], row[2], row[4], row[3]);
                p += n; remaining -= n;
            }
            mysql_free_result(res);
            return 1;
        }
        if (res) mysql_free_result(res);
    }

    snprintf(response, maxlen,
        "I don't have specific information on that yet. Try asking about: "
        "plate armor, forging methods, tempering, metal types, tools, costs, "
        "known armorers, competition series (HMB, IMCF, SCA), regulations, "
        "or armor trade. Type 'help' for full topic list.");
    return 0;
}

/* ═══════════════════════════════════════════════════════════════════════
   Store session interaction
   ═══════════════════════════════════════════════════════════════════════ */

static void store_session(MYSQL *conn, const char *question, const char *answer)
{
    char eq[MAX_INPUT * 2 + 1], ea[MAX_RESPONSE * 2 + 1];
    mysql_real_escape_string(conn, eq, question, strlen(question));
    mysql_real_escape_string(conn, ea, answer, strlen(answer));
    char query[MAX_INPUT * 4];
    snprintf(query, sizeof(query),
        "INSERT INTO sessions (question, answer) VALUES ('%s', '%s')", eq, ea);
    mysql_query(conn, query);
}

/* ═══════════════════════════════════════════════════════════════════════
   Banner and help
   ═══════════════════════════════════════════════════════════════════════ */

static void print_banner(void)
{
    printf("\n");
    printf(C_DKBLUE "  ╔══════════════════════════════════════════════════════════════╗  " C_RESET "\n");
    printf(C_DKBLUE "  ║      ARMORER STEVE™ — Plate Armor Q&A & Cost Estimator      ║  " C_RESET "\n");
    printf(C_DKBLUE "  ║      Version %s — MEARVK LLC 2026                        ║  " C_RESET "\n", VERSION);
    printf(C_DKBLUE "  ║      Database: nwe_armorer | MySQL localhost:3306            ║  " C_RESET "\n");
    printf(C_DKBLUE "  ╚══════════════════════════════════════════════════════════════╝  " C_RESET "\n");
    printf("\n");
    printf(C_WHITE "  Ask me about plate armor, forging, metal theory, costs,\n");
    printf("  known armorers, competition series, regulations, or trade.\n");
    printf("  Type 'help' for topics, 'cost' for estimator, 'quit' to exit.\n" C_RESET);
    printf("\n");
}

static void print_help(void)
{
    printf(C_CYAN "\n  ═══ ARMORER STEVE — Topic Guide ═══\n\n" C_RESET);
    printf(C_WHITE "  FUNDAMENTALS:  plate armor, types of armor, history\n");
    printf("  MATERIALS:     steel types, 1095, 4130, titanium, stainless\n");
    printf("  FORGING:       hot forging, cold forging, raising, dishing\n");
    printf("  METALLURGY:    tempering, hardening, heat treatment, grain\n");
    printf("  EQUIPMENT:     tools, hammers, anvils, forges, power hammers\n");
    printf("  COSTS:         shop setup, equipment costs, armor prices\n");
    printf("  ARMORERS:      famous armorers (historical & modern)\n");
    printf("  COMPETITION:   HMB, BUHURT, SCA, IMCF, Battle of Nations\n");
    printf("  REGULATIONS:   armor standards, thickness requirements\n");
    printf("  TRADE:         where to buy, sell, commission armor\n");
    printf("  CAPACITOR:     final capacitor trade, series INT\n" C_RESET);
    printf(C_DIM "\n  Commands: help, cost, sources, regs, quit\n" C_RESET);
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

    /* Command-line mode */
    if (argc > 1)
    {
        if (strcmp(argv[1], "--populate") == 0) { populate_knowledge(conn); mysql_close(conn); return 0; }
        if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) { print_banner(); print_help(); mysql_close(conn); return 0; }
        if (strcmp(argv[1], "--query") == 0 && argc > 2)
        {
            char response[MAX_RESPONSE];
            query_knowledge(conn, argv[2], response, sizeof(response));
            printf("%s\n", response);
            mysql_close(conn);
            return 0;
        }
        if (strcmp(argv[1], "--sources") == 0)
        {
            char response[MAX_RESPONSE];
            query_knowledge(conn, "modern armorers", response, sizeof(response));
            printf("%s\n", response);
            mysql_close(conn);
            return 0;
        }
        if (strcmp(argv[1], "--regs") == 0)
        {
            char response[MAX_RESPONSE];
            query_knowledge(conn, "regulations standards", response, sizeof(response));
            printf("%s\n", response);
            mysql_close(conn);
            return 0;
        }
    }

    /* Interactive mode */
    populate_knowledge(conn);
    print_banner();

    char input[MAX_INPUT];
    char response[MAX_RESPONSE];

    while (1)
    {
        printf(C_GOLD "  armorer-steve> " C_RESET);
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

    printf(C_CYAN "\n  Farewell, armorer. May your steel ring true.\n\n" C_RESET);
    mysql_close(conn);
    return 0;
}
