-- ArmorerSteve™ Database Population Script
-- Database: nwe_armorer
-- Run: mysql -u root < armorer-populate.sql
-- ═══════════════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS nwe_armorer CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_armorer;

-- ═══ Tables ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS knowledge_base (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    question VARCHAR(512),
    answer TEXT,
    category VARCHAR(64),
    confidence INT DEFAULT 85,
    access_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT KEY ft_qa (question, answer)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cost_estimates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    item VARCHAR(128),
    description VARCHAR(512),
    cost_low DECIMAL(10,2),
    cost_high DECIMAL(10,2),
    currency VARCHAR(8) DEFAULT 'USD',
    category VARCHAR(64),
    source VARCHAR(256),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS armorers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) UNIQUE,
    location VARCHAR(256),
    specialty VARCHAR(256),
    era VARCHAR(64),
    notable_works TEXT,
    series_wins INT DEFAULT 0,
    active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS regulations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    body VARCHAR(128),
    regulation_name VARCHAR(256),
    scope VARCHAR(128),
    description TEXT,
    series VARCHAR(64),
    effective_date DATE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trade_records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    item_type VARCHAR(128),
    seller VARCHAR(128),
    buyer VARCHAR(128),
    price DECIMAL(12,2),
    currency VARCHAR(8) DEFAULT 'USD',
    trade_date DATE,
    location VARCHAR(128),
    series VARCHAR(64),
    capacitor_grade VARCHAR(32)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sessions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    question TEXT,
    answer TEXT,
    session_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ═══ Knowledge Base ═══════════════════════════════════════════════════

