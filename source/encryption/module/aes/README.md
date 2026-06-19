# AES Encryption Module — NitroWebExpress™

**MEARVK LLC — Max Rupplin**

## Overview

Custom AES-variant encryption module using mixed-radix transformations across 21 rounds.

## Structure

- `two/EncryptionModule.java` — Primary encryption engine with multi-radix cipher intermix.
- `two/EncryptionModuleOriginal.java` — Preserved hardcoded original (runs when config disabled).
- `two/EncryptionModuleRunner.java` — Reads `aes2-config.xml`; dispatches configurable or original.
- `aes2-config.xml` — Master config: passes, radix, loops, output-flags, subpads, clearance.
- `flags/KnownUSServerFlag.java` — Output flag for known US servers between passes.
- `flags/UnknownUSAServerFlag.java` — Output flag for unknown/unverified USA servers.
- `math/ConvergentFields.java` — Convergence analysis between AES2 and US Calendar streams.

## Output Flags

Output flags can be posted between any two passes (configured in `aes2-config.xml`).

| Type | Class | Use Case |
|------|-------|----------|
| `known-us` | KnownUSServerFlag | Verified US server, no ACK required |
| `unknown-usa` | UnknownUSAServerFlag | Unverified USA server, optional ACK |

Each flag specifies: destination, port, protocol (TCP/TLS), authority-level, message, require-ack.

Coordinates with:
- US Calendar Module
- Future US Communications Modules

## Radix Stages

| Round | Radix | Purpose |
|-------|-------|---------|
| one() | Base 12 | Initial padding |
| two() i=2 | Base 18 | Field permutation |
| two() i=7 | Base 13 | Field permutation |
| two() i=6 | Base 6 | Field permutation |
| three() | Base 11, 12, 17 | Lightning rounds + intermix |
| four()–twentyone() | TBD | Reserved for additional cipher stages |

## Usage

```java
// Configurable (reads aes2-config.xml):
EncryptionModuleRunner.run(new Random(), "Title", "plaintext");

// Direct:
EncryptionModule em = new EncryptionModule(rng, "Title", new File("input.txt"));
em.one();
em.two();
em.three();
```

## Contact

Max Rupplin — mearvk@mearvk.us | mearvk@outlook.com
