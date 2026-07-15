#!/bin/bash
# ⚠️  DESTRUCTIVE: This script TRUNCATES/DROPS tables before reloading data.
# Do NOT run as part of git-pull automation. Run manually only when reloading reference data.
# Brarner.M.Alete™ — Populate Taxonomy Descriptions
# Creates taxonomy_descriptions table and populates with Wikipedia-sourced descriptions
# for kingdom, class, order, and family taxonomic levels.
# Usage: bash install/populate-taxonomy-descriptions.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Taxonomy Descriptions"
echo "═══════════════════════════════════════════════════════════════"

if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_PORT=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_HOST="${DB_HOST:-127.0.0.1}"
    DB_PORT="${DB_PORT:-3306}"
    MYSQL_OPTS="-u${DB_USER} -h${DB_HOST} -P${DB_PORT}"
    [ -n "$DB_PASS" ] && MYSQL_OPTS="$MYSQL_OPTS -p${DB_PASS}"
else
    echo "[!] db.properties not found."; exit 1
fi

echo "[*] Creating taxonomy_descriptions table..."

mysql $MYSQL_OPTS << 'SQL'
USE BrarnerScience;

CREATE TABLE IF NOT EXISTS taxonomy_descriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rank_level ENUM('kingdom','phylum','class','order','family') NOT NULL,
    taxon_name VARCHAR(200) NOT NULL,
    description TEXT,
    characteristics TEXT,
    example_species VARCHAR(500),
    wikipedia_url VARCHAR(500),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_rank_taxon (rank_level, taxon_name),
    INDEX idx_rank (rank_level),
    INDEX idx_name (taxon_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Kingdom descriptions
INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description, characteristics, example_species, wikipedia_url) VALUES
('kingdom', 'Animalia', 'The kingdom of multicellular eukaryotic organisms that form the biological kingdom Animalia. Animals are motile, heterotrophic (consume organic material), and generally reproduce sexually.', 'Multicellular, eukaryotic, heterotrophic, motile at some life stage, no cell walls, embryonic development through blastula stage', 'Homo sapiens, Canis lupus, Aquila chrysaetos, Tursiops truncatus', 'https://en.wikipedia.org/wiki/Animal')
ON DUPLICATE KEY UPDATE description=VALUES(description), characteristics=VALUES(characteristics);