INSERT IGNORE INTO knowledge_base (question, answer, category, confidence) VALUES
('What is plate armor?', 'Plate armor is personal body armor made from large metal plates, typically steel or iron. Historically worn from the late medieval period (14th-17th century), it provides excellent protection against slashing and piercing weapons. Modern reproductions use spring steel (1075, 1080, 1095 carbon steel) or stainless variants for display.', 'fundamentals', 95),
('What metals are used in armor?', 'Historical: wrought iron, low-carbon steel, case-hardened iron. Modern: 1075/1080/1095 high-carbon spring steel (most popular for functional armor), 4130 chromoly (aircraft-grade), 304/316 stainless (display), titanium Grade 2/5 (lightweight combat). Thickness ranges 16-18 gauge (1.2-1.6mm) for most plate pieces.', 'materials', 92),
('How do you forge plate armor?', 'The process: 1) Pattern/template creation from measurements. 2) Cut steel blanks (plasma, shear, or angle grinder). 3) Hot forging at 800-1000C for shaping (dishing, raising). 4) Cold working for detail and hardening. 5) Heat treatment (normalize, harden, temper to 350-400F spring temper). 6) Grinding, filing, polishing. 7) Assembly with rivets, leather straps, buckles. A full harness takes 200-800 hours.', 'forging', 90),
('What is tempering?', 'Tempering is reheating hardened steel to a specific temperature (300-700F) to reduce brittleness while retaining hardness. For armor, a spring temper (350-425F, straw-to-light-blue color) gives the ideal balance: hard enough to resist cuts, flexible enough to absorb impacts without cracking.', 'metallurgy', 93),
('What is modern metal theory for armor?', 'Modern armor metallurgy focuses on: 1) Microstructure control (martensite vs. bainite vs. pearlite). 2) Grain refinement via controlled forging temperature. 3) Alloy selection for purpose. 4) Differential hardening (hard face, tough core). 5) Surface treatments (case hardening, nitriding). The goal is maximum energy absorption per unit weight.', 'metallurgy', 87),
('What tools do I need to start armoring?', 'Essential startup: Anvil ($200-2000), hammers ($30-80 each), raising stakes ($50-300), forge ($200-800), angle grinder ($50-150), bench vise ($100-400), swage blocks ($100-500), files/tongs/pliers ($100-300), safety gear ($100-200). Total startup: $1500-6000.', 'equipment', 91),
('How much does it cost to set up an armor forge?', 'HOBBY ($1500-3000): portable gas forge, basic anvil, essential hand tools. SEMI-PROFESSIONAL ($5000-15000): coal forge, quality anvil, power hammer, full stake set, grinding station. PROFESSIONAL ($20000-60000): industrial power hammer, hydraulic press, multiple forges, English wheel, polishing station, workshop.', 'costs', 94),
('Who are famous historical armorers?', 'Lorenz Helmschmid (Augsburg, 1467-1516) — Emperor Maximilian I. Kolman Helmschmid (son). The Missaglia family (Milan, 15th c.) — finest Italian. Greenwich Armourers (England, 1515-1637) — Royal workshops. Filippo Negroli (Milan, 1510-1579) — embossed parade armor. Anton Peffenhauser (Augsburg, 1525-1603).', 'history', 90),
('Who are modern armorers?', 'Jeffrey Wasson (USA) — HEMA/SCA. Ugo Serrano/MercuryForgeworks (USA) — historical. Eric Dube (Canada) — tournament. Robert MacPherson (UK) — museum-quality. Andrey Galevskyi/Age of Craft (Ukraine) — BUHURT. Illusion Armoring (Poland) — mass production HMB. Arms & Armor (Minneapolis) — research.', 'modern', 88),
('What are armor competition series?', 'BUHURT League/HMB — full-contact international team combat. IMCF — world championships. SCA — rattan combat with armor standards. ACL — US chapter of HMB. Battle of the Nations (BotN) — annual world championship since 2009. HEMA — primarily swordsmanship with lighter armor.', 'competition', 89),
('Who decides armor regulations?', 'HMBIA — international HMB rules. IMCF Technical Committee — world championship standards. SCA Marshal community — SCA combat standards. National federations apply rules locally. NIJ sets ballistic standards for LE. NATO STANAG 4569 for military vehicle/personal armor.', 'regulations', 91),
('Where is armor traded?', 'Direct commission (3-12 month wait). Facebook groups. Auction houses (Christies, Sothebys) for historical ($10K-2M+). Bulk suppliers: India/Pakistan (budget), Ukraine/Poland (competition), Italy (high-end). Events: Pennsic War, Gulf Wars, Battle of Nations vendor areas.', 'trade', 87),
('What is a final capacitor trade?', 'The final capacitor trade is the culminating exchange in a series where the winning armorer trades their highest-grade forge capability. A capacitor grade represents stored skill, tooling, and material investment. Grade A = tournament-winning harnesses; the trade is preferential commission rights awarded to series champions.', 'trade', 80),
('What are armor thickness requirements?', 'HMBIA/HMB: Helmet 2.0mm min (2.5mm face). Body plates 1.5mm min. Limbs 1.0mm min. No titanium below 1.2mm. Stainless +0.5mm over carbon steel. All edges rolled. No sharp protrusions. Historical accuracy not required for HMB.', 'regulations', 92),
('How much does a full suit of armor cost?', 'BUDGET ($800-2000): Indian/Pakistani, mild steel. COMPETITION ($2500-6000): Ukrainian/Polish, HMB-legal. CUSTOM ($5000-15000): Made-to-measure, named armorer. MUSEUM ($15000-80000+): Historically accurate, hand-forged. ANTIQUE: $50K-2M+ at auction.', 'costs', 93),
('What is raising in armor making?', 'Raising is the technique of forming a flat sheet of metal into a three-dimensional hollow form by hammering it over a stake or mandrel. The metal is compressed on the outside and stretched on the inside. Used for helmets, breastplates, and limb armor. Requires many passes with annealing between to prevent cracking.', 'forging', 88),
('What is dishing?', 'Dishing is forming a concave shape in metal by hammering it into a depression (dishing stump, sandbag, or swage). Simpler than raising — works by stretching the metal thinner in the center. Used for shields, knee cops, elbow cops, and basic helmet bowls. Faster but produces thinner material at the deepest point.', 'forging', 87),
('What steel should I use for armor?', '1075 steel: Most popular, excellent spring temper, forgiving to heat treat. 1080: Slightly harder, good all-around. 1095: Hardest common carbon steel, excellent edge retention but less forgiving. 4130 chromoly: Aircraft-grade, excellent strength-to-weight, harder to heat treat. For beginners: start with 1075 or 1080 at 16-18 gauge.', 'materials', 91),
('What is case hardening?', 'Case hardening creates a hard outer shell with a tough, flexible core. Methods: 1) Pack carburizing (heating in carbon-rich compound at 900C for hours). 2) Gas carburizing (industrial). 3) Bone/horn char (historical method). Result: 0.5-1.5mm hardened surface over soft core. Historical armorers used this extensively before through-hardening was reliable.', 'metallurgy', 86);

-- ═══ Cost Estimates ═══════════════════════════════════════════════════

