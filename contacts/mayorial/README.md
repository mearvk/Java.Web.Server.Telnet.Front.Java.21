# Mayorial — municipal mayor contacts

Contact lists for **municipal mayors** (city-level), organized by state.

## Layout

```
mayorial/
  state/
    <state.name>/contacts.txt     # one file per state
  photo-directives/               # image assets (not a state)
```

State names are lowercase, spaces written as dots (e.g. `new.york`,
`north.carolina`). Each `contacts.txt` is a single column with an
`Email Address` header, one mayor/city-hall email per line.

## Sources

This folder combines two kinds of data:

1. **Original curated lists** — the substantial, hand-collected city-mayor
   lists already in the repository (e.g. California, Florida, Texas). These are
   the authoritative content and were **kept intact**.
2. **Additive backfill from Open States** — the public `openstates/people`
   dataset (https://github.com/openstates/people), limited to municipal people
   whose **current role is `mayor`** with a listed `email`. These were **merged
   in additively**: only addresses not already present were appended, and **no
   existing address was ever removed or overwritten**. States that had no file
   were created from this source.

## Coverage & limitations

Municipal-mayor contact data is **not** comprehensively available from a free,
openly-licensed source:

- The **U.S. Conference of Mayors** database (1,400+ mayors) is the most
  complete source but is **paid/subscription** and was therefore not used.
- The federal **get.gov / dotgov-data** list is public but its email column is
  a **domain security/DNS contact**, not the mayor — so it was **not** used for
  mayor emails.
- **Open States** municipal coverage is partial (a subset of cities per state),
  so the backfill fills gaps but does not make any state exhaustive.

As a result, the original curated lists remain richer than Open States for the
big states, and these files are a **point-in-time, non-exhaustive** snapshot.
Refresh periodically and prefer a dedicated mayor dataset if full coverage is
required.