-- Class descriptions (Mollusca and worm-like invertebrates from the URL path shown)
INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description, characteristics, example_species, wikipedia_url) VALUES
('class', 'Aplotegmentaria', 'A class of shell-less, worm-like molluscs (solenogasters/aplacophorans). These marine animals lack a shell and mantle cavity, instead having a body covered with calcareous spicules embedded in a cuticle.', 'Vermiform (worm-shaped), no shell, calcareous spicules in cuticle, marine benthic, feed on cnidarians or detritus, hermaphroditic', 'Neomenia carinata, Epimenia australis, Wirenia argentea', 'https://en.wikipedia.org/wiki/Solenogastres'),
('class', 'Gastropoda', 'The largest class of molluscs with over 65,000 living species. Includes snails and slugs. Characterized by torsion (180° twisting of the visceral mass) and usually a coiled shell.', 'Torsion, muscular foot, radula, usually coiled shell (lost in slugs), marine/freshwater/terrestrial', 'Helix pomatia, Littorina littorea, Aplysia californica', 'https://en.wikipedia.org/wiki/Gastropoda'),
('class', 'Bivalvia', 'A class of molluscs with laterally compressed bodies enclosed by two hinged shells (valves). Mostly filter-feeders living in marine and freshwater habitats.', 'Two hinged shells, laterally compressed, filter-feeding via gills, no head or radula, sessile or burrowing', 'Mytilus edulis, Crassostrea gigas, Pecten maximus', 'https://en.wikipedia.org/wiki/Bivalvia'),
('class', 'Cephalopoda', 'The most neurologically advanced class of molluscs including octopuses, squids, cuttlefish, and nautiluses. Characterized by bilateral symmetry, a prominent head, and modified muscular arms/tentacles.', 'Bilateral symmetry, jet propulsion, complex nervous system, chromatophores, beak, arms/tentacles, closed circulatory system', 'Octopus vulgaris, Loligo vulgaris, Sepia officinalis, Nautilus pompilius', 'https://en.wikipedia.org/wiki/Cephalopod'),
('class', 'Mammalia', 'Warm-blooded vertebrates characterized by mammary glands, hair/fur, three middle ear bones, and a neocortex. Over 6,400 living species.', 'Endothermic, mammary glands, hair, live birth (most), neocortex, single-boned lower jaw, specialized teeth', 'Homo sapiens, Balaenoptera musculus, Panthera leo', 'https://en.wikipedia.org/wiki/Mammal'),
('class', 'Aves', 'Feathered, winged, bipedal, warm-blooded, egg-laying vertebrates. Over 10,000 living species. Characterized by toothless beaked jaws, high metabolic rate, and lightweight skeleton.', 'Feathers, hollow bones, toothless beak, four-chambered heart, endothermic, hard-shelled eggs, high metabolic rate', 'Aquila chrysaetos, Corvus corax, Aptenodytes forsteri', 'https://en.wikipedia.org/wiki/Bird'),
('class', 'Reptilia', 'Cold-blooded, air-breathing vertebrates covered in scales or scutes. Includes turtles, crocodilians, snakes, lizards, and tuatara.', 'Ectothermic, scales/scutes, amniotic eggs, lungs throughout life, three or four-chambered heart', 'Crocodylus niloticus, Python reticulatus, Chelonia mydas', 'https://en.wikipedia.org/wiki/Reptile'),
('class', 'Actinopterygii', 'Ray-finned fishes — the largest class of vertebrates with over 30,000 species. Fins supported by bony spines (rays) rather than fleshy lobes.', 'Bony rays in fins, swim bladder, operculum covering gills, scales, lateral line system', 'Salmo salar, Thunnus thynnus, Danio rerio', 'https://en.wikipedia.org/wiki/Actinopterygii'),
('class', 'Insecta', 'The most species-rich class of animals with over 1 million described species. Three-part body (head, thorax, abdomen), three pairs of legs, compound eyes, and one pair of antennae.', 'Exoskeleton, three body segments, six legs, compound eyes, metamorphosis, tracheal respiration', 'Apis mellifera, Danaus plexippus, Musca domestica', 'https://en.wikipedia.org/wiki/Insect'),
('class', 'Arachnida', 'Arthropods with eight legs including spiders, scorpions, ticks, and mites. Over 100,000 described species. No antennae or wings.', 'Eight legs, two body segments (cephalothorax + abdomen), chelicerae, no antennae, book lungs or tracheae', 'Latrodectus mactans, Scorpio maurus, Ixodes scapularis', 'https://en.wikipedia.org/wiki/Arachnid')
ON DUPLICATE KEY UPDATE description=VALUES(description), characteristics=VALUES(characteristics);

