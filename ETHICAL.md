# ETHICAL.md — Ethical Framework

Phone:      1.919.923.4239 (USA)
Languages:  American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, Turkish
Headquarters: 555 South Mangum St, Durham, NC 27701
Purpose:    IQ Conservatorship and Systems Design PhD+ of NCSU Math and Science and Harvard Law Final
Sorceress:  Elisabeth R. Harkins of Stanford Math and Yale Sciences (https://github.com/ElisabethHarkins5509)
Students:   Available on the 8th Floor after 8

---

## Ethical Concerns Database

The system maintains a dedicated `ethical` table in `green_durham_grass_and_herb` MySQL database, accessed via `EthicalConcerns.java` in the Green.Durham.Grass.and.Herb™ module. This stores ethical queries, decisions, and evaluations for all module operations.

**Source:** `modules/black/presidential/Green.Durham.Grass.and.Herb/source/ethical/EthicalConcerns.java`
**Config:** `modules/black/presidential/Green.Durham.Grass.and.Herb/configuration/ethical-db-config.xml`


## Ethical Trust Codes (.CSVmd)

The AuditorContentModule uses 16 ethical trust codes stored in `.CSVmd` format. These codes govern:
- Trade approval or rejection
- 48-hour hold decisions
- Content compliance verification
- Goal alignment auditing

Trades that pass the ethical trust code evaluation receive "safe approval" status. Those that fail are held for 48-hour auditor review.

**Source:** `source/middle/director/AuditorContentModule.java`
**Weight:** 19 (highest in the edge schedule — ethical audit is final)


## Ethical Gating in Module Installation

Module installation (port 2000, Green.Durham.Grass.and.Herb) requires:
1. Valid Installer ID from MEARVK LLC (Max Rupplin)
2. National ID on file
3. Moral Rating of "Very Good" or better
4. IQ over 125

Modules from sources failing any criterion are rejected outright.

**Source:** `modules/black/presidential/Green.Durham.Grass.and.Herb/source/listeners/ModuleInstallListener.java`


## AI Training — Ethical Content Scoring

The AITrainingThread scores all training data on a mortality/ethical quality axis (0.0–1.0). Content must score ≥ 0.40 on moral quality to be accepted into the training set. This prevents ethically questionable data from contaminating the model.

Moral verdict sourcing priority:
- **HOUSING** — Module's own innate knowledge XML (trust 0.95)
- **LOCAL** — Local NWE connector (trust 0.80)
- **INTERNET** — Public internet scouting (trust 0.40)

**Source:** `source/international/radio/AITrainingThread.java`


## CityAnalysis — Ethical Speculation Boundaries

The CitySpeculationEngine operates within a moral-bound IQ spectrum. Speculation outputs include a `moral-spectrum` field that rates the ethical quality of each property/deed analysis. Recursive speculation reports self-grade on ethical alignment.

**Config:** `source/city-analysis/cse-allowance-config.xml` (IQ tiers, moral bounds)


## Port Leasing — Ethical AI Gate

GrayPortRegistry™ (port 9999) passes every port BIND request through an AI binary gate. This gate evaluates the ethical standing of the requesting party before authorizing port usage. Binding is refused if the gate returns negative.

**Source:** `modules/gray/source/GrayPortRegistryServer.java`


## Trade Evaluation — Ethical Direction

The TradeEvaluator determines if a trade is "upward/better" based on:
- Trust level (threshold: 50)
- Education grade of reasoning

Trades that are upward/better receive immediate approval. All others enter 48-hour auditor hold — a cooling period for ethical review before execution.

**Source:** `source/middle/director/TradeEvaluator.java`


## GamesAsGoals — Ethical IQ Tiers

The GamesAsGoalsModule applies tiered ethical acceptance:
- IQ 150+: accepted unconditionally (angular math, .mdmd sketches)
- IQ 125+: accepted only if NationalID overall trust value ≥ 70

This prevents low-trust participants from accessing high-impact game-goal integrations regardless of IQ.

**Source:** `source/middle/director/GamesAsGoalsModule.java`


## State Savings — Ethical Fiscal Policy

Strategic goals configuration includes "moral savings" — savings programs tied directly to ethical conduct. These are enabled by default and represent fiscal initiatives that reward moral behavior at the state level.

**Config:** `configuration/strategic-goals-config.xml`
