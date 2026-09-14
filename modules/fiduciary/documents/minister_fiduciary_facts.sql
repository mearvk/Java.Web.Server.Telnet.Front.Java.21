-- ═══════════════════════════════════════════════════════════════════════════════
-- NWE Fiduciary Module — Minister Fiduciary Facts & International Law
-- Document Retrieval into Database — Original Documents
--
-- Categories:
--   MINISTER          — Minister's fiduciary position, ongoing corporate finance
--   INTERNATIONAL     — International law (Hague, UNIDROIT, Santiago, cross-border)
--   COUNTY            — County legislature, tax evidence, local fiduciary duty
--   GENTRY_HERO       — The need for a gentry hero from time to time
--   STANDINGS         — Legal standings (who can sue, who has standing)
--   WINNERS           — Who has won from other times already
--   AHEAD             — Forward-facing fiduciary principle and future position
--
-- Database: nwe_fiduciary
-- Author: Max Rupplin — MEARVK LLC
-- Date: August 3 2026
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: original_documents
-- Stores the full research documents as retrieved original material
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS original_documents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(512) NOT NULL,
    category VARCHAR(64) NOT NULL,
    subcategory VARCHAR(64),
    jurisdiction VARCHAR(128),
    label VARCHAR(64) DEFAULT 'DOMESTIC',
    document_text TEXT NOT NULL,
    source_url VARCHAR(512),
    source_authority VARCHAR(256),
    retrieval_date DATE DEFAULT (CURRENT_DATE),
    confidence INT DEFAULT 85,
    relevance_to_minister TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_label (label),
    INDEX idx_jurisdiction (jurisdiction)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 1: MINISTER — Fiduciary Position of the Minister
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO original_documents (title, category, subcategory, jurisdiction, label, document_text, source_url, source_authority, confidence, relevance_to_minister) VALUES
('Minister as Fiduciary — Core Obligation', 'MINISTER', 'duty', 'United States / United Kingdom', 'DOMESTIC',
'A Minister of Corporate Ongoing Finance occupies a fiduciary position by operation of law. The relationship arises because: (1) Authority has been delegated to the minister to act on behalf of the corporate body and its beneficiaries; (2) The minister exercises discretionary powers over assets and interests of others; (3) The minister is in a position superior to that of ordinary stakeholders due to specialized access, knowledge, and ability; (4) The beneficiaries trust the minister will act in their best interest. The minister must exercise the twin pillars of loyalty and care. The duty of loyalty is absolute — self-dealing is forbidden. The duty of care requires the prudence of a reasonably skilled person under similar circumstances. The relationship is ongoing — it does not terminate upon a single transaction but persists for the duration of the appointment.',
'https://www.scu.edu/government-ethics/resources/public-officials-as-fiduciaries/', 'Santa Clara University Markkula Center for Applied Ethics', 93, 1),

('Minister Fiduciary — Conflict of Interest Prevention', 'MINISTER', 'conflicts', 'Canada / Westminster systems', 'DOMESTIC',
'Ministers bear a general duty to arrange private affairs to prevent conflicts of interest. Both members of parliament and ministers in government are expected to promote the interests of constituents and serve the political interests of their parties — but fiduciary duty constrains this to the public good. In Canada, the Conflict of Interest Act imposes explicit duties: no furthering private interests using official information, no preferential treatment, recusal requirements when personal interest intersects with official duty. A finance minister specifically has access to sensitive economic, fiscal, financial, and tax information — the fiduciary standard is heightened because the potential for self-dealing or information advantage is structurally embedded in the role.',
'https://www.canada.ca/en/canadian-heritage/corporate/transparency/open-government/standing-committee/chagger-information-privacy-ethics/summary-rules-ministers.html', 'Government of Canada — Ethics Commissioner', 91, 1),

('Minister as Ongoing Corporate Officer — Fiduciary Continuity', 'MINISTER', 'ongoing', 'United States (all states)', 'DOMESTIC',
'Corporate officers owe fiduciary duties that are continuous and ongoing for the duration of their office. The duty is not episodic — it attaches at appointment and persists until lawful termination. Key attributes of the ongoing fiduciary position: (1) The duty exists even when no specific transaction is being executed; (2) The officer must affirmatively monitor for conflicts and threats to the corporate body; (3) Silence in the face of known harm constitutes breach; (4) Post-departure duties may survive (confidentiality, non-competition, non-solicitation of corporate opportunity during notice period); (5) The ongoing nature means annual certification and continuous disclosure obligations. A minister of corporate ongoing finance bears this standard with the additional weight of public trust — the corporate body extends to all who depend on the finance function.',
'https://aaronhall.com/fiduciary-duties-of-officers-and-directors-of-corporations/', 'Aaron Hall, Attorney (Minnesota)', 90, 1),

('Fiduciary Accountability Regime — Prescribed Responsibilities', 'MINISTER', 'accountability', 'Australia / United Kingdom', 'DOMESTIC',
'Modern financial accountability regimes prescribe specific responsibilities for ministers and senior officers handling public or corporate finance. In Australia, the Financial Accountability Regime (FAR) identifies prescribed positions with individual responsibility for distinct functions: risk management, financial reporting, compliance, human resources conduct, and operational continuity. Accountable officers appointed by the Principal Accountable Officer have a specific responsibility to ensure Best Value arrangements. The Scottish Public Finance Manual likewise requires all Accountable Officers to comply with the duty of Best Value. Individuals are held accountable for stewardship after objectives have been established, responsibility assigned, authority delegated, and resources allocated. This framework directly maps to the minister-fiduciary: objectives → responsibility → authority → resources → accountability.',
'https://treasury.gov.au/sites/default/files/2021-07/c2021-169627-policy-paper.pdf', 'Australian Treasury / Scottish Government', 88, 1),

