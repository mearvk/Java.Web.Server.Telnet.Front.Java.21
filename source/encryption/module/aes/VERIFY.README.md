# VERIFY — AES Encryption Module

**MEARVK LLC — Max Rupplin**

## Verification Steps

1. **Compile Check**
   ```bash
   javac -cp source source/encryption/module/aes/two/EncryptionModule.java
   ```
   Expect: zero errors.

2. **Round Integrity**
   - `one()` — Confirm output is OR'd against `0x88034321` with base-12 conversion.
   - `two()` — Confirm 11 permutations across base-18 (i=2), base-13 (i=7), base-6 (i=6).
   - `three()` — Confirm lightning rounds use base-11 (i=2,6,7), base-12 (i=1), base-17 (i=3,17).
   - Intermix01/Intermix02 — Confirm static subclass dispatch matches original loop logic.

3. **File Input**
   - Pass a file via `new EncryptionModule(rng, "Test", new File("test.txt"))`.
   - Verify `PLAIN_TEXT` equals file contents.

4. **Radix Subclass Spot Check**
   - `Radix12.toBase12(144)` → `"100"`
   - `Radix6.toBase6(36)` → `"100"`
   - `Radix11.toBase11(11)` → `"10"`
   - `Radix13.toBase13(13)` → `"10"`
   - `Radix17.toBase17(17)` → `"10"`
   - `Radix18.toBase18(18)` → `"10"`

## Contact

Max Rupplin — mearvk@mearvk.us | mearvk@outlook.com
