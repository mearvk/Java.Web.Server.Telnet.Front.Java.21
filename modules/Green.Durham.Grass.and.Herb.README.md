# Green.Durham.Grass.and.Herb — Separate Repository

**This module is not a regular directory in this repo. It is a git submodule — it has its own repository.**

## What's going on

The path `modules/Green.Durham.Grass.and.Herb` is a **git submodule** (a gitlink,
tree mode `160000`), not normal files. It is the only submodule in this repo; every
other entry under `modules/` is an ordinary directory.

Because this repo has no `.gitmodules` file, git has no URL to resolve the submodule
against, so GitHub shows it as an empty/broken entry and a fresh checkout leaves an
empty directory. The content lives in its own repository (see link below).

## Pointer details

- **Submodule path:** `modules/Green.Durham.Grass.and.Herb`
- **Pinned subproject commit:** `e8d1fa05d4c4f45c99836cd6998d1c2a2d1b7cff`
- **Upstream repository (its own repo):**
  https://github.com/mearvk/Green.Durham.Grass.and.Herb

> Note: the upstream URL above is the expected location based on the module name and
> this account's naming convention. If the submodule actually lives elsewhere, update
> the link here (and, when ready, add a matching `.gitmodules` entry).

## To check it out locally

```sh
# If/when a .gitmodules entry exists:
git submodule update --init modules/Green.Durham.Grass.and.Herb

# Or clone it directly as its own repo:
git clone https://github.com/mearvk/Green.Durham.Grass.and.Herb.git
cd Green.Durham.Grass.and.Herb
git checkout e8d1fa05d4c4f45c99836cd6998d1c2a2d1b7cff
```
