# General Assembly — state legislature contacts

This folder holds contact lists for the **state legislatures** (the "General
Assembly": upper chamber / senate + lower chamber / house) of the U.S. states
and the District of Columbia.

## Layout

```
general.assembly/
  state/
    <state.name>/
      <state.name>        # the contact file (no extension)
```

Folder and file names are **lowercase**, with spaces written as dots — e.g.
`north.carolina`, `new.hampshire`, `district.of.columbia`.

## Unified format

Each state file is a single-column CSV:

```
email
first.address@example.gov
second.address@example.gov
...
```

- Line 1 is the header `email`.
- Each subsequent line is one legislator email address.
- Addresses are sorted and de-duplicated.

> Note: a few of the earliest state files predate this convention and are a
> bare list of addresses without the `email` header. New states added in bulk
> use the unified header format above. Existing files were **not** modified.

## Source & attribution

The bulk-added state lists were sourced from the **Open States / Plural**
`openstates/people` dataset — curated, public information on state legislators
aggregated from official state legislative sites.

- Dataset: https://github.com/openstates/people
- Project: https://openstates.org / https://open.pluralpolicy.com/data/

Only the top-level official `email` field of each currently-serving legislator
(`data/<state>/legislature/*.yml`) was extracted. These are public officials'
official government contact addresses.

Data reflects the dataset at the time of extraction; rosters change with
elections, appointments, and resignations, so treat these as a point-in-time
snapshot to be refreshed periodically from the source.
