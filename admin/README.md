# JWSTF Local Administration

**Introduced:** 2026-08-24  
**Documentation Updated:** 2026-09-16

A polished JavaFX local administration console for Java 21.

## Design

The console follows the Ubuntu White direction:

- white cards and surfaces
- dark-grey typography
- restrained green health state
- generous spacing
- clear navigation
- high-DPI friendly JavaFX controls
- no unnecessary decoration

## Sections

- **Overview** — health and runtime identity
- **Services** — web server and Telnet frontend state
- **Software** — install, update, verify, remove, repair
- **Modules** — Aptitude and repository modules
- **Configuration** — `/user`, `/deck`, `/usr`, paths and environment
- **Evidence** — origin, custody, production, release
- **Maintenance** — diagnostics and reports

## Authorization model

The UI is deliberately not a privileged shell. Buttons create reviewable requests; execution should be delegated to the platform lifecycle controllers and require the host's normal authorization for privileged changes.

Removal applies to installed/generated artifacts and does not silently delete repository source.

## Build integration

The class is `us.house.admin.LocalAdmin`. The release build should package it with the repository's JavaFX 21 / Java 21 configuration and produce native artifacts with `jpackage` on the corresponding OS.

## Administration Descriptors

The administration layer is documented as local software, not as a governmental or external-authority interface. Its controls are review-first and privileged execution remains subject to host authorization.

| Program | Descriptor Date | Current Status |
|---|---|---|
| `LocalAdmin` | 2026-08-24 | JavaFX local administration console |
| `RoyalsUSGuardIAdmin` | 2026-08-24 | Defensive local administration profile |
| `StateSecurityDownIAdmin` | 2026-08-24 | Intentional failed-state test fixture |
| `jwstf-admin-c` | 2026-09-16 | Native C local administration CLI |
| `jwstf-admin-cpp` | 2026-09-16 | Native C++17 local administration CLI |

**Current revision date:** 2026-09-16.
