-- ═══════════════════════════════════════════════════════════════════════════════
-- NWE Fiduciary Module — Legal Bright: INT/IQ Calendar Model
-- The Awareness of Legal Bright Concerning Ideals and Totals
--
-- The INT/IQ Calendar is divided into two halves:
--
--   TOP HALF:  Personal Interests that benefit the County mainly
--              Surrounds equal ideas as brilliant or pertinent
--              Concerns are ideals and totals
--
--   BOTTOM HALF: Treasure for Fiduciary (Treasure Fiduciary)
--                A Treasure Fiduciary can and may approach all law structure
--                as evident. State Nuisance resolved ably and usually as
--                Council. About try (profitable ideas and try-nuisances).
--
-- Database: nwe_fiduciary
-- Author: Max Rupplin — MEARVK LLC
-- Date: August 3 2026
-- ═══════════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: legal_bright
-- The INT/IQ Calendar awareness structure for fiduciary law approach
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS legal_bright (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    calendar_half ENUM('TOP', 'BOTTOM') NOT NULL,
    entry_name VARCHAR(256) NOT NULL,
    concern_type VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
    ideals TEXT,
    totals TEXT,
    benefit_to VARCHAR(128),
    approach_authority VARCHAR(128),
    nuisance_resolution VARCHAR(256),
    council_note TEXT,
    confidence INT DEFAULT 85,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_half (calendar_half),
    INDEX idx_concern (concern_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: treasure_fiduciary
-- When the bottom half of the INT/IQ calendar reveals Treasure for Fiduciary,
-- the Treasure Fiduciary can and may approach all law structure as evident
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS treasure_fiduciary (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    law_structure VARCHAR(256) NOT NULL,
    evidence_basis TEXT NOT NULL,
    approach_type ENUM('DIRECT', 'COUNCIL', 'TRY', 'RESOLUTION') NOT NULL,
    treasure_class VARCHAR(64),
    fiduciary_standing VARCHAR(128),
    nuisance_type VARCHAR(64),
    nuisance_resolution TEXT,
    profitable_idea TEXT,
    try_nuisance TEXT,
    council_resolution TEXT,
    jurisdiction VARCHAR(128),
    confidence INT DEFAULT 85,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_approach (approach_type),
    INDEX idx_treasure_class (treasure_class)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ═══════════════════════════════════════════════════════════════════════════════
-- THE INT/IQ CALENDAR — TOP HALF
-- Personal Interests — County Benefits Mainly
-- Surrounds Equal Ideas as Brilliant or Pertinent
-- Concerns Are Ideals and Totals
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO legal_bright (calendar_half, entry_name, concern_type, description, ideals, totals, benefit_to, approach_authority, confidence) VALUES
('TOP', 'Personal Interest in County Benefit',
 'IDEAL',
 'The top half of the INT/IQ calendar relates to personal interests — but these interests are structured such that the county benefits mainly. Personal interest is not selfish interest; it is invested interest. A person of intelligence invests their interest into the county structure, and the county surrounds those ideas as brilliant or pertinent. The IQ component measures the quality of the investment of interest — higher intelligence produces interests that benefit the county more completely.',
 'That personal interests serve county prosperity. That intelligence directs interest toward collective benefit. That the county recognizes and surrounds brilliant contributions. That pertinent ideas receive equal standing regardless of origin.',
 'Total personal interests invested into county benefit. Total ideas recognized as brilliant or pertinent. Total county benefit derived from the top-half personal interest class.',
 'County (mainly)', 'INT/IQ Calendar — Top Half Authority', 92),

('TOP', 'Equal Ideas as Brilliant or Pertinent',
 'IDEAL',
 'The county surrounds equal ideas as brilliant or pertinent. This means: ideas that serve the county purpose are evaluated on their merit (brilliance) and their relevance (pertinence), not on the social standing of who presents them. An idea from the gentry hero is weighed equally against an idea from a new participant — if both serve county benefit. The word "surrounds" is important: the county does not merely accept ideas, it surrounds them — embraces, protects, implements, and builds upon them.',
 'That brilliant ideas receive county protection. That pertinent ideas receive county implementation. That equality of evaluation serves the county interest. That surrounding an idea means embracing it into county structure.',
 'Total ideas evaluated on merit. Total brilliant ideas implemented. Total pertinent contributions integrated. Total county structural improvements from surrounded ideas.',
 'County (equality of evaluation)', 'INT/IQ Calendar — Brilliance/Pertinence Standard', 90),

('TOP', 'Concerns Are Ideals and Totals',
 'IDEAL',
 'The concerns of Legal Bright at the top half are specifically ideals and totals. An ideal is what should be — the aspirational standard for county governance, fiduciary stewardship, and public trust. A total is what is — the measured sum of performance against that ideal. Legal Bright awareness tracks both: the ideal (where we should be) and the total (where we are). The gap between ideal and total is the concern — the area requiring attention, investment, or correction. This is the fiduciary intelligence: knowing the gap and working to close it.',
 'That ideals are clearly articulated for every county function. That totals are honestly measured against those ideals. That the gap between ideal and total defines the concern priority. That fiduciary intelligence acts on the gap.',
 'Total ideals defined. Total measurements taken. Total gap analyses performed. Total corrective actions initiated from gap awareness.',
 'County (ideal-total governance)', 'Legal Bright — Concern Structure', 91),

('TOP', 'INT Component — Intelligence Invested in County',
 'TOTAL',
 'INT (Intelligence) in this calendar context means the invested intellectual capacity of persons toward county benefit. A person of high INT contributes ideas that are structurally sound, legally viable, and economically productive for the county. The top half of the calendar maps INT to personal interest: the higher the intelligence invested, the more the personal interest aligns with county benefit. This is not IQ as a test score — it is IQ as operational quality of thought applied to fiduciary purpose.',
 'That intelligence is measured by quality of contribution to county. That invested thought produces structural county benefit. That operational intelligence exceeds academic measurement. That personal interest and county benefit converge at high INT.',
 'Total INT invested per calendar period. Total county-benefit ideas produced. Total structural improvements from high-INT personal interest. Total alignment between personal and county benefit.',
 'County (structural benefit from intelligence)', 'INT/IQ Calendar — Intelligence Metric', 89),

('TOP', 'IQ Component — Quality of Ideas Surrounding the County',
 'TOTAL',
 'IQ in this calendar context represents the quality grade of ideas that surround the county. Ideas of high IQ are those that produce multiplied benefit — one good idea creates ten improvements. The calendar tracks: how many high-IQ ideas entered county consideration during the period, how many were recognized as brilliant, how many as pertinent, and how many achieved implementation. The IQ of the county is the aggregate quality of ideas it surrounds and implements. A county that surrounds only mediocre ideas has low collective IQ regardless of individual member scores.',
 'That county IQ is collective, not individual. That idea quality is measured by multiplied benefit. That surrounding high-IQ ideas elevates the county. That implementation is the proof of IQ realization.',
 'Total high-IQ ideas surrounding county per period. Total implementation rate. Total multiplied benefit from quality ideas. Total county IQ elevation measured across periods.',
 'County (collective intelligence elevation)', 'INT/IQ Calendar — Quality Metric', 88);


-- ═══════════════════════════════════════════════════════════════════════════════
-- THE INT/IQ CALENDAR — BOTTOM HALF
-- Treasure for Fiduciary
-- A Treasure Fiduciary Can and May Approach All Law Structure as Evident
-- State Nuisance Resolved Ably and Usually as Council
-- About Try (Profitable Ideas and Try-Nuisances)
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO legal_bright (calendar_half, entry_name, concern_type, description, ideals, totals, benefit_to, approach_authority, nuisance_resolution, council_note, confidence) VALUES
('BOTTOM', 'Treasure for Fiduciary',
 'TREASURE',
 'The bottom half of the INT/IQ calendar is treasure for fiduciary. Treasure here means: the accumulated value, knowledge, precedent, standing, and capability that belongs to the fiduciary role. When the calendar turns to its bottom half, the fiduciary accesses their treasure — the full corpus of authority, evidence, and approach that their position entitles them to. The treasure is not hidden — it is the natural yield of the fiduciary position operating in the bottom half of the calendar cycle.',
 'That fiduciary treasure is earned through calendar operation. That the bottom half reveals what the top half invested. That treasure includes authority, evidence, standing, and capability. That the fiduciary position naturally yields treasure through proper stewardship.',
 'Total treasure accumulated per fiduciary cycle. Total authority accrued. Total evidence gathered. Total capability developed. Total approach options revealed.',
 'Fiduciary (position and standing)', 'Treasure Fiduciary — Full Calendar Authority',
 NULL, NULL, 93),

('BOTTOM', 'Treasure Fiduciary Approaches All Law Structure as Evident',
 'TREASURE',
 'A Treasure Fiduciary can and may approach all law structure as evident. This is the key insight of Legal Bright: when a fiduciary has accumulated treasure (authority, precedent, standing, knowledge) through proper calendar operation, they gain the ability to approach any law structure with evidence already in hand. The law structure is not opaque to them — it is evident, meaning: visible, clear, provable, and approachable. "Can" means capability. "May" means permission. The Treasure Fiduciary possesses both.',
 'That law structure is evident to the prepared fiduciary. That treasure confers both capability and permission. That approach is direct — no structural barrier remains. That evidence makes all law structure transparent and navigable.',
 'Total law structures approached as evident. Total successful approaches. Total evidence packages deployed. Total permissions exercised by Treasure Fiduciary standing.',
 'Fiduciary (all law structure access)', 'Treasure Fiduciary — Evident Approach Authority',
 NULL, NULL, 94),

('BOTTOM', 'State Nuisance — Resolved Ably as Council',
 'NUISANCE',
 'The bottom half of the calendar also contains State Nuisance — impediments, friction, bureaucratic obstruction, legal complexity, and procedural difficulty that the state generates through its normal operation. These nuisances are resolved ably and usually as Council. Council means: deliberation, advice, gathered wisdom, legal representation, and structured resolution process. The nuisance is not ignored — it is resolved. Ably means with competence and skill. Usually means this is the normal path — Council is the standard resolution mechanism for State Nuisance.',
 'That state nuisance is acknowledged as real and legitimate concern. That resolution is through Council (deliberation, advice, wisdom). That resolution is able — competent and skilled. That Council is the usual and standard mechanism.',
 'Total state nuisances identified per period. Total resolutions achieved through Council. Total average time to resolution. Total competence rating of Council resolution.',
 'County and Fiduciary (nuisance clearance)', 'Council — Standard Resolution Authority',
 'State Nuisance is resolved ably and usually as Council. The Council approach means: gather the relevant parties, deliberate with full evidence, apply wisdom and precedent, and issue resolution. Able resolution means competent — not hasty, not delayed, but skilled and timely.',
 'Council is the standing body or process through which State Nuisance finds resolution. It may be a county council, a legal council (counsel), or a council of advisors. The word serves double duty: the body (council) and the advice (counsel). Both meanings apply. State Nuisance that persists without Council resolution becomes a systemic failure — the calendar tracks this.', 91),

('BOTTOM', 'About Try — Profitable Ideas',
 'TRY',
 'About Try: the bottom half of the calendar concerns "try" — the attempt, the venture, the profitable idea put into action. A profitable idea is one that generates value when attempted. The fiduciary who has accumulated treasure through proper calendar operation is positioned to try — to put profitable ideas into action with confidence that their standing, evidence, and approach authority support the venture. Try is not reckless — it is informed by the top half (personal interest invested in county benefit) and backed by the bottom half (treasure, evidence, approach authority).',
 'That profitable ideas emerge from proper calendar operation. That trying is informed by accumulated treasure. That profit means value generated — not merely monetary but structural, social, legal value. That the fiduciary position authorizes and supports the try.',
 'Total profitable ideas identified per period. Total ideas attempted (tried). Total success rate of tries. Total value generated from profitable tries. Total learning from unsuccessful tries.',
 'Fiduciary and County (value generation)', 'Treasure Fiduciary — Try Authority',
 NULL,
 'The try is the action component of the bottom-half calendar. Without try, treasure remains latent. Without treasure, try is uninformed. The calendar cycle produces both: treasure (from proper stewardship in prior cycles) and try (the application of that treasure to new profitable ventures).', 89),

('BOTTOM', 'Try-Nuisances — Nuisance Resolution Through Attempt',
 'TRY',
 'Try-Nuisances are the nuisances that arise specifically from attempts — from tries. When a profitable idea is put into action, it may encounter friction: regulatory resistance, procedural obstruction, competitor interference, or systemic inertia. These are try-nuisances. They are distinct from State Nuisance (which exists independently) in that they arise specifically because someone tried something. Try-nuisances are resolved through the same Council mechanism, but with the additional context that the try was authorized by Treasure Fiduciary standing — the nuisance arose from a legitimate exercise of fiduciary authority.',
 'That try-nuisances are a natural consequence of legitimate fiduciary action. That they do not delegitimize the try. That Council resolves them with awareness of the try authority. That resolution preserves the profitable idea while clearing the nuisance.',
 'Total try-nuisances encountered per period. Total resolved through Council. Total that blocked the try. Total that were cleared allowing the try to succeed. Total learning from try-nuisance patterns.',
 'Fiduciary (clearance of attempt-friction)', 'Council — Try-Nuisance Resolution',
 'Try-nuisances resolve through Council the same as State Nuisance — ably and usually. The additional context is: this nuisance arose from an authorized try. The Council considers whether the try was properly founded (backed by treasure, informed by top-half investment) before resolving the nuisance. A properly founded try receives favorable nuisance resolution.',
 'Spelling note: Nuisance (standard). The concept is clear: an impediment that arises from trying something legitimate. In law, a nuisance is an interference with the use and enjoyment of property or rights. A try-nuisance is interference with the exercise of fiduciary authority in pursuit of profitable ideas. Both are resolved through Council.', 88);


-- ═══════════════════════════════════════════════════════════════════════════════
-- TREASURE FIDUCIARY — Law Structure Approach Evidence
-- When a Treasure Fiduciary approaches law structure, these are the evidence
-- forms and approach types available
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO treasure_fiduciary (law_structure, evidence_basis, approach_type, treasure_class, fiduciary_standing, nuisance_type, nuisance_resolution, profitable_idea, try_nuisance, council_resolution, jurisdiction, confidence) VALUES
('Trust Law (Express, Constructive, Resulting)',
 'Full corpus of fiduciary case law from Keech v Sandford (1726) forward. Hague Trust Convention recognition. Uniform Trust Code. State trust statutes. INT/IQ Calendar top-half investment in trust knowledge.',
 'DIRECT', 'Primary Treasure', 'Treasure Fiduciary — Full Approach',
 NULL, NULL,
 'Structuring trusts that serve county benefit through intergenerational wealth preservation. Dynasty trusts, charitable trusts, public benefit trusts.',
 NULL, NULL,
 'All common law jurisdictions; Hague Convention signatories', 94),

('Corporate Fiduciary Law (Directors, Officers, Shareholders)',
 'Delaware Court of Chancery precedent. Business Judgment Rule. Caremark oversight doctrine. Section 102(b)(7) exculpation. Smith v Van Gorkom. Ongoing minister fiduciary duty documentation.',
 'DIRECT', 'Primary Treasure', 'Treasure Fiduciary — Full Approach',
 NULL, NULL,
 'Corporate governance structures that align officer interest with stakeholder benefit. Board composition, oversight mechanisms, accountability frameworks.',
 NULL, NULL,
 'United States (Delaware primary); United Kingdom (Companies Act 2006)', 93),

('County and Municipal Law (Legislature, Tax, Budget)',
 'County Board of Supervisors fiduciary precedent. Government Code §27000.3 (California model). Prudent investor standard for public funds. Tax evidence chain. GFOA reporting standards.',
 'DIRECT', 'County Treasure', 'Treasure Fiduciary — County Approach',
 'STATE_NUISANCE', 'Resolved as Council — county deliberation process with full evidence, applying wisdom and precedent',
 'Long-term fiscal planning as fiduciary duty. Capital improvement programs, pension funding adequacy, infrastructure investment for county benefit.',
 'Regulatory friction in county budgeting process. Inter-departmental conflict over resource allocation.',
 'Council resolution: gather relevant county parties, present fiscal evidence, deliberate on ideal vs. total, issue budget resolution that serves county benefit.',
 'United States (all counties); applicable internationally to local government fiduciary structures', 91),

('International Treaty Law (Hague, UNIDROIT, Santiago)',
 'Hague Trust Convention 1985. UNIDROIT Principles 2016. Santiago Principles 2008. IMF sovereign fund governance papers. Cross-border fiduciary recognition framework.',
 'DIRECT', 'International Treasure', 'Treasure Fiduciary — International Approach',
 'STATE_NUISANCE', 'International nuisance (jurisdictional conflict) resolved through treaty framework and Council of signatory nations',
 'Cross-border fiduciary structures that operate under international treaty protection. Sovereign wealth fund governance. Multi-jurisdictional trust recognition.',
 'Treaty non-recognition in non-signatory states. Civil law jurisdictions lacking trust equivalent.',
 'Council resolution: Hague Conference deliberation; UNIDROIT study groups; Santiago Principles voluntary adoption framework. Able resolution through multilateral agreement.',
 'International (multilateral)', 92),

('State Nuisance Law (Administrative, Regulatory, Procedural)',
 'Administrative Procedure Act. County regulatory frameworks. Licensing requirements. Permit processes. Environmental review. Zoning and land use. The bottom-half calendar evidence of nuisance patterns.',
 'COUNCIL', 'Resolution Treasure', 'Treasure Fiduciary — Nuisance Resolution Standing',
 'STATE_NUISANCE', 'Resolved ably and usually as Council. Standard administrative resolution: petition, hearing, deliberation, decision.',
 'Streamlining administrative process while preserving public protection. Finding the balance between regulatory purpose and procedural burden.',
 'Every attempt to improve county structure encounters some regulatory friction. The try-nuisance is not the enemy — it is the signal that the system is being used.',
 'Council resolution: administrative hearing with full evidence presentation. The Treasure Fiduciary approaches with standing, presents evidence, Council deliberates, nuisance is resolved ably. The usual path.',
 'United States (state and county level); general administrative law principle', 90),

('Profitable Ideas Law (Venture, Investment, Enterprise)',
 'Contract law. Partnership law. LLC formation. Investment advisory fiduciary standard. Venture capital governance. The try-authority from bottom-half calendar operation.',
 'TRY', 'Venture Treasure', 'Treasure Fiduciary — Try Authority',
 'TRY_NUISANCE', 'Try-nuisances from venture resolved through Council with awareness of authorized fiduciary try',
 'New ventures that serve county benefit through employment, tax base expansion, service provision, or structural improvement. The profitable idea is tried with fiduciary backing.',
 'Competitor resistance. Market entry barriers. Regulatory approval delays. Capital formation friction.',
 'Council resolution: present the profitable idea, demonstrate treasure backing, show county benefit alignment, resolve try-nuisance through deliberation. The try proceeds.',
 'United States (commercial law); applicable to all common law entrepreneurial frameworks', 88),

('Evident Law Structure — The Full Approach',
 'All prior categories combined. The Treasure Fiduciary has accumulated standing, evidence, and authority across trust, corporate, county, international, and venture law structures. All are evident — visible, clear, provable, approachable.',
 'RESOLUTION', 'Complete Treasure', 'Treasure Fiduciary — All Law Structure Evident',
 NULL, 'All nuisances resolve through Council with full treasure evidence',
 'The complete fiduciary portfolio: trusts, corporations, county governance, international structures, and profitable ventures — all approached with evident authority.',
 NULL,
 'The final Council resolution: all law structure is evident to the Treasure Fiduciary. No opacity remains. The calendar has cycled through top-half (personal interest benefiting county) and bottom-half (treasure revealed, nuisance resolved, try authorized). The fiduciary stands in full evident position.',
 'Universal — all jurisdictions where fiduciary law is recognized', 95);


-- ═══════════════════════════════════════════════════════════════════════════════
-- LINK: Insert summary into original_documents for cross-reference
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO original_documents (title, category, subcategory, jurisdiction, label, document_text, source_url, source_authority, confidence, relevance_to_minister) VALUES
('Legal Bright — INT/IQ Calendar Model (Top Half)', 'LEGAL_BRIGHT', 'top_half', 'United States / County', 'DOMESTIC',
'The top half of the INT/IQ calendar relates to personal interests structured such that the county benefits mainly. Concerns are ideals and totals. The county surrounds equal ideas as brilliant or pertinent. INT measures intelligence invested in county benefit. IQ measures quality of ideas surrounding the county. The top half is the investment phase: personal interest directed toward county prosperity, measured by ideal (where we should be) and total (where we are). The gap between ideal and total defines the concern priority. Legal Bright awareness tracks both.',
NULL, 'NWE Fiduciary Module — Legal Bright Calendar', 92, 1),

('Legal Bright — INT/IQ Calendar Model (Bottom Half)', 'LEGAL_BRIGHT', 'bottom_half', 'United States / International', 'DOMESTIC',
'The bottom half of the INT/IQ calendar is treasure for fiduciary. A Treasure Fiduciary can and may approach all law structure as evident. The treasure includes: authority, precedent, standing, capability, and evidence accumulated through proper calendar operation. State Nuisance is resolved ably and usually as Council. Try-nuisances (arising from authorized attempts at profitable ideas) resolve through the same Council mechanism with awareness of the try authority. The bottom half is the harvest phase: treasure revealed, nuisance cleared, profitable ideas tried.',
NULL, 'NWE Fiduciary Module — Legal Bright Calendar', 93, 1),

('Treasure Fiduciary — Evident Approach to All Law Structure', 'LEGAL_BRIGHT', 'treasure_fiduciary', 'Universal', 'DOMESTIC',
'When the Treasure Fiduciary has operated through proper INT/IQ calendar cycles — investing personal interest in county benefit (top half) and accumulating treasure through stewardship (bottom half) — they gain evident approach to all law structure. Evident means: visible, clear, provable, approachable. Can means capability. May means permission. The Treasure Fiduciary possesses both. All law structures become navigable: trust law, corporate fiduciary, county and municipal, international treaty, state nuisance (administrative), and profitable venture law. No opacity remains for the properly qualified Treasure Fiduciary.',
NULL, 'NWE Fiduciary Module — Treasure Fiduciary Standing', 94, 1),

('State Nuisance and Council Resolution', 'LEGAL_BRIGHT', 'nuisance', 'United States (state and county)', 'DOMESTIC',
'State Nuisance: impediments, friction, bureaucratic obstruction, and procedural difficulty that the state generates through normal operation. Resolved ably and usually as Council. Council means: deliberation, advice, gathered wisdom, legal representation, and structured resolution process. Ably means with competence and skill. Usually means this is the standard path. Try-nuisances are a subset: nuisances arising specifically from authorized tries at profitable ideas. Both resolve through Council with full treasure evidence. A properly founded try (backed by calendar-accumulated treasure) receives favorable nuisance resolution. Spelling: Nuisance (standard legal term — interference with use and enjoyment of rights).',
NULL, 'NWE Fiduciary Module — Nuisance Resolution', 90, 1);


-- ═══════════════════════════════════════════════════════════════════════════════
-- VIEW: Calendar Summary
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_legal_bright_calendar AS
SELECT
    calendar_half,
    concern_type,
    COUNT(*) AS entries,
    GROUP_CONCAT(entry_name ORDER BY confidence DESC SEPARATOR '; ') AS entry_names,
    AVG(confidence) AS avg_confidence
FROM legal_bright
GROUP BY calendar_half, concern_type
ORDER BY calendar_half DESC, concern_type;


CREATE OR REPLACE VIEW v_treasure_fiduciary_approaches AS
SELECT
    approach_type,
    treasure_class,
    COUNT(*) AS structures_approachable,
    GROUP_CONCAT(law_structure ORDER BY confidence DESC SEPARATOR '; ') AS law_structures,
    AVG(confidence) AS avg_confidence
FROM treasure_fiduciary
GROUP BY approach_type, treasure_class
ORDER BY avg_confidence DESC;


-- ═══════════════════════════════════════════════════════════════════════════════
-- QUERY HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Full calendar view
-- SELECT * FROM v_legal_bright_calendar;

-- All treasure fiduciary approaches
-- SELECT * FROM v_treasure_fiduciary_approaches;

-- Top half concerns (ideals and totals)
-- SELECT entry_name, ideals, totals FROM legal_bright WHERE calendar_half = 'TOP';

-- Bottom half treasure and nuisance
-- SELECT entry_name, description, nuisance_resolution, council_note FROM legal_bright WHERE calendar_half = 'BOTTOM';

-- All law structures the Treasure Fiduciary can approach as evident
-- SELECT law_structure, approach_type, evidence_basis, profitable_idea FROM treasure_fiduciary ORDER BY confidence DESC;

-- State nuisance resolution paths
-- SELECT law_structure, nuisance_type, nuisance_resolution, council_resolution FROM treasure_fiduciary WHERE nuisance_type IS NOT NULL;

-- Try-nuisances specifically
-- SELECT law_structure, try_nuisance, council_resolution FROM treasure_fiduciary WHERE nuisance_type = 'TRY_NUISANCE';