-- Order descriptions
INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description, characteristics, example_species, wikipedia_url) VALUES
('order', 'Pholidoskepia', 'An order of solenogasters (shell-less aplacophorans). Small, worm-like marine molluscs covered in scale-like spicules. Found in deep-sea benthic environments feeding on hydroids and other cnidarians.', 'Scale-like calcareous spicules, vermiform, deep-sea benthic, radula present, monaulic reproductive system', 'Epimenia babai, Alexandromenia valida', 'https://en.wikipedia.org/wiki/Pholidoskepia'),
('order', 'Carnivora', 'Diverse order of placental mammals with specialized teeth and claws for catching and eating other animals. Includes cats, dogs, bears, seals, and weasels.', 'Carnassial teeth, strong jaws, claws, highly developed brain, diverse body plans (terrestrial, aquatic, arboreal)', 'Panthera leo, Canis lupus, Ursus arctos, Phoca vitulina', 'https://en.wikipedia.org/wiki/Carnivora'),
('order', 'Primates', 'Order of mammals including humans, apes, monkeys, and prosimians. Characterized by large brains, binocular vision, and grasping hands with opposable thumbs.', 'Large brain relative to body, forward-facing eyes, grasping hands, nails instead of claws, prolonged parental care', 'Homo sapiens, Pan troglodytes, Gorilla gorilla', 'https://en.wikipedia.org/wiki/Primate'),
('order', 'Lepidoptera', 'Order of insects comprising butterflies and moths. Over 180,000 species. Characterized by scale-covered wings and complete metamorphosis.', 'Scaled wings, coiled proboscis, complete metamorphosis (egg-larva-pupa-adult), holometabolous', 'Danaus plexippus, Bombyx mori, Papilio machaon', 'https://en.wikipedia.org/wiki/Lepidoptera'),
('order', 'Coleoptera', 'Beetles — the largest order of insects and animals, with over 400,000 described species. Front wings hardened into elytra.', 'Hardened forewings (elytra), complete metamorphosis, chewing mouthparts, diverse habitats', 'Coccinella septempunctata, Lucanus cervus, Dynastes hercules', 'https://en.wikipedia.org/wiki/Beetle')
ON DUPLICATE KEY UPDATE description=VALUES(description), characteristics=VALUES(characteristics);

-- Family descriptions
INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description, characteristics, example_species, wikipedia_url) VALUES
('family', 'Lepidomeniidae', 'A family of solenogasters (order Pholidoskepia). Small, worm-like, shell-less aplacophoran molluscs with distinctive scale-shaped calcareous spicules covering the body. Marine benthic organisms found in deep-sea environments.', 'Scale-shaped spicules (lepido- = scale), vermiform body 2-30mm, no mantle cavity, deep-sea habitat, feed on hydrozoans', 'Lepidomenia hystrix, Lepidomenia australis', 'https://en.wikipedia.org/wiki/Lepidomeniidae'),
('family', 'Felidae', 'The cat family. Obligate carnivores with retractable claws, powerful jaws, and excellent night vision. 37 living species across all continents except Antarctica and Australia (historically).', 'Retractable claws, digitigrade locomotion, specialized carnassial teeth, binocular vision, flexible spine', 'Panthera leo, Felis catus, Panthera tigris, Acinonyx jubatus', 'https://en.wikipedia.org/wiki/Felidae'),
('family', 'Canidae', 'The dog family. Social carnivores with non-retractable claws and long muzzles. Includes wolves, foxes, jackals, and domestic dogs.', 'Non-retractable claws, long muzzle, bushy tail, digitigrade, social pack behavior (many species)', 'Canis lupus, Vulpes vulpes, Canis latrans', 'https://en.wikipedia.org/wiki/Canidae'),
('family', 'Hominidae', 'The great ape family including humans, chimpanzees, gorillas, and orangutans. Large-bodied primates with no tail and high cognitive abilities.', 'No tail, large brain, opposable thumbs, flat face, extended development period, tool use', 'Homo sapiens, Pan troglodytes, Gorilla gorilla, Pongo pygmaeus', 'https://en.wikipedia.org/wiki/Hominidae')
ON DUPLICATE KEY UPDATE description=VALUES(description), characteristics=VALUES(characteristics);

SQL

COUNT=$(mysql $MYSQL_OPTS -N -B -e "SELECT COUNT(*) FROM BrarnerScience.taxonomy_descriptions;" 2>/dev/null)
echo "[✓] taxonomy_descriptions populated: $COUNT records"
echo "    Verify: mysql BrarnerScience -e \"SELECT rank_level, taxon_name FROM taxonomy_descriptions ORDER BY rank_level, taxon_name;\""