('Fiduciary Role of Members of Parliament and Ministers', 'MINISTER', 'parliamentary', 'Comparative (Westminster, EU)', 'INTERNATIONAL',
'Both members of parliaments and ministers in government are expected to promote the interests of their constituents and to serve the political interests of their parties when joining the government. The fiduciary framework recognizes that ministers exercise delegated authority on behalf of the sovereign people. This creates a structural fiduciary relationship: the electorate (beneficiary) has delegated governance power to elected and appointed officials (fiduciaries) who must exercise that power for public benefit. The principal-agent relationship is formalized through constitutional convention, statutory mandate, and oath of office. Breach occurs when the minister uses the position for personal enrichment, fails to disclose material conflicts, or acts with gross negligence in stewardship of public resources.',
'https://www.researchgate.net/publication/297375851_The_Fiduciary_Role_of_Members_of_Parliament_and_Ministers', 'ResearchGate — Academic Publication', 87, 1);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 2: INTERNATIONAL — International Fiduciary Law
-- All entries labeled 'INTERNATIONAL'
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO original_documents (title, category, subcategory, jurisdiction, label, document_text, source_url, source_authority, confidence, relevance_to_minister) VALUES
('Hague Trust Convention 1985 — Law Applicable to Trusts', 'INTERNATIONAL', 'treaty', 'Multilateral (14+ signatories)', 'INTERNATIONAL',
'The Convention of 1 July 1985 on the Law Applicable to Trusts and on their Recognition (HCCH 1985 Trusts Convention) specifies the law applicable to trusts and governs the recognition of trusts among Contracting Parties. Key provisions: (1) Trusts created voluntarily and evidenced in writing are covered; (2) The Convention bridges common law trust states and civil law non-trust states; (3) Choice of law rules allow settlors to designate governing law; (4) Recognition principle: a trust validly created under one member state law must be recognized by others; (5) Mandatory rules of the forum state may override (public policy exception); (6) Countries like Italy and the Netherlands now recognize trusts based on this Convention despite civil law tradition. The Convention is administered by the Hague Conference on Private International Law (HCCH). Significance for fiduciary module: cross-border trust arrangements depend on this framework for legal certainty. A minister dealing in global transfer wealth must understand which jurisdictions honor trust arrangements and which require alternative vehicles.',
'https://www.hcch.net/en/instruments/conventions/specialised-sections/trusts', 'Hague Conference on Private International Law (HCCH)', 94, 1),

('UNIDROIT Principles — Commercial Contract Harmonization', 'INTERNATIONAL', 'principles', 'International (UNIDROIT member states)', 'INTERNATIONAL',
'UNIDROIT (International Institute for the Unification of Private Law) studies needs and methods for modernising, harmonising, and co-ordinating private and commercial law between States. The UNIDROIT Principles of International Commercial Contracts (2016 edition) provide a comprehensive framework for cross-border commercial agreements including fiduciary-adjacent concepts: good faith and fair dealing (Article 1.7), duty of confidentiality in negotiations (Article 2.1.16), implied obligations (Article 5.1.2), and duty to cooperate (Article 5.1.3). While not a fiduciary standard per se, these principles establish the baseline ethical obligations between commercial parties that underpin fiduciary relationships in international commerce. They are frequently referenced by arbitral tribunals (ICC, LCIA, SIAC) when parties have not specified governing law.',
'https://www.unidroit.org/instruments/commercial-contracts/unidroit-principles-2016/', 'UNIDROIT (Rome)', 89, 1),

('Santiago Principles — Sovereign Wealth Fund Governance', 'INTERNATIONAL', 'sovereign', 'International (30+ SWFs)', 'INTERNATIONAL',
'The Santiago Principles (Generally Accepted Principles and Practices for Sovereign Wealth Funds, 2008) provide voluntary governance standards for sovereign wealth funds. Key fiduciary principles: (1) SWFs should have a clear legal framework, including their legal structure and relationship to other state bodies (GAPP 1); (2) The policy purpose should be clearly defined and publicly disclosed (GAPP 2); (3) SWF operations and activities in host countries should be conducted in compliance with all applicable regulatory and disclosure requirements (GAPP 15); (4) SWFs fiduciary duty is to act in the best long-term interest of their beneficiaries — the citizenry (GAPP 19); (5) Investment decisions should aim to maximize risk-adjusted financial returns consistent with investment policy (GAPP 19.1). At fifteen years (2023), the principles remain the primary soft-law instrument governing $10+ trillion in sovereign assets. Recent IMF analysis (2026) indicates SWFs operating as parallel fiscal authorities need legal clarity as their scale and mandates expand.',
'https://www.americanbar.org/groups/international_law/resources/international-lawyer/57-1/governing-wealth-of-nations-santiago-principles/', 'American Bar Association — International Law', 92, 1),

('Transnational Formation of Fiduciary Law', 'INTERNATIONAL', 'formation', 'Global (common law + civil law convergence)', 'INTERNATIONAL',
'The trust as a legal institution is gaining ground in civil law jurisdictions, following national recognition of the Hague Trust Convention by countries such as Italy and the Netherlands. This transnational formation represents a convergence where: (1) Common law jurisdictions (England, Australia, Canada, Singapore, USA) possess mature fiduciary frameworks; (2) Civil law jurisdictions (France, Germany, Japan, China) historically lacked trust concepts but now incorporate functional equivalents — fiducie (France), Treuhand (Germany), trust-like structures in Japanese civil code; (3) Mixed systems (South Africa, Scotland, Quebec, Louisiana) blend both traditions. The institutionalization occurs through: treaty adoption, model law reception, judicial cross-referencing, and academic harmonization efforts. For ministers operating in global transfer wealth, this convergence means fiduciary structures are increasingly portable — but jurisdictional nuance remains critical.',
'https://www.cambridge.org/core/books/transnational-fiduciary-law/', 'Cambridge University Press', 88, 1),

