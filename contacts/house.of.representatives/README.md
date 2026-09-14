# House of Representatives — state lower-chamber contacts

Contact lists for the **lower chamber** (State House of Representatives /
Assembly / House of Delegates) of the U.S. states.

## Layout

```
house.of.representatives/
  <state.name>        # one flat file per state (no extension)
```

File names are **lowercase**, with spaces written as dots — e.g.
`north.carolina`, `new.hampshire`.

## Unified format

Each state file is a single-column CSV:

```
email
first.address@example.gov
second.address@example.gov
...
```

- Line 1 is the header `email`.
- Each subsequent line is one representative's email address.
- Addresses are sorted and de-duplicated.

> Note: the original `north.carolina` file predates this convention and is a
> bare list without the `email` header; it was intentionally left unchanged.
> States added in bulk use the unified header format above.

## Unicameral jurisdictions (excluded)

Two jurisdictions have no separate house / lower chamber and are therefore
**not** included in this folder:

- **Nebraska** — a single nonpartisan unicameral legislature.
- **District of Columbia** — a single Council (not a state; no House).

Their members appear under `../general.assembly/` instead.

## Source & attribution

Bulk-added lists were sourced from the public **Open States / Plural**
`openstates/people` dataset. Only currently-serving members whose **current
role is the lower chamber** (`type: lower`) were included, using each person's
official `email` field.

- Dataset: https://github.com/openstates/people
- Project: https://openstates.org / https://open.pluralpolicy.com/data/

Data is a point-in-time snapshot; rosters change with elections and vacancies,
so refresh periodically from the source. Small shortfalls versus a chamber's
full seat count reflect current vacancies or members without a listed email.
