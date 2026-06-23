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

## International Signal Servers

Country-specific signal servers that connect to international news, market, and data sources. Each runs on its own port, uses virtual threads (Java 21), and stores data in a dedicated MySQL database.

| Server | Port | Database | Sources | Signals |
|--------|------|----------|---------|---------|
| JapanSignalServer™ | 49201 | `nwe_japan` | NHK, Mainichi, Asahi, Nikkei, Kyodo, JPX, JMA | Nikkei 225, JPY/USD, Seismic |
| RussiaSignalServer™ | 49202 | `nwe_russia` | TASS, RIA, Interfax, RBC, MOEX, Kommersant, Vedomosti, RT | MOEX Index, RUB/USD, Brent Crude |
| MexicoSignalServer™ | 49203 | `nwe_mexico` | El Universal, Reforma, Milenio, La Jornada, Expansión, El Financiero, BMV, Excélsior | IPC/BMV, MXN/USD, Pemex Crude |
| GreeceInternationalSignalServer™ | 49204 | `nwe_greece_intl` | Kathimerini, AMNA, Naftemporiki, Capital.gr, Reuters, Al Jazeera, BBC, DW | Athens Exchange, EUR/USD, Baltic Dry Index |

**Protocol:** TCP socket — `FETCH|<sourceId>|<url>`, `SIGNAL|<url>`, `STATUS`

**Port-aware:** 21, 22, 80, 443, 8080, 8888 for outbound connections.

**Source directories:**
- `source/international.radio.japan/` — Japan config and server
- `source/international.radio.russia/` — Russia config and server
- `source/international.radio.mexico/` — Mexico config and server
- `source/greece/international/` — Greece/International config and server

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

---

## Strernary™ — Best-Guess Inference Server

Port 20000 inference server that accepts standard information and returns best-guess responses.

**Dual-port architecture:** A public OS port and a Java edition port both occupy port 20000. They sometimes talk; sometimes they don't. Communication is opportunistic — the Java server probes the OS listener at startup and relays queries when it's alive.

**Inference stack (priority order):**
1. **DJL (Deep Java Library)** — Local PyTorch inference via Amazon's open-source DJL framework. Download jars with `scripts/bash/strernary/download-djl.sh`.
2. **OS port relay** — Forwards to the OS-level listener on 20000 if alive.
3. **Keyword heuristics** — Routes queries to known NWE services based on content keywords.

**Protocol:** TCP socket — `ASK|<text>`, `RELAY|<text>`, `STATUS`

**Source directory:** `source/strernary/`

---

## NIO Masquerade Layer

NIO-based front layer that binds local IPs 127.0.0.1 through 127.0.0.17 and bridges non-blocking NIO connections to the existing blocking architecture.

**Port range modes:**
| Mode | Range | Binding |
|------|-------|---------|
| standard (default) | 0–65535 | All managed ports on 127.0.0.1 |
| extended | 0–1048576 | 65536 ports per IP across 127.0.0.1–17 |

**Module discovery:** At startup, `NioModuleScanner` reads `nwe-config.xml` and `masquerade-modules.xml` to discover all MEARVK LLC modules with their port values (0 to MAX_PORT). Masquerade-aware modules are registered in the NIO routing table automatically.

**Port 2000 XML forwarding:** Clients can send XML packets to port 2000 for direct routing:
```xml
<nwe-route><port>20000</port><payload>ASK|What is life?</payload></nwe-route>
```

**Configuration files:**
- `configuration/nio-masquerade-config.xml` — NIO settings, port range mode, managed ports
- `configuration/masquerade-modules.xml` — Module registry with auto-discovery
- `configuration/port-2000-directory-config.xml` — Port 2000 directory/forwarding settings

**Source files:**
- `source/strernary/NioMasqueradeEngine.java` — NIO Selector engine with local IP bindings
- `source/strernary/NioModuleScanner.java` — Startup module discovery and registration
- `source/strernary/StrernaryDirectoryServer.java` — Port 2000 menu + XML forwarding