INSERT IGNORE INTO cost_estimates (item, description, cost_low, cost_high, category, source) VALUES
('Anvil (100 lb)', 'Cast iron or steel anvil, farrier or blacksmith pattern', 150.00, 600.00, 'equipment', 'Centaur Forge, Amazon'),
('Anvil (250 lb)', 'Professional forged steel anvil, London or double-horn pattern', 800.00, 2500.00, 'equipment', 'Peddinghaus, Ridgid, NC Tool Co'),
('Gas Forge (2-burner)', 'Propane forge for heating plate steel blanks', 250.00, 800.00, 'equipment', 'Hell Forge, Majestic Forge, NC Whisper'),
('Coal Forge', 'Traditional coal/coke forge with blower', 150.00, 600.00, 'equipment', 'Centaur Forge, custom built'),
('Power Hammer (25 lb)', 'Mechanical power hammer for primary forming', 3000.00, 8000.00, 'equipment', 'Anyang, Big BLU, Iron Kiss'),
('Hydraulic Press (20 ton)', 'H-frame press with custom dies', 1500.00, 5000.00, 'equipment', 'Harbor Freight + custom tooling'),
('Ball Peen Hammer Set', '4-piece set: 8oz, 16oz, 24oz, 32oz', 40.00, 120.00, 'hand_tools', 'Picard, Peddinghaus, Stanley'),
('Cross Peen Hammer Set', 'Armoring hammers for raising and planishing', 60.00, 200.00, 'hand_tools', 'Picard, custom'),
('Raising Stakes (set of 6)', 'T-stakes and mushroom stakes for curves', 200.00, 800.00, 'hand_tools', 'Pepe Tools, custom cast'),
('Dishing Stump/Form', 'Hardwood or steel dishing form', 50.00, 200.00, 'hand_tools', 'Custom carved or cast'),
('Angle Grinder (4.5 in)', 'Variable speed with cutting/grinding discs', 50.00, 200.00, 'power_tools', 'DeWalt, Makita, Metabo'),
('Belt Grinder (2x72)', 'Primary shaping and finishing tool', 500.00, 3000.00, 'power_tools', 'Grizzly, KMG, Beaumont'),
('English Wheel', 'Compound curves and smooth planishing', 400.00, 3000.00, 'power_tools', 'Eastwood, Mittler Bros'),
('Bench Vise (6 inch)', 'Heavy-duty leg vise or bench vise', 100.00, 500.00, 'equipment', 'Yost, Wilton, post vise'),
('Tong Set (6 piece)', 'Flat, wolf-jaw, V-bit, bolt, farrier tongs', 80.00, 300.00, 'hand_tools', 'NC Tool Co, Blacksmith Depot'),
('Steel Sheet 1095 (4x8 ft 16ga)', 'High-carbon spring steel for armor', 200.00, 400.00, 'materials', 'NJ Steel Baron, Admiral Steel'),
('Steel Sheet 4130 (4x8 ft 14ga)', 'Aircraft-grade chromoly', 350.00, 700.00, 'materials', 'Aircraft Spruce, Online Metals'),
('Rivets (bag of 100)', 'Steel dome-head rivets', 8.00, 25.00, 'materials', 'McMaster-Carr, armoring supply'),
('Leather Strapping (10 ft)', 'Veg-tanned leather for straps/linings', 20.00, 60.00, 'materials', 'Tandy Leather, Springfield Leather'),
('Safety Equipment Set', 'Leather apron, face shield, ear muffs, gloves', 100.00, 250.00, 'safety', 'Amazon, local welding supply'),
('Metal Granules/Shot (50 lb)', 'Steel shot for tumbling/polishing armor', 40.00, 100.00, 'materials', 'Grainger, metalworking supply'),
('Planishing Hammer', 'Smooth-faced hammer for final surface finishing', 30.00, 100.00, 'hand_tools', 'Picard, custom ground face'),
('Swage Block', 'Cast iron block with various shaped holes/channels', 100.00, 500.00, 'hand_tools', 'Centaur Forge, antique'),
('Quench Tank (50 gal)', 'Oil or water quench tank for heat treatment', 50.00, 200.00, 'equipment', 'Custom built, repurposed drum'),
('Pyrometer/Thermocouple', 'Temperature measurement for heat treatment', 50.00, 300.00, 'equipment', 'Omega, ThermoWorks');

-- ═══ Armorers ═════════════════════════════════════════════════════════