('International Fiduciary Obligations — Sovereign Finance Ministers', 'INTERNATIONAL', 'sovereign_minister', 'International (IMF member states)', 'INTERNATIONAL',
'State-administered pension funds and sovereign wealth vehicles are large enough to invest at strategic scale, possess investment horizons measured in decades, and are structurally patient. Ministers of finance across nations bear fiduciary duties to manage sovereign assets prudently. The IMF Working Paper (WP/13/231) identifies governance structures critical for SWF performance: separation of asset owner (ministry/parliament) from asset manager (fund), clear mandate specification, risk tolerance calibration, and accountability mechanisms. The Norwegian Ministry of Finance, for example, serves as the formal owner of the Government Pension Fund Global ($1.7 trillion) while delegating management to Norges Bank Investment Management — a fiduciary chain where the finance minister retains ultimate fiduciary responsibility to the Norwegian people. New York University research (2026) argues for aligning fiduciary duty with strategic competition — sovereign-private partnerships where state fiduciaries partner with private capital for mutual national benefit.',
'https://nyudri.org/publications/allied-sovereign-private-partnerships-aligning-fiduciary-duty-with-strategic-competition/', 'NYU DRI / IMF Working Papers', 90, 1),

('IMF 2026 — Sovereign Wealth Funds Need Legal Clarity', 'INTERNATIONAL', 'regulatory', 'International (all SWF jurisdictions)', 'INTERNATIONAL',
'Funds operating as parallel fiscal authorities and bond buyers without clear fiscal anchoring may risk distorting government budgets, obscuring public debts, and complicating tax treatment cross-border. The IMF (July 2026) identifies that sovereign wealth funds have expanded beyond their original mandates — many now function as quasi-fiscal instruments, development banks, and domestic market stabilizers simultaneously. This mandate expansion creates fiduciary confusion: to whom does the fund owe its primary duty? Citizens (intergenerational savings)? Current government (fiscal stabilization)? Future generations (resource exhaustion)? International creditors (sovereign creditworthiness)? The answer shapes everything: asset allocation, risk tolerance, transparency requirements, and accountability mechanisms. A minister of finance overseeing such vehicles must navigate this multi-principal fiduciary challenge with legal clarity.',
'https://www.imf.org/en/blogs/articles/2026/07/21/sovereign-wealth-funds-need-legal-clarity-as-their-scale-and-mandates-expand', 'International Monetary Fund (IMF)', 91, 1);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 3: COUNTY — County Legislature, Tax Evidence, Local Fiduciary Duty
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO original_documents (title, category, subcategory, jurisdiction, label, document_text, source_url, source_authority, confidence, relevance_to_minister) VALUES
('County Board of Supervisors as Fiduciary — Prudent Investor Standard', 'COUNTY', 'legislature', 'United States (California model)', 'DOMESTIC',
'With regard to county funds deposited in the county treasury, the board of supervisors is the agent of the county who serves as a fiduciary and is subject to the prudent investor standard. California Government Code §27000.3 and §53600.3 state: all governing bodies of local agencies or persons authorized to make investment decisions on behalf of those local agencies investing public funds are trustees and therefore fiduciaries subject to the prudent investor standard. Statutory Investment Objectives (Gov Code §27000.5 and §53600.5): (1) PRIMARY — safeguard the principal of the funds; (2) SECONDARY — meet the liquidity needs of the depositor; (3) THIRD — achieve a return. County treasurers bear personal fiduciary liability for investment decisions. Tax receipts deposited into the county treasury are public trust funds — their management is a fiduciary act. Every tax dollar collected creates a fiduciary obligation from the county to the taxpayer.',
'https://www.treasurer.ca.gov/cdiac/seminars/2008/20081120/1.pdf', 'California State Treasurer — CDIAC', 93, 1),

('County Legislature — Tax Evidence and Fiduciary Accounting', 'COUNTY', 'tax_evidence', 'United States (all states)', 'DOMESTIC',
'County governments collect property tax, sales tax, and various fees — each creating fiduciary obligations. Tax evidence in county fiduciary context: (1) Assessment rolls — the documentary evidence of property values upon which tax liability is computed; (2) Tax receipts — proof of collection creating the fiduciary corpus; (3) Expenditure records — evidence of how fiduciary funds were deployed; (4) Audit reports — the Auditor-Controller provides independent source of financial information and analysis for the public, local governmental agencies, and county departments; (5) Investment reports — quarterly and annual disclosure of how pooled county funds are invested. The GFOA (Government Finance Officers Association) requires fiduciary activities to be reported separately from governmental activities — fiduciary fund financial statements must distinguish between fiduciary assets held in trust and those held as agent. Tax evidence is the documentary chain establishing that the fiduciary relationship exists and funds are properly stewarded.',
'https://www.gfoa.org/materials/accounting-and-financial-reporting-for-fiduciary-activities', 'Government Finance Officers Association (GFOA)', 90, 1),

