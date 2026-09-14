# Senatorial — state upper-chamber contacts

Contact lists for the **upper chamber** (State Senate) of the U.S. states.

## Layout

```
senatorial/
  state/
    <state.name>.filtered.emails.txt        # flat file per state (majority)
    <state.name>/<state.name>.filtered.emails.txt   # older subfolder variant
```

State names are **lowercase**, with spaces written as dots — e.g.
`new.york`, `north.carolina`. A few of the original files use a subfolder
(`state/<name>/<name>.filtered.emails.txt`); newer states use the flat form
`state/<name>.filtered.emails.txt`.

## Unified format

Each newly-added state file is a single-column CSV:

```
email
first.address@example.gov
second.address@example.gov
...
```

- Line 1 is the header `email`.
- Each subsequent line is one senator's email address.
- Addresses are sorted and de-duplicated.

> Note: several original files predate this convention (some have no header,
> some a `Email` header, and one is spelled `lousiana`). Those originals were
> **left unchanged**. States added in bulk use the unified header format above.

## Unicameral jurisdictions (excluded)

- **Nebraska** — a single nonpartisan unicameral legislature (no separate
  senate). Its members appear under `../general.assembly/`.
- **District of Columbia** — a single Council (not a state).

## Source & attribution

Bulk-added lists were sourced from the public **Open States / Plural**
`openstates/people` dataset. Only currently-serving members whose **current
role is the upper chamber** (`type: upper`) were included, via each person's
official `email` field.

- Dataset: https://github.com/openstates/people
- Project: https://openstates.org / https://open.pluralpolicy.com/data/

Data is a point-in-time snapshot; rosters change with elections and vacancies,
so refresh periodically. Small shortfalls versus a chamber's full seat count
reflect current vacancies or members without a listed email.
