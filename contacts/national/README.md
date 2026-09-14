# national — country-level contacts

Contacts for national governments, organized by country. Each country has a
folder (lowercase, dot-separated, e.g. `united.states.of.america`) with one
file per role plus a references file.

## Layout

```
national/
  <country>/
    ambassador.csv        # diplomatic missions of this country (REAL data + refs)
    head.of.state.txt     # head of state / head of government (placeholder + refs)
    minister.txt          # government ministers (placeholder + refs)
    governor.txt          # subnational governors (placeholder + refs)
    mayoral.txt           # municipal mayors (placeholder + refs)
    REFERENCES.md         # sources for every role
```

## `ambassador.csv` — sourced data

Columns:

```
email,mission_type,host_country,city,address,phone,website,wikidata_qid
```

One row per diplomatic mission (embassy / consulate) that the country operates
abroad. `email` is the mission's published address where available; the other
columns (host country, city, address, phone, website, Wikidata QID) are the
supporting references. The `email` column may be blank when the source has no
published address for that mission.

**Source:** the **database-of-embassies** project — public domain, powered by
Wikidata.
- https://github.com/database-of-embassies/database-of-embassies
- https://database-of-embassies.github.io/

Coverage at import: **252 countries**, **10,457 missions**, **1,051** with a
published email.

## Placeholder role files — no fabricated addresses

`head.of.state.txt`, `minister.txt`, `governor.txt`, and `mayoral.txt` contain
only an `email` header and an explanatory note. **No email addresses were
invented for these roles.** There is no openly-licensed dataset of individual
heads-of-state / minister / governor / mayor email addresses; the *names* of
current office-holders are public (CIA World Leaders directory, Wikipedia), but
official contact is normally via an office/ministry website or contact form.

Each country's `REFERENCES.md` lists the real sources to use when adding
verified addresses. When you add an address, cite its source there; do not add
unverified or invented addresses.

## Sources referenced

- Diplomatic missions — database-of-embassies (public domain / Wikidata).
- Heads of state & cabinet — CIA World Leaders directory (public domain):
  https://www.cia.gov/resources/world-leaders/ ; Wikipedia current-leaders list.
- Foreign-ministry cross-check — Lowy Global Diplomacy Index:
  https://globaldiplomacyindex.lowyinstitute.org/

This data is a point-in-time snapshot; refresh periodically from the sources.
