# JWSTF Administration CLI

The `admin/bin` directory contains native C and C++ command-line front ends for the local JWSTF administration layer.

## Programs

- `jwstf-admin-c` — C implementation.
- `jwstf-admin-cpp` — C++17 implementation.

## Build

```bash
cd admin/bin
make
```

The source files are intentionally kept beside the native build definitions. Compiled binaries are local build artifacts and are not required to be committed to Git.

## Commands

```text
status
services
modules
software
verify
doctor
install <component>
repair <component>
update <component>
remove <component>
```

Useful options:

```text
--json
--dry-run
--help
--version
```

The current command layer is deliberately review-first. Installation, repair, update, and removal requests **do not execute privileged shell commands**. They report an operation request and establish the contract for a future authorization/execution backend.

This keeps the native CLI aligned with the JavaFX administration console: both are local interfaces over the same intended administration model, rather than unrestricted privileged shells.