('Local Elected Officials — Fiduciary Responsibilities', 'COUNTY', 'elected', 'United States (North Carolina model, general applicability)', 'DOMESTIC',
'Fiduciary responsibilities of local elected officials encompass the full spectrum of public trust: budget adoption, expenditure oversight, revenue management, debt authorization, and capital planning. Government ethics refer to the unique set of duties that public officials owe to the public that they serve. These duties arise upon entering the public work force either as an elected representative, an appointed official, or a member of government staff. The relationship between public officials and the public has been described by scholars as fiduciary in nature. Four identifying factors: (1) The beneficiary (public) has delegated authority to the fiduciary (official) to act on its behalf; (2) The fiduciary has discretionary powers over the beneficiary assets or interests; (3) The fiduciary is in a superior position due to specialized access, knowledge, or ability; (4) The beneficiary trusts the fiduciary will act in their best interest. County legislators who vote on appropriations, tax rates, and bond issuances are exercising fiduciary discretion over public wealth.',
'https://sog.unc.edu/courses/fiduciary-responsibilities-local-elected-officials', 'UNC School of Government', 91, 1),

('Public Trusts — Legislature-Enabled Financial Vehicles', 'COUNTY', 'public_trust', 'United States (Oklahoma model)', 'DOMESTIC',
'In Oklahoma, the legislature has enabled the creation of public trusts that are empowered with significant financial flexibility and vested with some of the power and authority of governmental entities. These public trusts can: issue revenue bonds, enter contracts, acquire property, and invest funds — all while bearing fiduciary duty to the public beneficiaries. The hybrid nature (governmental power + trust flexibility) creates unique fiduciary challenges: (1) Who oversees the trustee? (2) What transparency requirements apply? (3) Can beneficiaries (taxpayers) enforce the trust terms? (4) How are conflicts between trust purpose and political objectives resolved? County legislatures that create or authorize public trusts must ensure adequate governance structures — the enabling legislation itself is a fiduciary document that defines the trust relationship between government and citizenry.',
'https://1889institute.org/trust-but-verify-open-government-and-oklahoma-public-trusts/', '1889 Institute — Oklahoma', 87, 1),

('Fiduciary Income Tax — County and State Level', 'COUNTY', 'tax_fiduciary', 'United States (Colorado model, general applicability)', 'DOMESTIC',
'If you are responsible for overseeing an estate or trust, you are the fiduciary of that estate or trust. Estates and trusts can own property and receive income, just like an individual or business. Fiduciary income tax is the tax that is paid on income received by estates and trusts. At the county level, property tax assessment on trust-held real estate creates a two-layer fiduciary interaction: (1) the trustee as fiduciary to the beneficiary must ensure taxes are paid to preserve trust corpus; (2) the county as fiduciary to the public must ensure tax revenues are collected and deployed prudently. Tax evidence in this context includes: fiduciary income tax returns (IRS Form 1041 and state equivalents), county assessment records, trust accounting statements showing tax payments, and audit trails demonstrating proper fiduciary stewardship of both private trust assets and public tax revenues.',
'https://tax.colorado.gov/fiduciary-income-tax-FAQ', 'Colorado Department of Revenue', 88, 1);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 4: GENTRY_HERO — The Need for a Gentry Hero from Time to Time
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO original_documents (title, category, subcategory, jurisdiction, label, document_text, source_url, source_authority, confidence, relevance_to_minister) VALUES
('The Gentry and Fiduciary Stewardship — Historical Foundation', 'GENTRY_HERO', 'history', 'England (historical, 12th century forward)', 'DOMESTIC',
'Feudal accounting was codified in the twelfth century to control the behavior of lords who stood as guardians for underage heirs. The landed gentry bore fiduciary obligations to their tenants, to the Crown, and to the land itself — an obligation of stewardship that predated modern trust law by centuries. The designation landed gentry originally referred to members of the upper class who were landlords and commoners — not peers, but persons of substance who held land, administered estates, and discharged local justice. Their fiduciary role was inherent in their social position: they managed wealth not merely for personal gain but for the continuity of the estate, the welfare of tenants, and the productive capacity of the land. When the system worked, a competent gentleman of the gentry class served as a hero to the community — maintaining roads, funding churches, adjudicating disputes, and ensuring economic continuity through seasons of hardship. The need for such a gentry hero arises periodically: when institutions fail, when professional fiduciaries default, when systems require a person of standing to step forward and exercise careful stewardship.',
'https://ora.ox.ac.uk/objects/uuid:3aeaa887-e57d-41ab-ae9d-e9f1fb14e1f0', 'Oxford University — Fiduciary Principles in English Common Law', 92, 1),

('The Gentry Hero Need — When Systems Require Intervention', 'GENTRY_HERO', 'need', 'Universal (common law jurisdictions)', 'DOMESTIC',
'From time to time, fiduciary systems fail. Professional trustees default. Corporate boards are captured by self-interest. County administrators neglect their obligations. In these moments, the historical pattern shows that a person of gentry character — someone with standing, competence, ethical grounding, and personal resources — steps forward to restore order. This is the gentry hero pattern: (1) Recognition — the hero identifies systemic fiduciary failure before it becomes catastrophic; (2) Standing — the hero possesses legal, financial, or social standing sufficient to intervene; (3) Action — the hero takes corrective action, whether through litigation, replacement of failed fiduciaries, direct management, or institutional redesign; (4) Restoration — the system is returned to proper fiduciary function; (5) Continuity — the hero ensures succession so the repair persists. The £85 million Hertford v Yarmouth family trust dispute demonstrates what happens when gentry stewardship fails and no hero emerges — protracted litigation, dissipated assets, broken family continuity. The Duke of Westminster case (landed gentry, $13B estate) shows the opposite: careful multi-generational stewardship preserving enormous value across centuries.',
'https://www.withersworldwide.com/en-gb/insight/read/marquess-of-hertford-vs-earl-of-yarmouth', 'Withers Worldwide (London)', 88, 1),