INSERT IGNORE INTO armorers (name, location, specialty, era, notable_works, series_wins) VALUES
('Jeffrey Wasson', 'USA', 'HEMA/SCA combat harnesses, custom fitted plate', 'modern', 'Multiple SCA Crown Tournament winners outfitted', 12),
('Ugo Serrano (MercuryForgeworks)', 'USA', 'Historically accurate 14th-15th century reproductions', 'modern', 'Museum commissions, Higgins Armory collaboration', 3),
('Eric Dubé (Les Artisans du Fer)', 'Canada', 'Tournament and jousting harnesses', 'modern', 'World Jousting Championship armor', 8),
('Robert MacPherson', 'Scotland, UK', 'Museum-quality Gothic and Milanese reproductions', 'modern', 'Wallace Collection commissions, Royal Armouries Leeds', 5),
('Andrey Galevskyi (Age of Craft)', 'Ukraine', 'BUHURT/HMB competition armor', 'modern', '3x Battle of the Nations team champion armorer', 22),
('Illusion Armoring', 'Poland', 'Mass-production BUHURT armor', 'modern', 'Outfitter for 40+ national HMB teams', 45),
('Arms & Armor Inc.', 'Minneapolis, USA', 'Research-grade swords and armor', 'modern', 'Museum reproductions, film props, academic research', 2),
('Lorenz Helmschmid', 'Augsburg, Germany', 'Imperial court armorer, Gothic plate', 'historical (1467-1516)', 'Armor of Emperor Maximilian I (Kunsthistorisches Museum)', 0),
('Filippo Negroli', 'Milan, Italy', 'Embossed parade armor, all antica style', 'historical (1510-1579)', 'Burgonet of Charles V (Met Museum)', 0),
('The Missaglia Workshop', 'Milan, Italy', 'Export-quality Milanese armor', 'historical (15th century)', 'Supplied half of European nobility, Churburg Castle collection', 0),
('Greenwich Royal Armoury', 'Greenwich, England', 'English court armor, garnitures', 'historical (1515-1637)', 'Armor of Henry VIII (Tower of London)', 0),
('Anton Peffenhauser', 'Augsburg, Germany', 'Late period master, etched decoration', 'historical (1525-1603)', 'Numerous court armors in European collections', 0);

-- ═══ Regulations ══════════════════════════════════════════════════════

INSERT IGNORE INTO regulations (body, regulation_name, scope, description, series) VALUES
('HMBIA', 'Equipment Standard 2024', 'International', 'Helmet: 2.0mm min (2.5mm face). Body: 1.5mm. Limbs: 1.0mm. Stainless +0.5mm. Edges rolled. No projections. Face grill or visor with eye slot max 35mm.', 'HMB/BUHURT'),
('IMCF', 'Technical Rules 2024', 'World Championship', 'Similar to HMBIA plus: titanium min 1.2mm. Padding 15mm+. No PVC structural. Weight limits per category. 3-judge inspection.', 'IMCF World'),
('SCA', 'Marshal Handbook — Armor Standards', 'SCA worldwide', 'Rigid material covering critical areas. Min 16-gauge steel or equivalent. Helm must withstand 12-lb drop from 6 ft. Gorget mandatory.', 'SCA Heavy Combat'),
('ACL', 'Armored Combat League Rules (USA)', 'USA national', 'HMBIA base + helm hold after 3 strikes. Stricter polearm rules. Shield flex test required.', 'ACL National'),
('NIJ', 'NIJ Standard 0101.07', 'US Law Enforcement', 'Ballistic body armor classification: Level IIA, II, IIIA (handgun), III, IV (rifle). Defines testing protocols for modern protective equipment.', 'Military/LE'),
('NATO', 'STANAG 4569', 'NATO military', 'Standardization Agreement for vehicle and personal armor protection levels 1-6. Kinetic energy and blast protection.', 'Military');

-- ═══ Sample Trade Records ═════════════════════════════════════════════

INSERT IGNORE INTO trade_records (item_type, seller, buyer, price, currency, trade_date, location, series, capacitor_grade) VALUES
('Full Harness (HMB)', 'Illusion Armoring', 'Team USA', 4500.00, 'USD', '2025-11-15', 'Kraków, Poland', 'IMCF 2026 Prep', 'A'),
('Gothic Breastplate', 'Age of Craft', 'Private collector', 2800.00, 'EUR', '2025-09-20', 'Kyiv, Ukraine', 'BotN 2025', 'A'),
('Tournament Helm', 'Jeffrey Wasson', 'SCA Knight', 1200.00, 'USD', '2025-07-04', 'Pennsic, USA', 'SCA Crown', 'B'),
('Reproduction Sallet', 'Robert MacPherson', 'Museum of London', 8500.00, 'GBP', '2025-06-01', 'Edinburgh, UK', 'Museum', 'A'),
('Jousting Harness', 'Eric Dubé', 'World Jousting League', 12000.00, 'CAD', '2025-04-10', 'Montreal, Canada', 'WJC 2025', 'A'),
('Antique Maximilian Armor', 'Christies Auction', 'Anonymous', 450000.00, 'GBP', '2024-12-12', 'London, UK', 'Historical', 'N/A'),
('Competition Kit (5-man)', 'Illusion Armoring', 'Team Poland', 18000.00, 'EUR', '2025-01-20', 'Warsaw, Poland', 'BotN 2025', 'A'),
('Practice Helmet + Gauntlets', 'Facebook Market', 'New fighter', 600.00, 'USD', '2025-08-01', 'Online', 'Casual', 'C');

-- ═══ Done ═════════════════════════════════════════════════════════════
SELECT 'ArmorerSteve database populated successfully.' AS status;
