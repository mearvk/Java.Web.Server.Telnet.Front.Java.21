-- Species table for individual species within families
USE BrarnerScience;

CREATE TABLE IF NOT EXISTS species (
    id INT AUTO_INCREMENT PRIMARY KEY,
    family_name VARCHAR(128) NOT NULL,
    species_name VARCHAR(256) NOT NULL,
    common_name VARCHAR(256),
    description TEXT,
    INDEX idx_family (family_name)
);

INSERT INTO species (family_name, species_name, common_name, description) VALUES
('Hominidae','Homo sapiens','Human','Modern humans. ~8 billion global population.'),
('Hominidae','Pan troglodytes','Chimpanzee','Closest living relative to humans.'),
('Hominidae','Gorilla gorilla','Western Gorilla','Largest living primates. Critically endangered.'),
('Felidae','Panthera leo','Lion','Only social cat. African savanna.'),
('Felidae','Panthera tigris','Tiger','Largest living cat. Endangered.'),
('Felidae','Acinonyx jubatus','Cheetah','Fastest land animal (~120 km/h).'),
('Canidae','Canis lupus','Gray Wolf','Ancestor of domestic dogs. Pack hunters.'),
('Canidae','Vulpes vulpes','Red Fox','Most widespread wild carnivore.'),
('Corvidae','Corvus corax','Common Raven','Largest passerine. Problem-solving intelligence.'),
('Corvidae','Cyanocitta cristata','Blue Jay','Eastern North America. Vocal mimic.'),
('Accipitridae','Haliaeetus leucocephalus','Bald Eagle','US national bird. Fish eagle.'),
('Accipitridae','Aquila chrysaetos','Golden Eagle','Most widely distributed eagle.'),
('Colubridae','Pantherophis guttatus','Corn Snake','Southeastern US. Non-venomous constrictor.'),
('Colubridae','Thamnophis sirtalis','Common Garter Snake','Most widespread snake in North America.'),
('Nymphalidae','Danaus plexippus','Monarch Butterfly','4,800km annual migration.'),
('Curculionidae','Dendroctonus ponderosae','Mountain Pine Beetle','Bark beetle devastating western forests.');
