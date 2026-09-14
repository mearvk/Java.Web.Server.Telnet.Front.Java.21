# MORALS.md — Moral Framework

Phone:      1.919.923.4239 (USA)
Languages:  American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, Turkish
Headquarters: 555 South Mangum St, Durham, NC 27701
Purpose:    IQ Conservatorship and Systems Design PhD+ of NCSU Math and Science and Harvard Law Final
Sorceress:  Elisabeth R. Harkins of Stanford Math and Yale Sciences (https://github.com/ElisabethHarkins5509)
Students:   Available on the 8th Floor after 8

---

## Moral Rating Scale

The system enforces a 9-tier moral rating scale for all participants:

| Index | Rating | Access Level |
|-------|--------|--------------|
| 0 | Very Poor | Denied |
| 1 | Poor | Denied |
| 2 | Below Average | Denied |
| 3 | Average | Denied |
| 4 | Above Average | Denied |
| 5 | Good | Denied |
| 6 | Very Good | **Minimum for module install** |
| 7 | Excellent | Full access |
| 8 | Outstanding | Full access + priority |

Minimum threshold for system participation: **Very Good** (index 6).

**Source:** `modules/black/presidential/Green.Durham.Grass.and.Herb/source/listeners/ModuleInstallListener.java`


## Moral Concerns Database

The system maintains a dedicated `moral` table in `green_durham_grass_and_herb` MySQL database. This stores:
- Moral evaluations of participants
- Moral verdicts on content
- Moral scoring of AI training data
- Historical moral decisions for audit trail

**Source:** `modules/black/presidential/Green.Durham.Grass.and.Herb/source/moral/MoralConcerns.java`
**Config:** `modules/black/presidential/Green.Durham.Grass.and.Herb/configuration/moral-db-config.xml`


## Moral Gating — Module Installation

All module installations require the submitter's Moral Rating to be "Very Good" or better. This is enforced at the protocol level — the server requests the rating during the handshake and validates against the scale before accepting any file data.

Combined moral requirements for module install:
- Moral Rating ≥ "Very Good"
- IQ > 125
- Valid Installer ID from MEARVK LLC
- Valid National ID on file


## Moral Verdicts in AI (AIIntegrativeEngine)

The AIIntegrativeEngine processes queries with moral verdict sourcing. Each response carries a moral verdict drawn from one of three sources:

| Source | Trust | Description |
|--------|-------|-------------|
| HOUSING | 0.95 | Module's own innate knowledge XML |
| LOCAL | 0.80 | Local NWE connector response |
| INTERNET | 0.40 | Public internet scouting |

Higher-trust sources override lower-trust sources. Internet-sourced moral verdicts are treated as provisional and may be overridden by local or housing sources.

**Source:** `source/international/radio/AIIntegrativeEngine.java`


## Mortality Score — AI Training

All AI training content is scored on a mortality/moral quality axis:
- Range: 0.0 to 1.0
- Acceptance threshold: ≥ 0.40
- Content below threshold is rejected from the training set

The mortality score evaluates whether content is morally sound enough to influence the AI model. This prevents the system from learning from morally corrupt or harmful data.

**Source:** `source/international/radio/AITrainingThread.java`


## Moral Savings — Strategic Goals

The strategic goals configuration defines "moral savings" as a fiscal policy instrument:
- Savings programs tied to ethical conduct
- Enabled by default in `strategic-goals-config.xml`
- Part of the "StateSavings" goal (weight 0.85)
- Description: "Savings tied to ethical conduct"

This represents the system's position that moral behavior should have tangible financial reward at institutional and state levels.

**Config:** `configuration/strategic-goals-config.xml`


## 48-Hour Moral Hold

Trades that do not meet the "upward/better" criteria (trust ≥ 50, adequate education grade) enter a 48-hour moral hold. During this period:
- The trade is logged but not executed
- An auditor reviews the moral standing of the request
- The AuditorContentModule applies 16 ethical trust codes
- Only after moral clearance does the trade execute

This ensures no financial transaction proceeds without moral validation.

**Source:** `source/middle/director/TradeEvaluator.java`
**Auditor:** `source/middle/director/AuditorContentModule.java`


## Trust Levels in the System

| Context | Threshold | Effect |
|---------|-----------|--------|
| Trade approval | ≥ 50 | Immediate execution |
| Trade hold | < 50 | 48-hour auditor review |
| GamesAsGoals (IQ 125+) | ≥ 70 | Access granted |
| Module trust rating | 9.5+/10 | Author-trusted modules |
| AI training (HOUSING) | 0.95 | Highest moral source |
| AI training (LOCAL) | 0.80 | Trusted local source |
| AI training (INTERNET) | 0.40 | Provisional moral source |

**Config:** `configuration/masquerade-modules.xml` (module trust levels)
**Config:** `configuration/known.port.2000.servers.xml` (moral rating requirements)


## Labor, Ethical, and Mortality Concerns

The Green.Durham.Grass.and.Herb™ module maintains separate databases for:
- **Labor concerns** — Worker rights, fair treatment, employment ethics
- **Ethical concerns** — Right/wrong determinations, code of conduct
- **Moral concerns** — Character, virtue, moral quality assessments
- **Mortality concerns** — Life/death weight, existential impact scoring

Each concern type has its own source directory, configuration, and MySQL table.

**Source directories:**
- `modules/black/presidential/Green.Durham.Grass.and.Herb/source/labor/`
- `modules/black/presidential/Green.Durham.Grass.and.Herb/source/ethical/`
- `modules/black/presidential/Green.Durham.Grass.and.Herb/source/moral/`
- `modules/black/presidential/Green.Durham.Grass.and.Herb/source/mortality/`
