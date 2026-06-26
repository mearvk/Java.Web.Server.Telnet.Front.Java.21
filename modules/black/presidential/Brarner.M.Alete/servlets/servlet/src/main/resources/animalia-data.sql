-- Brarner.M.Alete — Animalia Taxonomy Data Loader
-- Populates the animalia table from parsed taxonomy
-- Run AFTER animalia-schema.sql

USE BrarnerScience;

-- Populate from animalia.coercus.config (representative subset — full load via install script)
-- Each family is one row with full lineage

INSERT INTO animalia (phylum, subphylum, class_name, subclass, order_name, suborder, infraorder, family_name, installer_tax_id) VALUES
('Cnidaria','Anthozoa','Anthozoa','Hexacorallia','Actiniaria','Endocoelantheae',NULL,'Actinernidae','MEARVK-LLC-2026'),
('Cnidaria','Anthozoa','Anthozoa','Hexacorallia','Actiniaria','Endocoelantheae',NULL,'Halcuriidae','MEARVK-LLC-2026'),
('Cnidaria','Anthozoa','Anthozoa','Hexacorallia','Actiniaria','Nyantheae','Athenaria','Andresiidae','MEARVK-LLC-2026'),
('Cnidaria','Anthozoa','Anthozoa','Hexacorallia','Actiniaria','Nyantheae','Athenaria','Edwardsiidae','MEARVK-LLC-2026'),
('Cnidaria','Anthozoa','Anthozoa','Hexacorallia','Scleractinia','Astrocoeniina',NULL,'Acroporidae','MEARVK-LLC-2026'),
('Cnidaria','Anthozoa','Anthozoa','Hexacorallia','Scleractinia','Fungiina',NULL,'Fungiidae','MEARVK-LLC-2026'),
('Cnidaria','Anthozoa','Anthozoa','Octocorallia','Alcyonacea','Holaxonia',NULL,'Gorgoniidae','MEARVK-LLC-2026'),
('Cnidaria','Medusozoa','Cubozoa',NULL,'Carybdeida',NULL,NULL,'Carybdeidae','MEARVK-LLC-2026'),
('Cnidaria','Medusozoa','Hydrozoa','Hydroidolina','Anthoathecatae','Capitata',NULL,'Hydridae','MEARVK-LLC-2026'),
('Cnidaria','Medusozoa','Scyphozoa','Discomedusae','Rhizostomeae',NULL,NULL,'Rhizostomatidae','MEARVK-LLC-2026'),
('Ctenophora',NULL,'Nuda',NULL,'Beroida',NULL,NULL,'Beroidae','MEARVK-LLC-2026'),
('Ctenophora',NULL,'Tentaculata',NULL,'Lobata',NULL,NULL,'Bolinopsidae','MEARVK-LLC-2026'),
('Porifera',NULL,'Calcarea','Calcaronea',NULL,NULL,NULL,'Amphoriscidae','MEARVK-LLC-2026'),
('Placozoa',NULL,'Uniplacotomia',NULL,'Trichoplacea',NULL,NULL,'Trichoplacidae','MEARVK-LLC-2026'),
('Chordata','Vertebrata','Mammalia',NULL,'Primates',NULL,NULL,'Hominidae','MEARVK-LLC-2026'),
('Chordata','Vertebrata','Mammalia',NULL,'Carnivora',NULL,NULL,'Felidae','MEARVK-LLC-2026'),
('Chordata','Vertebrata','Aves',NULL,'Passeriformes',NULL,NULL,'Corvidae','MEARVK-LLC-2026'),
('Chordata','Vertebrata','Aves',NULL,'Accipitriformes',NULL,NULL,'Accipitridae','MEARVK-LLC-2026'),
('Chordata','Vertebrata','Reptilia',NULL,'Squamata',NULL,NULL,'Colubridae','MEARVK-LLC-2026'),
('Chordata','Vertebrata','Actinopterygii',NULL,'Perciformes',NULL,NULL,'Cichlidae','MEARVK-LLC-2026'),
('Arthropoda',NULL,'Insecta',NULL,'Coleoptera',NULL,NULL,'Curculionidae','MEARVK-LLC-2026'),
('Arthropoda',NULL,'Insecta',NULL,'Lepidoptera',NULL,NULL,'Nymphalidae','MEARVK-LLC-2026'),
('Arthropoda',NULL,'Arachnida',NULL,'Araneae',NULL,NULL,'Salticidae','MEARVK-LLC-2026'),
('Mollusca',NULL,'Gastropoda',NULL,'Stylommatophora',NULL,NULL,'Helicidae','MEARVK-LLC-2026'),
('Mollusca',NULL,'Cephalopoda',NULL,'Octopoda',NULL,NULL,'Octopodidae','MEARVK-LLC-2026'),
('Echinodermata',NULL,'Asteroidea',NULL,'Forcipulatida',NULL,NULL,'Asteriidae','MEARVK-LLC-2026'),
('Nematoda',NULL,'Chromadorea',NULL,'Rhabditida',NULL,NULL,'Rhabditidae','MEARVK-LLC-2026'),
('Platyhelminthes',NULL,'Trematoda',NULL,'Plagiorchiida',NULL,NULL,'Schistosomatidae','MEARVK-LLC-2026'),
('Annelida',NULL,'Polychaeta',NULL,'Phyllodocida',NULL,NULL,'Nereididae','MEARVK-LLC-2026');

-- Full data load is performed by the install script (install-animalia.ps1)
-- which parses all 7238 families from animalia.coercus.config