('Keech v Sandford 1726 — The Original Fiduciary Hero Case', 'GENTRY_HERO', 'precedent', 'England (Court of Chancery)', 'INTERNATIONAL',
'Keech v Sandford [1726] EWHC J76 is the foundational case in fiduciary law. A trustee held a lease on behalf of an infant beneficiary. When the lease expired and the landlord refused to renew for the infant, the trustee took the lease for himself. Lord Chancellor King held that the trustee must assign the lease to the infant beneficiary and account for all profits. The principle: a fiduciary cannot profit from opportunities arising from their position, even if the beneficiary could not have taken the opportunity themselves. This case established that the fiduciary standard is prophylactic — it prevents the temptation of wrongdoing, not merely the wrongdoing itself. The Lord Chancellor acted as gentry hero: someone with authority, standing, and ethical clarity who intervened to correct fiduciary failure and establish enduring principle. Every modern fiduciary case traces its lineage to this moment.',
'https://en.wikipedia.org/wiki/Keech_v_Sandford', 'English Court of Chancery (1726)', 95, 1),

('Meinhard v Salmon 1928 — Cardozo and the Punctilio of Honor', 'GENTRY_HERO', 'precedent', 'United States (New York)', 'DOMESTIC',
'In Meinhard v. Salmon, 164 N.E. 545 (N.Y. 1928), Justice Benjamin Cardozo articulated the highest expression of fiduciary duty in American law: a fiduciary is held to something stricter than the morals of the marketplace — not honesty alone, but the punctilio of an honor the most sensitive. Salmon was a joint venturer who took a new lucrative lease opportunity for himself without informing Meinhard. The Court held this was a breach of fiduciary duty — the opportunity belonged to the venture. Cardozo served as the judicial gentry hero: a person of exceptional intellect, ethical standing, and judicial authority who set the standard that all subsequent fiduciary relationships must meet. The case demonstrates that fiduciary duty is not mere contract compliance — it is a standard of honor, sensitivity, and selflessness that transcends market morality.',
NULL, 'New York Court of Appeals (1928)', 95, 1),

('The Modern Gentry Hero — When Professional Fiduciaries Fail', 'GENTRY_HERO', 'modern', 'Global (21st century)', 'DOMESTIC',
'The Credit Suisse Trust Limited v Ivanishvili case (Singapore International Commercial Court, 2025) awarded US$742.73 million plus interest and costs for breach of fiduciary duty by a professional trustee. The trust company had managed the assets negligently and with conflicts of interest. The beneficiary had to fight through years of litigation to recover. This case demonstrates the ongoing need for gentry heroes: (1) Professional fiduciaries (banks, trust companies, wealth managers) can fail catastrophically; (2) The beneficiary requires standing, resources, and persistence to enforce their rights; (3) Courts serve as institutional gentry heroes — but only when activated by someone with the will and means to pursue justice; (4) The damages awarded ($742M) reflect the scale of harm when fiduciary duty is breached at institutional level. The pattern repeats across jurisdictions: when the trusted institution fails, someone must step forward — a person of standing, competence, and ethical conviction — to restore the fiduciary order.',
'https://www.judiciary.gov.sg/judgments/case-briefs-by-smu/credit-suisse-trust-limited-v-ivanishvili--bidzina-and-others', 'Singapore International Commercial Court (SICC)', 91, 1);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 5: STANDINGS — Legal Standing (Who Can Sue, Who Has Standing)
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO original_documents (title, category, subcategory, jurisdiction, label, document_text, source_url, source_authority, confidence, relevance_to_minister) VALUES
('Fiduciary Standing — Constitutional Requirements (Thole v US Bank)', 'STANDINGS', 'constitutional', 'United States (Supreme Court)', 'DOMESTIC',
'In Thole v. U.S. Bank (2020), the Supreme Court held 5-4 that retired participants in a defined benefit pension plan lack constitutional standing to sue plan fiduciaries for alleged breach of ERISA fiduciary duties — because they could not show concrete injury (their benefits were still being paid). Standing requires: (1) Injury in fact — concrete and particularized, actual or imminent; (2) Causation — the injury is fairly traceable to the challenged action; (3) Redressability — it is likely the injury will be redressed by a favorable decision. For fiduciary claims, this means: a beneficiary must show actual harm or imminent threat of harm, not merely that the fiduciary acted improperly. This creates a structural problem: the best time to address fiduciary failure is before harm materializes, but the court system requires injury before granting standing. The gentry hero pattern addresses this gap — someone with standing (shareholder, trustee, co-fiduciary, attorney general) who can act preemptively.',
'https://www.verrill-law.com/blog/supreme-court-holds-pension-plan-participants-lack-standing-to-sue-fiduciaries-for-breach-of-duties/', 'Verrill Dana LLP / US Supreme Court', 93, 1),

('Fiduciary Shield Doctrine — Personal Jurisdiction', 'STANDINGS', 'shield', 'United States (Fifth Circuit, 2025)', 'DOMESTIC',
'The Fiduciary Shield Doctrine bars personal jurisdiction over individual corporate officers whose contacts with the forum state were created solely in their corporate capacity. In Savoie (Fifth Circuit, 2025), the court revived this doctrine — the first federal appellate decision since 1985 to withhold jurisdiction under the fiduciary shield. The doctrine protects officers from being hauled into distant courts merely because their corporate duties required interaction with that jurisdiction. Standing implications: (1) Where you sue matters — jurisdiction selection is strategic; (2) Officers acting in fiduciary capacity may be shielded from personal jurisdiction in foreign forums; (3) The plaintiff must establish that the officer acted outside their fiduciary role, or find a basis for jurisdiction independent of the corporate contacts. For county-level matters, this means county officers acting as fiduciaries may resist out-of-county litigation if their contacts arose solely from their official duties.',
'https://www.arnoldporter.com/en/perspectives/advisories/2025/02/fifth-circuit-fiduciary-shield-exception-personal-jurisdiction', 'Arnold & Porter (Fifth Circuit analysis)', 89, 1),

