# CityAnalysis™ Module

**Author:** Max Rupplin — MEARVK LLC  
**Contact:** mearvk@mearvk.us | mearvk@outlook.com  
**Phone:** 1.919.923.4239  
**Belt Requirement:** Green Belt or Brown Belt  
**IQ Requirement:** 180+  

---

## Overview

CityAnalysis™ gathers property records and deed information for North Carolina cities by contacting county Register of Deeds websites, then applies a trained AI speculation engine to infer patterns in lending, property transactions, and community behavior.

## Components

| File | Purpose |
|------|---------|
| `CityAnalysisMain.java` | Entry point — IDE or terminal |
| `CityAnalysisServer.java` | Fetches property/deed data from county websites |
| `CitySpeculationEngine.java` | AI module — entity extraction, speculation, recursive self-analysis |
| `CitySpeculationTrainer.java` | Moral-bound IQ spectrum spatial model trainer |
| `city-analysis-config.xml` | City list, URLs, connection settings |
| `cse-allowance-config.xml` | AI reasoning limits, IQ tiers, trainer params |
| `legalice.presumes.xml` | Presumptions, rules, lessons, proofs for citizen classes |

## Operations

1. **Load config** — Reads city list and selects default (Durham, NC)
2. **Fetch** — HTTP GET to county property records and Register of Deeds sites
3. **Extract** — Pulls dollar amounts, percentages, keywords, URLs from data
4. **Train** — Runs moral-bound spatial model with base-objection exponential falloff
5. **Speculate** — Generates inferences on financial patterns, market focus, community behavior
6. **Recursive speculation** — AI re-analyzes its own findings 1–3 passes, stopping if confidence drops

## Settings (cse-allowance-config.xml)

| Setting | Description |
|---------|-------------|
| `max-reasoning-time-ms` | Hard time limit on training (ms) |
| `max-inputs` | Maximum input files/entries processed |
| `input-value` | Importance weight of input (1–1000) |
| `age-of-treason` | Toggle for persistence-under-duress modeling |
| `max-heap-mb` | Memory ceiling for AI working set |
| `democrat-class` / `citizen-class` | Importance weights for class inference |
| `dominant-iq` | Central IQ for tier calculations |
| `tiers` | 5-level IQ falloff (157+ to baseline) |
| `recursive-speculation` | Max/min passes, confidence threshold |

## Trainer Settings

| Setting | Description |
|---------|-------------|
| `epochs` | Training iterations |
| `learning-rate` | Base gradient step size |
| `moral-bound-weight` | Constraint toward moral center |
| `dimensions` | Spatial model dimensionality |
| `base-objections` | Shyness, cause-aversion, social-distance with decay |
| `falloff-model` | Exponential decay of objection pressure |
| `learner-rate-spectrum` | Adaptive LR range (min/max) |

## Output

- `speculations/` — Initial speculation reports (timestamped)
- `speculations/recursive/<date>/<time>/` — Recursive pass outputs by datetime

## Usage

```bash
java CityAnalysisMain                          # Durham default, fetch only
java CityAnalysisMain Raleigh                  # Fetch for Raleigh
java CityAnalysisMain Durham input.data        # Full speculation on input file
```

## Concerns

- This module contacts live county government websites; respect rate limits
- Speculation outputs are heuristic inferences, not legal or financial advice
- Training time is bounded by `max-reasoning-time-ms` to prevent runaway
- Recursive passes halt early if model confidence degrades below threshold
- All citizen classes are presumed good-faith per `legalice.presumes.xml`

---

**This module is intended for 180+ IQ operators holding Green Belt or Brown Belt certification at this time.**
