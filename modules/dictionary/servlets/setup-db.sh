#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Dictionary™ Database Setup
# Defines all rare, new, or system-specific terms used across NWE and the OS.
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating nwe_dictionary database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_dictionary;
USE nwe_dictionary;

-- ───────────────────────────────────────────────────────────────────────
-- Terms: the core dictionary entries
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS terms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    term VARCHAR(128) NOT NULL UNIQUE,
    pronunciation VARCHAR(128),
    part_of_speech ENUM('noun', 'verb', 'adjective', 'adverb', 'concept', 'system', 'protocol', 'module', 'person', 'place') DEFAULT 'noun',
    definition TEXT NOT NULL,
    etymology VARCHAR(512),
    usage_example TEXT,
    related_module VARCHAR(64),
    domain VARCHAR(64),
    first_appearance VARCHAR(256),
    is_system_term BOOLEAN DEFAULT TRUE,
    is_published BOOLEAN DEFAULT TRUE,
    author VARCHAR(128) DEFAULT 'Max Rupplin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_term (term),
    INDEX idx_domain (domain),
    INDEX idx_module (related_module),
    INDEX idx_pos (part_of_speech)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Domains: categorical groupings of terms
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS domains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain_name VARCHAR(64) NOT NULL UNIQUE,
    description VARCHAR(256),
    color VARCHAR(16),
    term_count INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Revisions: immutable edit history
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS term_revisions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    term_id INT NOT NULL,
    old_definition TEXT,
    new_definition TEXT,
    revised_by VARCHAR(128) DEFAULT 'Max Rupplin',
    revised_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_term (term_id),
    FOREIGN KEY (term_id) REFERENCES terms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Cross-references: term relationships
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cross_references (
    id INT AUTO_INCREMENT PRIMARY KEY,
    from_term_id INT NOT NULL,
    to_term_id INT NOT NULL,
    relationship ENUM('synonym', 'antonym', 'related', 'parent', 'child', 'see_also', 'contrast') DEFAULT 'related',
    UNIQUE KEY uk_ref (from_term_id, to_term_id),
    FOREIGN KEY (from_term_id) REFERENCES terms(id),
    FOREIGN KEY (to_term_id) REFERENCES terms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════════════════════════════════════
-- SEED DOMAINS
-- ═══════════════════════════════════════════════════════════════════════
INSERT IGNORE INTO domains (domain_name, description, color) VALUES
    ('Spectrum', 'SpectrumTandem and TandemEquals terminology', '#cc0000'),
    ('Kernel', 'Linux kernel module and system-level terms', '#f59e0b'),
    ('Ethics', 'White Ethics, moral philosophy, system values', '#22c55e'),
    ('Intelligence', 'Dave, AI, reasoning, cognitive systems', '#3b82f6'),
    ('Security', 'HPM, ClamAV, rootkit, encryption terms', '#ef4444'),
    ('Protocol', 'EPMP, NWE TCP, network terminology', '#8b5cf6'),
    ('Identity', 'User classes, nnet, permissions, grading', '#06b6d4'),
    ('Filesystem', 'NEGAMANE, branding, immutability concepts', '#ec4899'),
    ('Module', 'NWE module-specific terminology', '#f97316'),
    ('Architecture', 'System design, build, structure terms', '#6366f1'),
    ('Mathematics', 'Simplex, matrix, curve, computational terms', '#14b8a6'),
    ('Medical', 'System health, diagnostics, certification', '#84cc16'),
    ('Finance', 'ACH, banking, payment processing, fiduciary transfer terms', '#10b981');

-- ═══════════════════════════════════════════════════════════════════════
-- SEED TERMS — Rare, new, or system-specific
-- ═══════════════════════════════════════════════════════════════════════
INSERT IGNORE INTO terms (term, pronunciation, part_of_speech, definition, etymology, usage_example, related_module, domain, first_appearance, author) VALUES

-- Spectrum / TandemEquals terms
('dolyene', 'DOL-ee-een', 'noun',
 'The spectrum of int discipline; the graphical representation of term usage frequency across radix conditions and spelling variants.',
 'Coined for NWE SpectrumTandem. Origin: synthesis of \"dolly\" (gentle movement) + \"-ene\" (substance/essence).',
 'The dolyene of \"spectrum\" shows 95% usage in lowercase, 70% in title case.',
 'SpectrumTandem', 'Spectrum', 'SpectrumTandem v1.0 (July 2026)', 'Max Rupplin'),

('saimptom', 'SAME-tom', 'noun',
 'A choice where both ends are not yet obvious to the chooser. A symptom of decision where the resolution has not collapsed. Merely a choice, but not both ends apparent.',
 'Portmanteau of \"same\" + \"symptom\". Both sides look the same until resolution.',
 'The career saimptom resolved after 12 answers revealed the mono mind was hiding the lateral option.',
 'TandemEquals', 'Spectrum', 'TandemEquals kernel module v1.0 (Aug 2026)', 'Max Rupplin'),

('stereo mind', 'STAIR-ee-oh mind', 'concept',
 'The balanced, two-channel perception that sees real choices and province wisdoms simultaneously. Contrast: mono mind (collapsed single-track thinking that sees only one path).',
 'Audio metaphor. Stereo = two channels. Mono = one channel. Applied to cognitive state.',
 'After 12 answers, TandemEquals restored stereo mind — both career paths were now simultaneously visible.',
 'TandemEquals', 'Spectrum', 'TandemEquals kernel module v1.0 (Aug 2026)', 'Max Rupplin'),

('province wisdom', 'PROV-ince WIZ-dom', 'noun',
 'Wisdom specific to your situation — your province of life. Not universal truth but YOUR truth for YOUR context. Hidden by overconfidence because overconfidence insists on universal answers.',
 'Province = local territory. Wisdom that applies HERE, to YOU, NOW.',
 'Province wisdom: \"In Durham, the lateral career path IS the main path. The straight path is noise here.\"',
 'TandemEquals', 'Spectrum', 'TandemEquals kernel module v1.0 (Aug 2026)', 'Max Rupplin'),

('equal noise', 'EE-kwul noyz', 'noun',
 'The residual ambiguity that remains after saimptom resolution. Made visible and equalized so the person can see what they were dismissing. Not random — it is the other channel that mono mind hid.',
 'What the unkind mind calls \"noise\" is actually valid signal from the other channel.',
 'Equal noise of 420/1000 means 42% genuine ambiguity remains — both options still have real merit.',
 'TandemEquals', 'Spectrum', 'TandemEquals kernel module v1.0 (Aug 2026)', 'Max Rupplin'),

('tandem pass', 'TAN-dem pass', 'noun',
 'The bidirectional matrix computation where each row i sums matrix[i][j] * matrix[j][i]. Consideration × consequence evaluated in lockstep. Produces the choice/noise separation.',
 'Tandem = together. Pass = single traversal. The matrix reads forward AND backward simultaneously.',
 'The tandem pass showed axis 17 as dominant — career creativity scored highest bidirectionally.',
 'TandemEquals', 'Mathematics', 'TandemEquals kernel module v1.0 (Aug 2026)', 'Max Rupplin'),

('radix', 'RAY-dix', 'noun',
 'The root or base form of a term from which spelling variants derive. In SpectrumTandem, the radix anchors a word family.',
 'Latin: radix = root.',
 'Radix \"doly\" anchors: dolyene, Dolyene, DOLYENE, dolyenic.',
 'SpectrumTandem', 'Spectrum', 'SpectrumTandem v1.0 (July 2026)', 'Max Rupplin'),

-- Kernel / System terms
('negamane', 'NEG-ah-mah-nay', 'noun',
 'An immutable filesystem brand. Once applied, a path cannot be altered, deleted, or created into. Only Grade 7+ admin can release. Permanent protective treatment.',
 'Portmanteau suggesting negation of maneuvering — cannot be manipulated.',
 'negamane /home/user/important/ brands the directory as permanently immutable.',
 'Kernel', 'Filesystem', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

('sudo_gate', 'SOO-doh gate', 'system',
 'An 8-level graded privilege system. Standard sudo for grades 1-6. \"touch system\" for grade 7 (critical). \"touch system gate\" for grade 8 (irreversible). Friction proportional to danger.',
 'sudo (superuser do) + gate (controlled passage). The gate IS the friction.',
 'sudo touch system gate dd if=/dev/zero of=/dev/sda requires explicit gate acknowledgment.',
 'Kernel', 'Security', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

('epmp', 'E-P-M-P', 'protocol',
 'Extended Port Multiplexing Protocol. Service on TCP port 64444 that routes traffic to extended ports beyond 2^16 (up to 30 quintillion). Supports DH/RSA handshake and encrypted/raw/hybrid modes.',
 'Extended Port Multiplexing Protocol. Acronym.',
 'EPMP frame header: 42 bytes. Magic: 0x45504D50.',
 'Kernel', 'Protocol', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

('hpm', 'H-P-M', 'system',
 'Heuristic Port Monitor. Three-stage security pipeline (Protocol Framing → Behavioral Heuristics → Response Graphing) for all ports with safety scoring at each stage.',
 'Heuristic Port Monitor. Acronym.',
 'HPM detected a NULL scan pattern — stealth probe blocked at pipe 2.',
 'Kernel', 'Security', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

-- Ethics / Philosophy terms
('white ethics', 'wyte ETH-iks', 'concept',
 'A system-level presence covering the software in a careful aura of elegance and future. Properties: careful, brave, heuristic, elegant, future-facing, calming. The installer grade certifies ethical standing.',
 'White = purity of intent. Ethics = system of moral principle.',
 'During the glow cycle, the system radiates white ethics — the creatures feel calmed.',
 'Kernel', 'Ethics', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

('glow cycle', 'gloh SY-kul', 'noun',
 'A 2-hour period (every 8-36 hours, naturally timed) when the system asserts its health, ethics, and forward presence. The system glows white. Ethics remain active between cycles.',
 'The periodic heartbeat of the White Ethics system.',
 'cat /proc/white_ethics/glow → ◉ GLOWING WHITE. The system is careful.',
 'Kernel', 'Ethics', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

-- Intelligence terms
('palladium grooves', 'pah-LAY-dee-um groovz', 'system',
 'PalladiumGrooves III: Social characterizability scoring in Pi ratio to TandemEquals. 132 groove channels (Pi × 42). Scores -50 to +50. Catches output from TandemEquals choice/noise vectors.',
 'Palladium = precious, stable element. Grooves = channels of analysis.',
 'PalladiumGrooves scored +32 characterizability — outward guesses are socially legible.',
 'TandemEquals', 'Intelligence', 'Ubuntu Determinant Alpha RS Edition 98 (Aug 2026)', 'Max Rupplin'),

('mill matter', 'mill MAT-er', 'noun',
 'PalladiumGrooves IV concept: raw intellectual processables ingested from upstream modules. The mill identifies INT advantages, replaces similars with easier equivalents, and produces forward vectors.',
 'Mill = processing grinder. Matter = substance to be worked.',
 'Mill matter from TandemEquals showed 3 processables ready for advancement (forward score > 80).',
 'TandemEquals', 'Intelligence', 'Ubuntu Determinant Alpha RS Edition 98 (Aug 2026)', 'Max Rupplin'),

('rebate certificate', 'REE-bayt ser-TIF-ih-kit', 'noun',
 'RebateCertificates VIII: identifies longs that look like unnecessaries, checks moral equations, produces Save Me clearances. Cost: 2.25x standard lifetime INT and drift. Costs do NOT reciprocate.',
 'Rebate = return of excess cost. Certificate = formal clearance document.',
 'Rebate certificate issued: the long was indeed unnecessary. Person cleared at no moral cost.',
 'TandemEquals', 'Intelligence', 'Ubuntu Determinant Alpha RS Edition 98 (Aug 2026)', 'Max Rupplin'),

-- Identity / Permission terms
('genius class', 'JEEN-yus klass', 'noun',
 'Permission Class 5. Works freely FOR the system. Not an audit item. Has graduated from auditor class. Supreme-tier access logged for institutional record only.',
 'Genius = exceptional innate capacity. Class = permission tier.',
 'Genius class users bypass DAC entirely. Their work is transparent by nature.',
 'Kernel', 'Identity', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

('trusted class', 'TRUST-ed klass', 'noun',
 'Permission Class 4. Bypasses DAC entirely with light audit trail (access counter). Has established alignment with system integrity. Simple to trace.',
 'Trusted = established reliability. Class = permission tier.',
 'echo \"1000 4 alice\" > /proc/eperm/register — registers alice as Trusted.',
 'Kernel', 'Identity', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

('hobby hole', 'HOB-ee hole', 'noun',
 'A RAM-backed identity space (4-44 MB per user) that grows with adequacy and functional tenure. Part of the nnet identity system.',
 'Hobby = personal interest space. Hole = allocated memory region.',
 'The hobby hole for mearvk grew to 44MB after 3 years of functional tenure.',
 'Kernel', 'Identity', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

-- Module / NWE terms
('strernary', 'STRER-nah-ree', 'noun',
 'The NWE deep inference AI engine. DJL/PyTorch/DistilBERT. Provides ASK, CLASSIFY, TRAIN, RELAY commands. Port 20000 (inference) + Port 2000 (directory).',
 'Coined term. Tri-fold reasoning: structure + ternary + arbitrary.',
 'StrernaryConnector.askHardened() sends trust-aware queries with full metadata.',
 'Strernary', 'Module', 'NitroWebExpress v1.0 (2026)', 'Max Rupplin'),

('cd1 connector', 'see-dee-wun kon-EK-tor', 'system',
 'A circular button (80px desktop / 100px mobile) on every BMA JSP page that opens a floating dialog for TCP protocol interaction. Supports direct port and Strernary routing modes.',
 'CD1 = Connector Dialog 1. First-generation protocol interface button.',
 'Click the CD1 button → select Connect → choose direct port → send STATUS.',
 'Brarner.M.Alete', 'Module', 'Brarner.M.Alete servlets (July 2026)', 'Max Rupplin'),

('memory grain', 'MEM-oh-ree grayn', 'noun',
 'A 3-tier classification for per-user kernel objects: Grain 1 (user space, 4MB, anyone), Grain 2 (safety space, 16MB, sudo 1+), Grain 3 (kernel space, 64MB, sudo 4+). Grains 1-2 bypass secure boot.',
 'Grain = level of fineness/access. Memory = allocated kernel space.',
 'install --grain=2 my_service loads into safety space without triggering secure boot.',
 'Kernel', 'Architecture', 'Ubuntu Determinant Alpha RS Edition 98 (2026)', 'Max Rupplin'),

-- Architecture terms
('simplex', 'SIM-pleks', 'noun',
 'In TandemEquals: the traced path from perception through cognition and modulation to expression. A single traversal through all four layers. Simplex value = integrated signal strength.',
 'Mathematical: a simplex is the simplest polytope in any dimension. Here: simplest complete path.',
 'Control curve \"Focus→Decision\" has simplex value 0.88 — strong traversal.',
 'TandemEquals', 'Mathematics', 'TandemEquals web module (Aug 2026)', 'Max Rupplin'),

('control curve', 'kon-TROHL kurv', 'noun',
 'A complete path through the 4-layer modulator: perception → cognition → modulation → expression. Maps one intake signal through processing and shaping to final output. Measured by simplex value and stability.',
 'Control = governed/directed. Curve = the trajectory through layer space.',
 'The \"Data→Logic→Output\" control curve has 0.98 stability — highly consistent.',
 'TandemEquals', 'Mathematics', 'TandemEquals web module (Aug 2026)', 'Max Rupplin'),

('int discipline', 'int DIS-ih-plin', 'noun',
 'The integer classification system governing term ordering and spectral weight within SpectrumTandem. Each term has an int discipline index determining its position in the dolyene.',
 'Int = integer (mathematical). Discipline = ordered system of classification.',
 'The int discipline of \"dolyene\" is 1 — primary position in its own spectrum.',
 'SpectrumTandem', 'Spectrum', 'SpectrumTandem v1.0 (July 2026)', 'Max Rupplin'),

-- Finance / ACH / Fiduciary terms
('ACH', 'A-C-H', 'noun',
 'Automated Clearing House. Electronic network for financial transactions between banks. Handles direct deposits, bill payments, B2B transfers. Settles in 1-2 business days (standard) or same-day. Governed by NACHA rules.',
 'Acronym: Automated Clearing House. Established 1974.',
 'ACH standard transfers settle in 1-2 business days; same-day ACH settles within hours.',
 'Fiduciary', 'Protocol', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('routing number', 'ROOT-ing NUM-ber', 'noun',
 '9-digit ABA (American Bankers Association) code identifying a financial institution. Validated via weighted checksum: 3(d1+d4+d7) + 7(d2+d5+d8) + (d3+d6+d9) mod 10 == 0.',
 'ABA routing transit number. Introduced 1910 by the American Bankers Association.',
 'Routing number 021000021 identifies JPMorgan Chase. Checksum: 3(0+0+0) + 7(2+0+2) + (1+0+1) = 0+28+2 = 30; 30 mod 10 == 0 ✓.',
 'Fiduciary', 'Protocol', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('Melio', 'MEL-ee-oh', 'noun',
 'Pay-as-you-go ACH platform. Zero-fee standard business transactions. 1% same-day expedited. Connects via Plaid instant link to online banking credentials. Best for zero-fee standard business ACH.',
 'Company name. Latin melio = to improve, make better.',
 'Melio processes zero-fee ACH for standard business payments with Plaid-linked bank accounts.',
 'Kernel', 'Module', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('Moov', 'MOOV', 'noun',
 'API-first payment platform. Pure pay-as-you-go pricing, no monthly fees. Built for developers needing API for two-legged standard and same-day FedNow/RTP settlement windows.',
 'Company name. Stylized \"move\" — moving money programmatically.',
 'Moov API supports standard ACH, same-day ACH, FedNow, and RTP settlement rails.',
 'Kernel', 'Module', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('Stripe', 'stryp', 'noun',
 'Hybrid payment processor. $0/month. ACH: 0.8% capped at $5. Card: 2.9% + $0.30. Best for e-commerce web checkouts, custom code integrations, international currencies.',
 'Company name. Reference to the magnetic stripe on payment cards.',
 'Stripe ACH charges 0.8% per transaction capped at $5 — predictable ceiling for large transfers.',
 'Kernel', 'Module', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('Square', 'skwair', 'noun',
 'Hybrid payment processor. $0/month. ACH: 1% per transaction (min $1). Card: 2.9% + $0.30. Best for quick invoice links, virtual terminals, immediate day-after payouts.',
 'Company name (now Block, Inc.). Named for the square card reader hardware.',
 'Square ACH: 1% per transaction with $1 minimum. Funds available next business day.',
 'Kernel', 'Module', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('Helcim', 'HEL-sim', 'noun',
 'Hybrid payment processor. $0/month. ACH: 0.5% + $0.25 (capped at $6). Card: ~2.27% + $0.25 (Interchange-plus). Best for wholesale, B2B invoicing, automated surcharging.',
 'Company name. Canadian payment processor, interchange-plus model.',
 'Helcim interchange-plus pricing averages 2.27% + $0.25 with automated surcharging available.',
 'Kernel', 'Module', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('FedNow', 'FED-now', 'noun',
 'Federal Reserve instant payment service (2023). Real-time gross settlement, 24/7/365. Transfers complete in seconds, not days. Supported by Moov platform API.',
 'Federal Reserve + Now. Launched July 2023 by the Federal Reserve System.',
 'FedNow settles transfers in seconds — no batching, no waiting for end-of-day clearing.',
 'Fiduciary', 'Protocol', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('RTP', 'R-T-P', 'noun',
 'Real-Time Payments network operated by The Clearing House. Instant settlement for US banks. Available 24/7/365. Complements FedNow as an instant payment rail.',
 'Acronym: Real-Time Payments. Launched 2017 by The Clearing House.',
 'RTP processes instant payments 24/7/365 alongside FedNow as a parallel real-time rail.',
 'Fiduciary', 'Protocol', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('Plaid', 'playd', 'noun',
 'Financial data aggregation platform. Links user bank accounts instantly via online banking credentials. Used by Melio, Stripe, and other payment platforms for bank verification.',
 'Company name. Reference to interwoven connections (plaid pattern = intersecting lines).',
 'Plaid instant link verifies bank accounts in seconds using online banking credentials.',
 'Kernel', 'Module', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('idempotency key', 'eye-dem-POH-ten-see kee', 'noun',
 'Unique identifier sent with payment API requests to prevent duplicate transactions. If the same key is resubmitted, the platform returns the original result without processing again.',
 'Idempotent (mathematics): applying operation multiple times yields same result as applying once. Key = unique identifier.',
 'POST /v1/transfers with Idempotency-Key: uuid-abc-123 — safe to retry on timeout.',
 'Fiduciary', 'Protocol', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('interchange-plus', 'IN-ter-chaynj plus', 'noun',
 'Credit card pricing model where merchant pays actual interchange fee (set by card networks) plus a fixed markup. More transparent than flat-rate. Used by Helcim.',
 'Interchange = fee between banks. Plus = the processors added margin.',
 'Interchange-plus: Visa interchange 1.65% + Helcim markup 0.30% + $0.25 = total 1.95% + $0.25.',
 'Fiduciary', 'Architecture', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('pay-as-you-go', 'pay az yoo GO', 'adjective',
 'Pricing model with no monthly subscription fees. Charges only per transaction. Zero cost when idle. Used by Melio, Moov, Stripe, Square, and Helcim for ACH/card processing.',
 'Common English: pay only for what you use, when you use it.',
 'Pay-as-you-go ACH: $0/month base. Only charged when transfers actually execute.',
 'Fiduciary', 'Architecture', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('surcharging', 'SUR-char-jing', 'noun',
 'Practice of passing payment processing fees directly to the customer as a line item. Automated by Helcim. Legal in most US states for credit cards (not debit).',
 'Sur- (above/additional) + charge. An additional charge above the listed price.',
 'Helcim automated surcharging adds 2.27% to credit card transactions — merchant pays net zero on processing.',
 'Fiduciary', 'Architecture', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('fiduciary', 'fih-DOO-shee-air-ee', 'noun',
 'Person or institution holding legal/ethical obligation to act in anothers best interest. Highest standard of care in law. Applies to trustees, advisors, executors, directors.',
 'Latin fiduciarius, from fiducia (trust). One who holds something in trust for another.',
 'A fiduciary must place the clients interest above their own — the highest legal standard of care.',
 'Fiduciary', 'Architecture', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('global transfer wealth', 'GLOH-bul TRANS-fer welth', 'concept',
 'The balance of internal design and remedy across fiduciary structures. The means by which wealth moves between parties, jurisdictions, and generations while preserving value.',
 'Global = worldwide scope. Transfer = movement between parties. Wealth = accumulated value.',
 'Global transfer wealth mechanisms ensure value preservation across jurisdictional and generational boundaries.',
 'Fiduciary', 'Architecture', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('yield and turn', 'yeeld and tern', 'concept',
 'Yield: return generated by a fiduciary structure over time. Turn: frequency at which yield materializes. Together they define productive capacity of a fiduciary arrangement.',
 'Yield = produce/return. Turn = cycle/rotation. Financial pair measuring rate and frequency of return.',
 'Yield and turn of 4.2% quarterly means 4.2% return materializing every 90 days.',
 'Fiduciary', 'Mathematics', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('polyblend assumption', 'POL-ee-blend ah-SUMP-shun', 'noun',
 'Weighted combination of multiple yield expectations into a single composite projection. Blends fixed income, equity, real assets, and alternatives by reliability weight.',
 'Poly = many. Blend = mix. Assumption = forward projection based on weighted inputs.',
 'Polyblend assumption: 40% fixed (3.8%) + 30% equity (7.2%) + 20% real (5.1%) + 10% alt (9.0%) = 5.58% composite.',
 'Fiduciary', 'Mathematics', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('ach_transfer', 'A-C-H TRANS-fer', 'system',
 'Command-line tool and API for initiating bank-to-bank transfers via Melio, Moov, Stripe, Square, or Helcim. Validates ABA routing numbers, calculates fees, records transfers to MySQL.',
 'ACH = Automated Clearing House. Transfer = movement of funds between accounts.',
 'ach_transfer --platform melio --amount 5000 --routing 021000021 --account 123456789 --memo \"Invoice 4401\"',
 'Kernel', 'Module', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin'),

('NACHA', 'NAH-chah', 'noun',
 'National Automated Clearing House Association. Governs the ACH network rules and standards. Processes over 30 billion transactions annually worth $80+ trillion.',
 'Acronym: National Automated Clearing House Association. Founded 1974.',
 'NACHA rules govern all ACH transactions — file formats, settlement timing, return codes, and compliance.',
 'Fiduciary', 'Protocol', 'FiduciaryServices ACH v1.0 (Aug 2026)', 'Max Rupplin');
"

echo "[OK] nwe_dictionary database ready."
echo "     4 tables: terms, domains, term_revisions, cross_references"
echo "     12 domains seeded. 45+ terms defined."
echo "     Installer Tech ID: Max Rupplin"