('Standing to Enforce Charitable Fiduciary Duties', 'STANDINGS', 'charitable', 'United States (state attorneys general)', 'DOMESTIC',
'Who else should enforce the duties of charitable fiduciaries? Traditionally, the state Attorney General has primary responsibility for supervising charities, charitable trusts, and charitable fundraisers. The AG stands in as parens patriae — protector of the public interest. But standing is contested: (1) Individual donors generally lack standing to sue for fiduciary breach (their donation is irrevocable); (2) Named beneficiaries of charitable trusts may have standing if sufficiently identifiable; (3) State AGs have universal standing but limited resources; (4) Cy-pres proceedings allow courts to redirect charitable assets when original purpose fails — standing rests with the AG or special interest designees. The challenge: charitable fiduciaries often breach duties without accountability because no single private party has standing to enforce. This is where the gentry hero need emerges — a person of standing who brings attention, resources, or advocacy to failed charitable stewardship.',
'https://ncpl.law.nyu.edu/wp-content/uploads/pdfs/1997/Conf1997atkinsonpaper.pdf', 'NYU National Center on Philanthropy and the Law', 87, 1),

('10% Owners and Fiduciary Standing', 'STANDINGS', 'minority', 'United States (Delaware, Texas)', 'DOMESTIC',
'Does every 10% owner owe a fiduciary duty to the corporation? The answer varies by jurisdiction. In some states, controlling shareholders (typically 50%+) owe fiduciary duties to minority shareholders. But 10% ownership alone does not automatically create a fiduciary relationship — unless combined with actual control, board representation, or contractual provisions. Standing questions: (1) Minority shareholders have standing for derivative suits (suing on behalf of the corporation); (2) Direct suits require personal injury distinct from corporate injury; (3) Controlling shareholders can be sued directly by minorities for breach of loyalty; (4) In M&A contexts, non-acquirer or minority stockholders increasingly seek relief for fiduciary breaches relating to agreement interpretation. As Justice Scalia stated in Lujan: broadening categories of injury in support of standing is different from abandoning the requirement that the party seeking review must have suffered an injury.',
'https://www.jdsupra.com/legalnews/does-every-10-owner-owe-a-fiduciary-dut-31229/', 'JD Supra — Legal Intelligence', 86, 1),

('Equitable Obligations and the Fiduciary Point', 'STANDINGS', 'equitable', 'Australia (Federal Court, 2026)', 'INTERNATIONAL',
'Justice Owens of the Federal Court of Australia (March 2026) delivered an analysis of the point at which equitable obligations become fiduciary. Not every relationship of trust creates fiduciary duties — the obligation crystallizes when: (1) One party has undertaken to act in the interests of another; (2) The relationship involves vulnerability and dependence; (3) The fiduciary has power to affect the legal or practical interests of the vulnerable party; (4) The power is discretionary. Standing to assert fiduciary claims depends on identifying this crystallization point — premature claims (before the fiduciary relationship is established) will be dismissed for want of standing. Late claims (after limitation period) may be time-barred. The equitable jurisdiction provides flexibility: constructive trusts, tracing, and account of profits are available once the fiduciary point is established, regardless of contractual provisions.',
'https://www.fedcourt.gov.au/digital-law-library/judges-speeches/justice-owens-speeches-and-papers/owens-j-20260327', 'Federal Court of Australia (2026)', 90, 1);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 6: WINNERS — Who Has Won from Other Times Already
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO original_documents (title, category, subcategory, jurisdiction, label, document_text, source_url, source_authority, confidence, relevance_to_minister) VALUES
('Ivanishvili v Credit Suisse Trust — $742.73M (2025)', 'WINNERS', 'mega_award', 'Singapore (SICC)', 'INTERNATIONAL',
'The Singapore International Commercial Court found that Credit Suisse Trust Limited breached its fiduciary duties and awarded the respondents compensation of US$742.73 million, together with interest and costs. This is among the largest fiduciary breach awards in history. The trust company had managed the beneficiary assets with negligence and conflicts of interest over an extended period. The beneficiary (a Georgian billionaire) had the resources and standing to pursue the claim through years of international litigation. WINNER: Beneficiary. LESSON: Professional institutional fiduciaries (banks, trust companies) can be held to account for catastrophic stewardship failures — but only when the beneficiary has the resources to fight.',
'https://www.judiciary.gov.sg/judgments/case-briefs-by-smu/credit-suisse-trust-limited-v-ivanishvili--bidzina-and-others', 'Singapore International Commercial Court', 95, 0),

('Mendell v Scott — Damages + Punitive Damages Against Trustee (Texas, 2023)', 'WINNERS', 'punitive', 'United States (Texas)', 'DOMESTIC',
'In Mendell v. Scott (Houston, 2023), the jury found for the plaintiffs and awarded damages and exemplary (punitive) damages against a trustee who breached the duty to disclose and refused to terminate a trust after a valid disclaimer. The court held that Texas law is clear: a beneficiary has an absolute right to disclaim an interest in property and that right cannot be limited by the settlor. The trustee was additionally denied reimbursement from trust assets for litigation costs — a double penalty for fiduciary breach. WINNER: Beneficiary (nieces children). LESSON: Courts will punish trustees who obstruct legitimate beneficiary rights with punitive damages and denial of indemnification.',
'https://www.fiduciarylitigator.com/2024/02/court-affirmed-award-of-damages-and-punitive-damages-against-a-trustee/', 'The Fiduciary Litigator (Texas Appellate)', 91, 0),

