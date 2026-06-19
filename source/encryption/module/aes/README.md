# AES Encryption Module — NitroWebExpress™

**MEARVK LLC — Max Rupplin**

## Overview

Custom AES-variant encryption module using mixed-radix transformations across 21 rounds.

## Structure

- `two/EncryptionModule.java` — Primary encryption engine with multi-radix cipher intermix.

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
Random rng = new Random();
EncryptionModule em = new EncryptionModule(rng, "Title", "plaintext");
// or from file:
EncryptionModule em = new EncryptionModule(rng, "Title", new File("input.txt"));
em.one();
em.two();
em.three();
```

## Contact

Max Rupplin — mearvk@mearvk.us | mearvk@outlook.com
