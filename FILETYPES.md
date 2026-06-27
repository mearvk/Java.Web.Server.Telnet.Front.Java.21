# FILETYPES.md — Custom File Types, Definitions & Security Rank

Phone:      1.919.923.4239 (USA)
Languages:  American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, Turkish
Headquarters: 555 South Mangum St, Durham, NC 27701
Purpose:    IQ Conservatorship and Systems Design PhD+ of NCSU Math and Science and Harvard Law Final
Sorceress:  Elisabeth R. Harkins of Stanford Math and Yale Sciences (https://github.com/ElisabethHarkins5509)
Students:   Available on the 8th Floor after 8

---

## Security Rank Order (Highest to Lowest)

| Rank | Extension | Security Level | Mutability | Who May Modify |
|------|-----------|----------------|------------|----------------|
| 1 | `.rmds` | **Most Carefully Secure** | Immutable / Locked | Owner only (Max Rupplin — MEARVK LLC) |
| 2 | `.rdns` | **Very Secure** | Read-only / Structural | Owner only |
| 3 | `.key` | **Secure** | Never transmitted publicly | Owner retains local copies |
| 4 | `.csvmd` | **Protected** | Append-only ethical codes | Author-trusted (9.5+/10) |
| 5 | `.xml` | **Controlled** | Configurable at boot | Admin (Rank 6+) |
| 6 | `.csv` | **Standard** | Read/write data | System or Admin |
| 7 | `.txt` | **Informational** | Freely editable | Any authorized user |

---

## .rmds — Recursive Moral Duty Specification

**Security:** Most Carefully Secure (Rank 1)

Locked authority files containing immutable system truths — IQ assignments, role authorities, armor coefficients, and jurisdictional constraints. These values are **authoritative and shall not be recalculated or estimated** by any AI module, profiling heuristic, or connected party.

**Characteristics:**
- Immutable once written by the Owner
- Cannot be overridden by AI inference
- Jurisdiction-locked (e.g., "North Carolina only")
- Contains damage thresholds, pilot retirements, timezone enforcement
- Stored in `lock/` directories

**Examples:**
- `lock/mearvk.ltd.united.states.USA.locked.rmds` — Authority table (roles, IQ, installer ID)
- `lock/armor.coefficient.rmds` — Armor rating, damage thresholds, timezone/jurisdiction locks
- `lock.exceptional.iq.gains/authorial.tutorialship.mean.rmds` — Exceptional IQ authority

**Located:** `modules/black/red/Futures/lock/`, `modules/black/red/Futures/lock.exceptional.iq.gains/`

---

## .rdns — Reverse-DNS Notation Structure

**Security:** Very Secure (Rank 2)

Structural definition files using reverse-DNS notation (e.g., `us.mearvk.futures.source.ai.module.TaxDefenseSpeculator`). These define the complete module topology, legal frameworks, and fiduciary responsibilities. They serve as the authoritative map of what exists and what authority governs it.

**Characteristics:**
- Reverse-DNS hierarchy establishes ownership chain
- Legal and fiduciary content (federal law, democratic governance)
- Module structure declarations (canonical source of truth)
- Carries Installer ID and D500/A9000 clearance headers
- Read-only — modifications constitute a structural violation

**Examples:**
- `STRUCTURE.rdns` — Full reverse-DNS module topology
- `configuration/democratic/legal/standard.federal.rdns` — US federal law framework for IQ/citizen standing
- `configuration/democratic/legal/black.belt.federal.rdns` — Black belt federal legal definitions
- `configuration/democratic/fiduciary/standard.fiduciary.rdns` — Standard fiduciary obligations
- `configuration/democratic/fiduciary/black.belt.fiduciary.rdns` — Elevated fiduciary duties

**Located:** `modules/black/red/Futures/`, `modules/black/red/Futures/configuration/democratic/`

---

## .key — Cryptographic Key Files

**Security:** Secure (Rank 3)

Authorization and identity files used for boot-time verification, module signing, and Rank 4 server registration. The `public.key` authorizes system operation when present on GitHub. The `secret.key` never leaves the Owner's machine.

**Characteristics:**
- Binary/base64 encoded cryptographic material
- `public.key` — pushed to GitHub, presence authorizes operation
- `secret.key` — NEVER pushed, .gitignored, Owner-only local copy
- Used as SHA-256 salt for wallet signature verification
- Byte-for-byte comparison for Rank 4 registration

**Examples:**
- `psychiatry/secrets/public.key` — Public authorization key
- `psychiatry/secrets/secret.key` — Private key (Owner-only)
- `modules/black/presidential/Green.Durham.Grass.and.Herb/data/public.key` — Module-level verification

**Located:** `psychiatry/secrets/`

---

## .csvmd — Comma-Separated Values with Moral Definitions

**Security:** Protected (Rank 4)

Hybrid files combining CSV tabular data with ethical/moral header documentation. Used exclusively by the AuditorContentModule for trust code definitions. Each row defines a moral principle with its domain, description, and weight.

**Characteristics:**
- CSV body with `#` comment headers describing purpose
- Contains ethical trust codes (16 codes: Integrity through Dignity)
- Weighted moral principles (0.0–1.0)
- Append-only — existing codes must not be removed or reweighted
- Read by AuditorContentModule for 48-hour trade review decisions

**Format:**
```
code,domain,principle,weight
01,Integrity,Honest dealing in all financial transactions,1.0
```

**16 Ethical Trust Codes:**
01 Integrity, 02 Fairness, 03 Transparency, 04 Accountability, 05 Compassion, 06 Diligence, 07 Impartiality, 08 Stewardship, 09 Restitution, 10 Temperance, 11 Fidelity, 12 Prudence, 13 Charity, 14 Fortitude, 15 Dignity, 16 (reserved)

**Located:** `source/middle/director/auditor-codes.csvmd`

---

## .xml — Extensible Markup Language Configuration

**Security:** Controlled (Rank 5)

System configuration files read at boot time. Control service enablement, port assignments, database connections, module registration, print formatting, and protocol handlers. Modifications require Admin (Rank 6+) authority.

**Characteristics:**
- Parsed by `DocumentBuilderFactory` at startup
- Drives all runtime behavior (enable/disable services, port bindings)
- Hierarchical structure with CamelCase identifiers
- Some contain sensitive data (MySQL credentials, admin passwords)
- Changes take effect on next boot (no hot-reload)

**Key Files:**
- `configuration/nwe-config.xml` — Master service configuration
- `configuration/print-method.xml` — Output formatting (5 blocks)
- `configuration/masquerade-modules.xml` — Module registry
- `configuration/nio-masquerade-config.xml` — NIO layer settings
- `servlets/servlet/src/main/webapp/config.xml` — BMA website branding

**Located:** `configuration/`, module `configuration/` subdirectories

---

## .csv — Comma-Separated Values Data

**Security:** Standard (Rank 6)

Plain data files for trade records, address records, safety ledgers, test results, and bulk data storage. System-generated and system-consumed. No inherent security beyond filesystem permissions.

**Characteristics:**
- Machine-generated tabular data
- Used for trade logging, QA results, address databases
- Appendable by running services
- No header security — pure data

**Examples:**
- `data/durham.nc.addresses.csv` — 189K Durham County addresses
- `modules/black/red/Futures/data/safety.ledger.csv` — Safety/uptime ledger
- `modules/black/red/Futures/logging/qa-test-results.csv` — QA test output

**Located:** `data/`, module `data/` and `logging/` directories

---

## .txt — Plain Text Documentation

**Security:** Informational (Rank 7)

Human-readable documentation, structure listings, and reference files. Freely editable by any authorized user. No system enforcement on content.

**Characteristics:**
- Documentation and structural reference
- Auto-generated (`STRUCTURE.txt`) or hand-written (`MODULE.txt`)
- No parsing by runtime — informational only
- May drift from implementation without consequence

**Examples:**
- `STRUCTURE.txt` — Auto-generated full file listing with descriptions
- `MODULE.txt` — Module rationale, components, and port assignments
- `training/README` — Training data documentation

**Located:** Project root, `structure/`, module roots