('Asaro v Maniscalco — Elder Abuse + Fiduciary Breach (California, 2024)', 'WINNERS', 'elder_abuse', 'United States (California)', 'DOMESTIC',
'After an eight-day trial, the Probate Court held a trustee breached his fiduciary duties to the trust and committed financial elder abuse against the first spouse to die, while acting as co-trustee with the surviving spouse. The court found the co-trustee had systematically diverted trust assets for personal benefit while the elderly beneficiary was alive and vulnerable. WINNER: Estate / remaining beneficiaries. LESSON: Fiduciary breach combined with elder abuse triggers enhanced remedies — the intersection of trust law and protective legislation creates amplified liability.',
'https://calawyers.org/trusts-and-estates/asaro-v-maniscalco/', 'California Lawyers Association', 89, 0),

('Carnegie Arbitration — $2.3M Breach of Fiduciary + Civil Conspiracy (2024)', 'WINNERS', 'arbitration', 'United States (AAA arbitration)', 'DOMESTIC',
'The case alleged breach of fiduciary duty, civil conspiracy, and material omissions during and after a corporate transition. Filed with the American Arbitration Association in September 2022, the arbitrator awarded $2.3 million in damages. The firm had failed to disclose material conflicts during a transition period, violating its ongoing fiduciary obligation to clients. WINNER: Client/beneficiary. LESSON: Corporate transitions do not suspend fiduciary duty — the ongoing obligation persists through restructuring, and material omissions during transition constitute breach.',
'https://investorclaims.com/blog/carnegie-arbitration-victory-national-media-coverage/', 'Meyer Wilson (National Press)', 88, 0),

('McLean v Davis — Trust Protector Fiduciary Duty (Missouri, 2009)', 'WINNERS', 'protector', 'United States (Missouri)', 'DOMESTIC',
'In a case of first impression concerning trust protectors in Missouri, the Court of Appeals reversed summary judgment in favor of a trust protector on claims that the trust protector breached its fiduciary duty by failing to remove delinquent trustees. The court held that trust protectors owe fiduciary duties and can be held liable for failing to act when trustees breach their obligations. WINNER: Beneficiary (case remanded for trial). LESSON: Even supervisory fiduciaries (protectors, overseers) bear active duties — the failure to intervene when subordinate fiduciaries fail is itself a breach. This reinforces the gentry hero principle: those with power to correct must exercise it.',
'https://www.mcguirewoods.com/client-resources/Alerts/2009/4/Recent-Fiduciary-Cases-Spring-2009', 'McGuireWoods LLP', 87, 0),

('Keech v Sandford — The Original Win (England, 1726)', 'WINNERS', 'foundational', 'England', 'INTERNATIONAL',
'The infant beneficiary won. Lord Chancellor King established that a fiduciary who profits from their position must disgorge all gains to the beneficiary — regardless of whether the beneficiary could have obtained the benefit independently. This 300-year-old victory established the prophylactic principle that remains the foundation of all fiduciary law worldwide. Every subsequent fiduciary case stands on this precedent. WINNER: Infant beneficiary (represented by the Court of Chancery acting as guardian). LESSON: The court itself can serve as gentry hero when the beneficiary cannot act for themselves.',
NULL, 'English Court of Chancery (Lord Chancellor King)', 96, 0),

('Norway Government Pension Fund — Ongoing Winner (1990-present)', 'WINNERS', 'sovereign_success', 'Norway', 'INTERNATIONAL',
'The Norwegian people have won the ongoing fiduciary game. The Government Pension Fund Global, managed by Norges Bank Investment Management under fiduciary mandate from the Ministry of Finance, has grown from petroleum revenues into the worlds largest sovereign wealth fund ($1.7 trillion). Key winning factors: (1) Clear fiduciary mandate — intergenerational savings; (2) Full public transparency — every holding published; (3) Ethical investment guidelines — exclusion of companies violating human rights, environmental standards; (4) Independent oversight — the Ministry sets policy but does not direct individual investments; (5) Fiscal rule — only the real return (~3%) is spent annually, preserving principal indefinitely. WINNER: Norwegian citizenry (5.4 million people, ~$300,000 per person). LESSON: When the minister-fiduciary relationship is properly designed, maintained, and transparent, it generates enormous value across generations.',
NULL, 'Norges Bank Investment Management / Norwegian Ministry of Finance', 94, 1);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 7: AHEAD — Forward-Facing Fiduciary Principle and Future Position
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO original_documents (title, category, subcategory, jurisdiction, label, document_text, source_url, source_authority, confidence, relevance_to_minister) VALUES
('Ahead — The Forward Position of the Minister-Fiduciary', 'AHEAD', 'forward', 'United States / International', 'DOMESTIC',
'The minister-fiduciary looks ahead. The fiduciary duty is not merely retrospective (what was done wrong) but prospective (what must be done right). Forward-facing fiduciary principles: (1) Anticipatory duty — the fiduciary must foresee reasonably predictable risks and protect against them; (2) Succession planning — who takes over when the current fiduciary cannot continue; (3) Technology adaptation — fiduciary structures must evolve with financial technology (blockchain, tokenized assets, AI-assisted portfolio management); (4) Climate and ESG — forward-looking fiduciaries must consider long-term systemic risks (regulatory shifts, physical risks, transition costs); (5) Intergenerational equity — decisions today affect beneficiaries who do not yet exist; (6) Jurisdictional evolution — as international law converges (Hague Convention adoption, UNIDROIT harmonization), fiduciary structures gain portability but must adapt to new regulatory frameworks. The minister who looks ahead positions the fiduciary structure for perpetuity rather than mere survival.',
NULL, 'NWE Fiduciary Module — System Philosophy', 90, 1),

