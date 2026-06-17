MearvK Ltd - MEARVK LLC

Maximlian Eric Alexander Rupplin von Keffikon - MEARVK - MEARVK LLC

Owner of Establishment of Corporate ongoing Finance - US United States a Minister

Owner of Miramax Films UK & US United States and Settlement - NO GODZILLA

Owner of Del Taco in Apple Valley, CA '95

Owner of AtlAtl.phd Brand Clothing US United States

![Profile views](https://views.igorkowalczyk.dev/api/badge/@mearvk?style=flat)

---

## Software Authorization & Key Terms

This software verifies its operational authorization by checking the presence of `psychiatry/secrets/public.key` on the central GitHub repository (`github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21`).

**If the public.key is present on GitHub**, the software is free to operate within all existing guidelines, agreements, and contracts as established by the Owner.

**Key Files:**
- `psychiatry/secrets/public.key` — Public authorization key. Pushed to GitHub. Presence authorizes operation.
- `psychiatry/secrets/secret.key` — Private key. NEVER pushed to GitHub (excluded via .gitignore). A local copy is kept exclusively by the Owner of the Software.

**Terms:**
1. The Owner of the Software (Max Rupplin, MEARVK LLC) retains local copies of both key files at all times.
2. The `secret.key` shall never be committed or pushed to any public or shared repository.
3. Removal of the `public.key` from the GitHub repository constitutes a revocation of operational authorization for all installations that depend on this verification.
4. All editions (Personal Executive, National, International, Free) are subject to this key verification at boot time.
5. The software operates within existing guidelines, agreements, and contracts only while the `public.key` remains accessible at its canonical GitHub URL.

**Contact:**
- Max Rupplin — mearvk@mearvk.us | mearvk@outlook.com

---

## Downloads

- **NWE Key Listener (C, port 80):** [`apache/nwe-key-listener`](apache/nwe-key-listener) — Standalone executable for Linux/Apache. Listens on port 80 for `public.key` POST, sends ACK, 30-minute timeout. Run with `sudo ./nwe-key-listener`.
- **NWE Module Installer (Java, port 8888):** [`standalone/nwe-module-installer.jar`](standalone/nwe-module-installer.jar) — Standalone JAR. Accepts modules from verified NWE instances. Run with `java -jar nwe-module-installer.jar`.
- **NWE Apache Module (mod_nwe_key):** [`apache/modules/mod_nwe_key.c`](apache/modules/mod_nwe_key.c) — Drop-in Apache2 module. Install with `sudo bash apache/modules/build-module.sh`. Provides `/nwe-key-listener/handshake` and `/nwe-key-listener/install` endpoints.

### NWE Key Listener — How It Works

1. On startup, fetches `public.key` from this GitHub repository for comparison.
2. **Phase 1 (Handshake):** Accepts POST on port 80. Strips HTTP headers, compares body byte-for-byte against the GitHub `public.key`. Sends `ACK` only on exact match. Records the verified IP.
3. **Phase 2 (JAR Install):** Accepts the next binary from the **same verified IP**. Validates JAR signature (PK magic bytes), computes SHA-256, installs to `/opt/nwe/nwe-module-installer.jar`, opens port 8888 via ufw/iptables, and launches the module installer.
4. Closes after 30 minutes if no valid `public.key` is received.

**Build requirements:** `libcurl4-openssl-dev`, `libssl-dev` (standalone), plus `apache2-dev` (for the module).

---

## Print System Configuration

All terminal output is driven by `configuration/print-method.xml`. No recompile needed to adjust formatting.

**Blocks (left-to-right):**
| Block | Name | Example |
|-------|------|---------|
| 1 | Prefix | `-- : ` |
| 2 | ObjectId | `[Object ID: 0925308434]` |
| 3 | Date | `[Date: 2026-06-16 22:17:55 EDT]` |
| 4 | Current | `[Current: @Main]` |
| 5 | Message | `. NitroWebExpress™ now starting .` |

**Additional controls in print-method.xml:**
- `<starts>` — Canonical lifecycle verb (`starts`, `is starting`, `now starting`, etc.)
- `<parent-class-prefix>` — Prepend owning class to message (enabled/disabled)
- `<decorator-start>` / `<decorator-end>` — Message framing characters (default `.`)
- `<grace>` — Fade animation timing (steps, delay, post-delay)
- `<control>` — Color toggle, reset behavior, trademark color

**Naming convention:** All module/service identifiers use CamelCase with ™ (trademark in red). Configured in `nwe-config.xml` with CamelCase server IDs (e.g. `AesCompliant`, `BitcoinWalletIndexer`).

**Startup failure handling:** If NweConfig, MySQL systemctl, or JDBC login fails, the message prints in red, the cause is appended to `exception.log`, and the process halts.
