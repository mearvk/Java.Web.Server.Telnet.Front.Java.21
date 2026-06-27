MearvK Ltd - MEARVK LLC

Maximlian Eric Alexander Rupplin von Keffikon - MEARVK - MEARVK LLC

Owner of Establishment of Corporate ongoing Finance - US United States a Minister

Owner of Miramax Films UK & US United States and Settlement - NO GODZILLA

Owner of Del Taco in Apple Valley, CA '95

Owner of AtlAtl.phd Brand Clothing US United States

Phone:      1.919.923.4239 (USA)

Languages:  American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, Turkish

Headquarters: 555 South Mangum St, Durham, NC 27701

Purpose:    IQ Conservatorship and Systems Design PhD+ of NCSU Math and Science and Harvard Law Final

Sorceress:  Elisabeth R. Harkins of Stanford Math and Yale Sciences (https://github.com/ElisabethHarkins5509)

Students:   Available on the 8th Floor after 8

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
- Discussions / Rank Upgrades / Installer IDs / Public Key Requests: https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions

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

## Modules/Black — Forward Directives (Trusted 9.5+/10)

Trusted AI and governance modules authored by Max Rupplin - NC - MEARVK LLC. Forward directives for US Democratic block and North Carolina Socialist-College block. All modules are masquerade-aware, discoverable by `NioModuleScanner` at startup, and registered in `configuration/masquerade-modules.xml`.

| Module | Port(s) | Block | Source |
|--------|---------|-------|--------|
| Democratic ProFront National 1.0 (Futures™) | 5000 | US Democratic | `modules/black/red/Futures` |
| Green.Durham.Grass.and.Herb™ | 2000, 20000, 40002, 40003, 40007, 49152 | NC Socialist-College | `modules/black/presidential/Green.Durham.Grass.and.Herb` |
| Brarner.M.Alete™ | 49152 | NC Socialist-College | `modules/black/presidential/Brarner.M.Alete` |

**Futures™ (US Democratic Block):** D500 Democratic President. AI tax defense speculation, protective procedural pipeline using Java `CompletableFuture` patterns (supplyAsync, thenCompose, thenCombine, allOf, exceptionally). DJL/PyTorch inference. Port 5000 with secure random wait. Local masquerade config at `modules/black/red/Futures/configuration/nio-masquerade-config.xml`.

**Green.Durham.Grass.and.Herb™ (NC Socialist-College Block):** Appree contact server with labor/ethical/moral/mortality concerns database. JWSTFJ21 masquerade-integrated with extended virtual ports (70000–99152). Reflective integration degrades to standalone if parent absent. Local integration config at `modules/black/presidential/Green.Durham.Grass.and.Herb/configuration/jwstfj21-integration.xml`.

**Brarner.M.Alete™ (NC Socialist-College Block):** Presidential species/postal/SSA/art/science module. Maven multi-module (servlets, EJB, EAR). NC college block. Gluon-styled servlet website with tabbed navigation (Overview, Species, Postal, Art, Science, Status), filterable download tables, admin dashboard, and config.xml-driven branding with split MEARVK LLC logos. Install scripts for Linux/macOS/Windows with optional remote Apache deploy to `http://name.com/brarner.m.alete`. JAR download scripts fetch Jakarta Servlet 6.1, MySQL Connector/J 8.3, and Tomcat Embed 11.0.2. Local masquerade config at `modules/black/presidential/Brarner.M.Alete/configuration/nio-masquerade-config.xml`.

**Trust:** All modules rated 9.5+/10 by Author. Masquerade routing enabled globally.

---

## CityAnalysis™ — Property Records & AI Speculation Engine

City-level property and deed analysis module with AI-driven speculation. Fetches county Register of Deeds data, extracts financial entities, trains a moral-bound IQ spectrum spatial model, and generates recursive speculation reports.

**Belt Requirement:** Green Belt or Brown Belt | **IQ Requirement:** 180+

**Components:** `CityAnalysisMain`, `CityAnalysisServer`, `CitySpeculationEngine`, `CitySpeculationTrainer`

**Configuration:**
- `source/city-analysis/city-analysis-config.xml` — City list (15 NC cities, Durham default)
- `source/city-analysis/cse-allowance-config.xml` — AI reasoning limits, IQ tiers, trainer params
- `source/city-analysis/legalice.presumes.xml` — Citizen class presumptions

**Output:** `source/city-analysis/speculations/` and `speculations/recursive/<date>/<time>/`

**Source directory:** `source/city-analysis/`

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

## Strernary™ Directory Server — Port 2000

Telnet-accessible directory and routing server on port 2000. Provides an interactive menu for discovering known servers and registering new Rank 4 nodes, plus XML packet forwarding for NIO masquerade routing.

**Interactive menu options:**
| Option | Description | Auth |
|--------|-------------|------|
| 1 | List port 20000 server IPs (Strernary™) | NationalID (configurable) |
| 2 | List port 49152 server IPs (NationalFinanceID) | NationalID required |
| 3 | Register Rank 4 JWSTNJ21 server | public.key verification |
| 4 | Quit | — |

**XML forwarding mode:** If the first data received is an `<nwe-route>` XML packet, the server bypasses the interactive menu and forwards the payload directly to the target port via the NIO masquerade engine:
```xml
<nwe-route><port>20000</port><payload>ASK|What is life?</payload></nwe-route>
```

**Rank 4 registration:** Clients submit their `public.key` contents (base64, single line). The server compares byte-for-byte against the GitHub-hosted `public.key`. On match, the client's server address is added to the registered Rank 4 list.

**Configuration:** `configuration/port-2000-directory-config.xml` — Controls which menu options are enabled, NationalID requirements, and XML forwarding toggle.

**Known server lists:**
- `configuration/known.port.20000.servers.xml` — Strernary™ endpoints
- `configuration/known.port.49152.servers.xml` — NationalFinanceID endpoints

**Source:** `source/strernary/StrernaryDirectoryServer.java`

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

---

## Memory Footprint (Rough Estimates)

Approximate heap/RSS at steady state on Linux x86_64, Java 21 with virtual threads.

**Core:**

| Component | Estimated Memory | Notes |
|-----------|-----------------|-------|
| NitroWebExpress™ (main server) | ~60 MB | Base JVM + NIO selector + config |
| NIO Masquerade Layer | ~20 MB | Selector engine, 18 local IP bindings |
| MySQL JDBC pool | ~15 MB | Connection pool (idle) |
| Print system + CommonRails | ~5 MB | Formatting, color, XML config |

**Modules (per-module, when active):**

| Module | Estimated Memory | Notes |
|--------|-----------------|-------|
| DJL Inference (Strernary™) | ~350 MB | DistilBERT model weights (~250 MB) + PyTorch native |
| Strernary™ Server (port 20000) | ~25 MB | TCP socket handler + knowledge DB cache |
| Strernary™ Directory (port 2000) | ~10 MB | Menu, XML forwarding, registered server lists |
| International Signal Servers (each) | ~30 MB | Per-country: Japan, Russia, Mexico, Greece, Ukraine, Britain |
| CityAnalysis™ | ~40 MB | Speculation engine + trainer + recursive output buffers |
| AIProctorModule™ (port 49111) | ~20 MB | Session state + NationalID verification |
| AIIntegrativeEngine + Training | ~80 MB | Shared model + scouting buffer (up to 200 MB during training) |
| HeuristicClassifier™ | ~15 MB | Rate tables, geo-concentration maps, findings |
| BitcoinCompliant (port 6682) | ~25 MB | Wallet indexer + trade session state |
| AES/DSA/RSA Encryption | ~10 MB | Key material + pass buffers |
| NationalFinanceID (port 49152) | ~20 MB | Keypair generator + profile cache |
| Communicator (port 49199) | ~15 MB | Chat history + message queues |
| Weather/Calendar/ASCII | ~10 MB | Lightweight socket handlers |
| GrayPortRegistry (port 9999) | ~30 MB | NIO selector + block map + AI gate + DB pool |
| Gray85 Crème Registry (port 10085) | ~35 MB | NIO selector + block map + Crème state + AI gate + DB pool |

**Totals (approximate):**

| Profile | Estimated RSS | Description |
|---------|---------------|-------------|
| Minimal (core only) | ~100 MB | NitroWebExpress + NIO + MySQL |
| Standard (no DJL) | ~450 MB | Core + all modules including Gray registries, DJL disabled |
| Full (DJL loaded) | ~800 MB | All modules + PyTorch model loaded |
| Training burst | ~1000 MB | Full + AITrainingThread scouting buffer at capacity |
| Full + Gray registries active | ~865 MB | Full + both port registries with lease maps populated |

**Recommended JVM flags:**
```
-Xms256m -Xmx1024m -XX:+UseZGC
```

---

## GrayPortRegistry™ — 30M Port Block Leasing (Bitcoin/Dashcoin)

Port registry service that leases blocks of 30,000,000 ports via Bitcoin or Dashcoin payment. Two tiers: standard (port 9999) and Crème (port 10085).

**Brand:** Installer ID Tech™

### Standard Registry (Port 9999)

- **Block size:** 30,000,000 ports per block
- **Available blocks:** 1000 (total capacity: 30 billion ports)
- **Minimum donation:** $10 USD in Bitcoin or Dashcoin
- **Terms:** `month` (30 days), `year` (1 year), `multi-year` (3 years)
- **Database:** `nwe_gray_registry` (MySQL)
- **AI Gate:** Each port binding passes through an AI binary gate for authorization

**Protocol (TCP on port 9999):**

| Command | Format | Description |
|---------|--------|-------------|
| LEASE | `LEASE\|<block_id>\|<term>\|<btc_txid>` | Lease a port block. Provide Bitcoin/Dashcoin transaction ID as payment proof. |
| STATUS | `STATUS\|<block_id>` | Check if a block is available or leased (shows expiry). |
| BIND | `BIND\|<block_id>\|<port>` | Bind a specific port within your leased block. AI-gated. |
| LIST | `LIST` | List all active leases. |
| QUIT | `QUIT` | Disconnect. |

**How to Pay and Lease:**

1. Send $10+ USD equivalent in Bitcoin or Dashcoin to the published wallet address.
2. Connect to port 9999 via telnet/TCP: `telnet <server-ip> 9999`
3. Issue: `LEASE|<block_id>|month|<your_btc_txid>`
4. On success, server responds: `LEASED|block=<id>|ports=<start>-<end>|term=month|txid=<txid>`
5. Bind individual ports: `BIND|<block_id>|<port_number>`
6. Server responds with the resolved 127.0.X.X binding address.

**Port resolution:** Absolute port numbers map to local IPs via `127.0.<octet3>.<octet4>:<local_port>` where `octet3 = port / 65536 / 256`, `octet4 = port / 65536 % 256`, `local_port = port % 65536`.

### Gray85 Crème Registry (Port 10085)

Same as standard but 15 out of every 100 ports are Crème-locked (planetary auditor control).

- **Open ports:** 85% of block ($10 USD lease)
- **Crème-locked ports:** 15% of block ($1000 USD to unlock, 1 hour minimum)
- **Database:** `nwe_gray85_registry` (MySQL)

**Additional commands:**

| Command | Format | Description |
|---------|--------|-------------|
| UNLOCK | `UNLOCK\|<block_id>\|<port_offset>\|<hours>\|<btc_txid>` | Unlock a Crème port for N hours ($1000/unlock). |
| CREME | `CREME\|<block_id>` | List which ports in a block are Crème-locked. |

**Example session:**
```
$ telnet server.example.com 9999
═══════════════════════════════════════════════════════════════
 Installer ID Tech™ — Port Registry Service
 $10 USD minimum donation — Bitcoin/Dashcoin accepted
 30,000,000 ports per block — 1000 blocks available
═══════════════════════════════════════════════════════════════
LEASE|42|month|abc123def456txid
LEASED|block=42|ports=1260000000-1289999999|term=month|txid=abc123def456txid
BIND|42|1260000001
BOUND|block=42|port=1260000001|ip=127.0.75.49:37761
QUIT
```

**Source:**
- `modules/gray/source/GrayPortRegistryServer.java` — Standard registry (port 9999)
- `modules/gray.a85/source/Gray85PortRegistryServer.java` — Crème registry (port 10085)
