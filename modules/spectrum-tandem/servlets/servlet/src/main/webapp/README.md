# SpectrumTandem™ — Dolyene Spectrum of Int Discipline

**NitroWebExpress™ Module**
Author: Maximilian Eric Alexander Rupplin von Keffikon — MEARVK LLC
Installer Tech ID: Max Rupplin
Port: 49222
Database: nwe_spectrum_tandem
Context: /spectrum-tandem

---

## Purpose

Graphs the **dolyene** (spectrum of int discipline) of use of term for any special spelling of term or radix or term or spelling of radix or other conditions of spelling int.

Core features:
- **Word Bank** — Store terms with definitions, specialness classifications, radix roots, spelling variants, and author/revisionist IDs
- **Dolyene Spectrum** — Graph the int discipline spectrum for any term, showing how different spellings distribute across discipline indices
- **County Precedent** — Full capitalized term of precedent (COUNTY) with pointers, indirections, revisions, and caliber
- **Revisions** — Immutable revision history with old/new definitions, revisionist IDs, and timestamps
- **AI Integration** — Strernary™ inference for spectrum analysis and term search

---

## Key Terms

| Term | Radix | Specialness | Definition |
|------|-------|-------------|------------|
| dolyene | doly | CORE_CONCEPT | The spectrum of int discipline; graphical representation of term usage frequency across radix conditions |
| spectrum | spect | MEASURE | A range or continuum of values representing the spread of a term across its int discipline |
| radix | radix | LINGUISTIC | The root or base form of a term from which spelling variants derive |
| tandem | tand | OPERATIONAL | Two or more elements operating in conjunction; parallel execution of spectrum analysis |
| int discipline | intdi | MATHEMATICAL | The integer classification system governing term ordering and spectral weight |
| pointer | point | REFERENCE | A reference to another term or county precedent; indirection target |
| indirection | indir | REFERENCE | A layer of abstraction between a pointer and its final resolution |
| county | count | GOVERNANCE | Full capitalized term of precedent; jurisdictional authority over term definitions |
| caliber | calib | QUALITY | The quality or grade of a revision; measure of revision significance |
| specialness | speci | META | The categorical classification of a term within the word bank hierarchy |

---

## Protocol (Port 49222)

```
telnet localhost 49222

DEFINE|dolyene          → Get full definition
LOOKUP|spectrum         → Search by spelling/radix/variant
RADIX|doly              → Search by radix root
SPECTRUM|dolyene        → Get dolyene spectrum graph data
COUNTY|DURHAM           → Query county precedent
REVISE|dolyene|new def|Max Rupplin   → Revise a definition
ADD|newterm|definition|CORE|Max Rupplin  → Add term to word bank
HISTORY|dolyene         → Get revision history
WORDBANK                → List all terms
SEARCH|spelling         → AI-assisted search via Strernary™
STATUS                  → Module status
HELP                    → Command list
QUIT                    → Close session
```

---

## Database Schema (nwe_spectrum_tandem)

### word_bank
Stores terms, definitions, specialness, radix, spelling variants, authors, timestamps.

### dolyene_spectrum
Int discipline indices per term — spelling conditions, weights, radix conditions.

### county_precedent
Full capitalized COUNTY term of precedent — pointers, indirections, revisions, caliber.

### revisions
Immutable revision log — NO DELETE, NO UPDATE on this table. Append-only.

---

## Scripts

| Script | Purpose |
|--------|---------|
| `start-backend.sh` | Start TCP backend on port 49222 |
| `shutdown-backend.sh` | Stop TCP backend |
| `start-frontend.sh` | Deploy webapp to Tomcat |
| `shutdown-frontend.sh` | Undeploy webapp |
| `start.sh` | Legacy: deploy + start Tomcat |
| `shutdown.sh` | Full shutdown (backend + frontend) |
| `servlets/deploy-local.sh` | Deploy webapp to Tomcat webapps |
| `servlets/setup-db.sh` | Create database and seed data |

---

## Webapp

White background with red font lettering. CD1 button connector style for Strernary™/direct port routing.

Pages:
- **index.jsp** — Overview, term table, CD1 connector
- **wordbank.jsp** — Word bank CRUD, add new terms
- **spectrum.jsp** — Dolyene spectrum graphing (bar chart visualization)
- **county.jsp** — County precedent query and display
- **status.jsp** — Backend connectivity, protocol reference

---

## Contact

- GitHub: https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions
- Email: mearvk@mearvk.us | mearvk@outlook.com