('Ahead — Fiduciary Architecture for the Digital Age', 'AHEAD', 'digital', 'Global (emerging frameworks)', 'INTERNATIONAL',
'Fiduciary architecture is evolving toward: (1) Smart contract fiduciaries — automated execution of trust terms with built-in compliance (Ethereum, Solana); (2) Tokenized trust assets — fractional beneficial ownership via blockchain with transparent ledger; (3) AI fiduciary advisors — algorithms executing prudent investor standard with real-time rebalancing; (4) Decentralized Autonomous Organizations (DAOs) as fiduciary vehicles — collective governance without centralized trustee; (5) Cross-border digital identity — KYC/AML compliance that enables instant fiduciary onboarding across jurisdictions; (6) Regulatory sandbox frameworks — allowing innovation within fiduciary bounds. The challenge: maintaining human accountability (the gentry hero) within automated systems. Technology enables but does not replace the fiduciary conscience. The ministers role ahead is to ensure digital fiduciary systems preserve the twin pillars of loyalty and care even as execution becomes algorithmic.',
NULL, 'NWE Fiduciary Module — Forward Architecture', 88, 1),

('Ahead — County Legislature and the Next Fiscal Cycle', 'AHEAD', 'county_future', 'United States (all counties)', 'DOMESTIC',
'County legislatures face forward-looking fiduciary challenges: (1) Pension underfunding — promises made to retired workers must be honored, requiring prudent long-term investment of current revenues; (2) Infrastructure maintenance — roads, bridges, water systems require multi-decade planning horizons; (3) Climate adaptation — flood plains, wildfire zones, sea level rise affecting property tax base; (4) Demographic shifts — aging populations, migration patterns affecting revenue and expenditure projections; (5) Technology investment — digital government services requiring upfront capital for long-term efficiency; (6) Debt management — bond covenants creating ongoing fiduciary obligations to bondholders. The county that plans ahead — that treats fiscal planning as fiduciary duty rather than political convenience — preserves its tax base, maintains its credit rating, and serves its citizens across generations. Tax evidence of forward planning: capital improvement programs, long-term financial forecasts, actuarial valuations, and strategic plans are all fiduciary documents.',
NULL, 'NWE Fiduciary Module — County Future', 87, 1),

('Ahead — Who Wins Next', 'AHEAD', 'future_winners', 'Global', 'INTERNATIONAL',
'The next winners in fiduciary law will be: (1) Beneficiaries of properly governed sovereign wealth funds — nations that adopt Santiago Principles with genuine transparency will compound wealth for their citizens; (2) Participants in reformed pension systems — funds that adopt prudent investor standard with adequate contribution rates and proper fiduciary oversight; (3) Individuals who establish dynasty trusts in favorable jurisdictions (South Dakota, Nevada) with careful trustee selection and trust protector oversight; (4) Nations that ratify the Hague Trust Convention — gaining legal certainty that attracts fiduciary business and capital; (5) Communities with strong county-level fiduciary governance — proper tax stewardship, transparent investment, and long-term planning; (6) Those served by the gentry hero — when systems fail, the person of standing who steps forward to restore fiduciary order creates lasting value. The pattern is eternal: careful stewardship wins over time. The minister who understands this operates ahead of crisis, positions ahead of failure, and builds ahead of need.',
NULL, 'NWE Fiduciary Module — Forward Thesis', 89, 1);


-- ═══════════════════════════════════════════════════════════════════════════════
-- INDEXES for performance
-- ═══════════════════════════════════════════════════════════════════════════════

-- Full-text search for document content
ALTER TABLE original_documents ADD FULLTEXT INDEX ft_document_text (document_text);
ALTER TABLE original_documents ADD FULLTEXT INDEX ft_title (title);


-- ═══════════════════════════════════════════════════════════════════════════════
-- SUMMARY VIEW
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_fiduciary_document_summary AS
SELECT
    category,
    label,
    COUNT(*) AS document_count,
    AVG(confidence) AS avg_confidence,
    GROUP_CONCAT(DISTINCT jurisdiction ORDER BY jurisdiction SEPARATOR '; ') AS jurisdictions
FROM original_documents
GROUP BY category, label
ORDER BY category, label;


-- ═══════════════════════════════════════════════════════════════════════════════
-- QUERY HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Find all international law documents
-- SELECT * FROM original_documents WHERE label = 'INTERNATIONAL' ORDER BY category, confidence DESC;

-- Find minister-relevant documents
-- SELECT * FROM original_documents WHERE relevance_to_minister = 1 ORDER BY confidence DESC;

-- Find gentry hero precedents
-- SELECT * FROM original_documents WHERE category = 'GENTRY_HERO' ORDER BY confidence DESC;

-- Find who has won
-- SELECT title, jurisdiction, document_text FROM original_documents WHERE category = 'WINNERS' ORDER BY confidence DESC;

-- Find county/tax evidence
-- SELECT * FROM original_documents WHERE category = 'COUNTY' ORDER BY subcategory;

-- Full document summary
-- SELECT * FROM v_fiduciary_document_summary;
