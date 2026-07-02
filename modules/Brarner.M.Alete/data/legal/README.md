# BMA Legal Data Directory

## Sources

| Source | URL | Data Type |
|--------|-----|-----------|
| GovInfo (GPO) | https://www.govinfo.gov/ | US Code, Public Laws, Statutes at Large, CFR |
| CourtListener (Free Law Project) | https://www.courtlistener.com/ | Case Law, Court Opinions, Citations, Dockets |
| Caselaw Access Project (Harvard) | https://case.law/ | Historical US Case Law (6.5M+ decisions) |

## Directory Structure

```
data/legal/
├── README.md                    — This file
├── legal.sites.001.txt          — Source descriptions
├── legal.sites.002.txt          — Source URLs
├── sources.xml                  — Machine-readable source config
├── us-code/                     — US Code (statutory law) from GovInfo
│   ├── titles/                  — Individual USC title XML files
│   └── uscode-summary.csv      — Title index with section counts
├── public-laws/                 — Public Laws from GovInfo
│   └── plaw-index.csv          — Index of downloaded public laws
├── statutes-at-large/           — Statutes at Large from GovInfo
├── case-law/                    — Case law from CourtListener
│   ├── courts.csv              — Court metadata
│   ├── opinions.csv            — Opinion text & metadata
│   ├── citations.csv           — Citation map (what cites what)
│   └── dockets.csv             — Docket metadata
├── precedent/                   — Landmark precedent cases
│   └── landmark-cases.csv      — Key US Supreme Court precedents
├── cfr/                         — Code of Federal Regulations
└── counts/                      — Whole law counts & statistics
    ├── usc-title-counts.csv    — Sections per USC title
    ├── public-law-counts.csv   — Laws per Congress
    └── court-opinion-counts.csv— Opinions per court/year
```

## Download Scripts

- `download-legal-data.sh` — Main download script (Linux)
- `download-govinfo.sh` — GovInfo US Code & Public Laws downloader
- `download-courtlistener.sh` — CourtListener bulk case law downloader

## Notes

- CourtListener bulk data is regenerated quarterly (last day of Mar/Jun/Sep/Dec)
- GovInfo API requires a free api.data.gov key (sign up at https://www.govinfo.gov/api-signup)
- All data is public domain or free of known copyright restrictions
- Harvard Caselaw Access Project data is transitioning to CourtListener/Free Law Project
