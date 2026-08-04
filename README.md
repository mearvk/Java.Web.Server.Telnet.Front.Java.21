# NitroWebExpress™

**National Finance Engine v2811.1**
Author: Maximilian Eric Alexander Rupplin von Keffikon — MEARVK LLC
License: LICENSE.md

A multi-module Java 21 telnet/TCP server platform with NIO masquerade routing, AI inference (Strernary™), encrypted chat, fiduciary services, and Tomcat-deployed web frontends. All modules share a common startup/shutdown orchestration system.

---

## Quick Start

```bash
# First-time install (handles Java, MySQL, Tomcat, firewall, databases, deploy)
sudo bash scripts/web/post-clone.sh

# Or use the Ubuntu Alpha Restricted installer
sudo bash scripts/install-jwstf.sh

# After git pull on an existing server
bash scripts/compile-all-modules.sh
bash scripts/start-all.sh

# Deploy all module frontends
bash deploy-all-modules.sh

# Verify
bash scripts/status.sh
```

---

## Module Registry

### Core Servers (always started by Main.java)

| Module | Port | Class | Purpose |
|--------|------|-------|---------|
| NitroWebExpress | 49152 | `Main` | Main entry point, telnet proxy |
| AesCompliant | 5512 | `source.AesCompliant` | AES-256 encryption server |
| RsaCompliant | 7743 | `source.RsaCompliant` | RSA-2048/4096 encryption server |
| DsaCompliant | 7744 | `source.DsaCompliant` | DSA encryption server |
| BitcoinCompliant | 6682 | `source.BitcoinCompliant` | Bitcoin wallet/transaction server |
| ConnectionStatus | 49155 | `source.ConnectionStatusServer` | Active connection tracker |
| AsciiCreator | 49177 | `source.ASCIICreatorServer` | ASCII art generator |
| ModuleInstallation | 49166 | `source.ModuleInstallationService` | Remote module install/unload |
| ModuleLoaderDaemon | 49188 | `ModuleLoaderDaemon` | Standalone OS-installable daemon |
| Communicator | 49199 | `source.communicator.Communicator` | Encrypted 1-hour chat (DH/ECDH) |
| BinaryHttp | 49144 | `source.BinaryHttpServer` | Binary-to-HTTP-link server |
| Antivirus | — | `source.AntivirusScanner` | ClamAV daily scan |
| Strernary | 20000 | `strernary.StrernaryServer` | AI inference (DJL/PyTorch) |
| StrernaryDirectory | 2000 | `strernary.StrernaryDirectoryServer` | Port directory/menu server |
| NioMasquerade | — | `strernary.NioMasqueradeEngine` | NIO routing layer (127.0.0.1–17) |
| BrarnerAlete | — | `source-code.Main` | HTTP comm with Brarner.M.Alete repo |

### Signal Servers (international TCP endpoints)

| Module | Port | Purpose |
|--------|------|---------|
| JapanSignal | 49201 | Japan signal processing |
| RussiaSignal | 49202 | Russia signal processing |
| MexicoSignal | 49203 | Mexico signal processing |
| GreeceInternational | 49204 | Greece international signal |
| CalendarD44 | 49200 | Calendar / scheduling |

### Submodules (in `modules/`)

| Module | Directory | Port | Context | Backend Class | Purpose |
|--------|-----------|------|---------|---------------|---------|
| CaliforniaFBI | `modules/fbi` | 49210 | `/california-fbi` | `source.CaliforniaFBIServer` | FBI crime reporting, AI categorization, tips.fbi.gov |
| CaliforniaCIA | `modules/cia` | 49211 | `/california-cia` | `source.CaliforniaCIAServer` | CIA intelligence reporting, FOIA, cia.gov |
| CaliforniaNSA | `modules/nsa` | 49212 | `/california-nsa` | `source.CaliforniaNSAServer` | NSA cybersecurity, CISA vulnerability disclosure |
| DukeUniversity | `modules/duke` | 49213 | `/california-duke` | `source.DukeUniversityServer` | Duke University college interface, academic queries |
| StanfordLibrary | `modules/library` | 49214 | `/library` | `source.StanfordLibraryServer` | Stanford Library catalog, resource requests |
| Vietnam | `modules/vietnam` | 49215 | `/vietnam` | `source.VietnamServer` | Saving American Names and graces. |
| Emeter | `modules/emeter` | 49216 | `/emeter` | `source.EmeterServer` | E-Meter instruction, calibration, readings |
| SpectrumTandem | `modules/spectrum-tandem` | 49222 | `/spectrum-tandem` | `source.SpectrumTandemServer` | Dolyene spectrum of int discipline, word bank, county precedent |
| TandemEquals | `modules/tandem-equals` | 49223 | `/tandem-equals` | `source.TandemEqualsServer` | Human intellect modulator simplex, 4-layer control curve |
| Chat | `modules/chat` | 49230 | `/chat` | `source.ChatServer` | Encrypted chat, DH-2048/RSA-2048, federation, file/voice, admin |
| UNCW | `modules/uncw` | 49231 | `/uncw` | `source.UNCWServer` | UNCW Wilmington CS club, colleges, chancellor, files, messaging |
| ArmorerSteve | `modules/armorer` | 49235 | `/armorer` | `source.ArmorerSteveServer` | TCP Q&A interface, knowledge base, C/Java hybrid |
| Fiduciary | `modules/fiduciary` | 49240 | `/fiduciary` | `source.FiduciaryServicesServer` | ACH transfer service, fiduciary outbound connector, C/Java hybrid |
| GrayPortRegistry | `modules/gray` | 9999 | `/gray-registry` | `modules.gray.source.GrayPortRegistryServer` | Port registry (30M ports/block), Bitcoin/Dash payment, AI-gated |
| Gray85Crème | `modules/gray.a85` | 10085 | `/gray85-registry` | `modules.gray.a85.source.Gray85PortRegistryServer` | Crème port registry (85% open, 15% locked at $1000 USD) |
| AE6E66 | `modules/AE6E66` | — | `/ae6e66` | `source.AE6E66Main` | UK Parliament contact module, DKIM email |
| Green.Durham.Grass.and.Herb | `modules/Green.Durham.Grass.and.Herb` | 20000 | `/gdgh` | `listeners.BaseListener` | Labor/ethical/moral concerns, NC labor laws |
| Futures (DemocraticAI) | `modules/red/Futures` | 5000 | `/futures` | `ai.server.DemocraticAIServer` | Democratic AI futures, tax defense pipeline |
| Defined | `modules/Defined` | 49220 | `/defined` | `modules.Defined.source.ai.server.DefinedAIServer` | Dark Gray moral surveillance, 29 categories, NTSB, 12 protocol handlers |
| Bitcoin | `modules/bitcoin` | — | `/bitcoin` | (webapp only) | Bitcoin wallet webapp frontend |
| Dictionary | `modules/dictionary` | — | `/dictionary` | (DB-only) | Dictionary lookup, MySQL `nwe_dictionary` |
| Calendar | `modules/calendar` | — | `/calendar` | (webapp only) | Calendar and scheduling webapp |
| Analytics | `modules/analytics` | — | `/analytics` | (DB-only) | Passive analytics tracking via JSP includes |
| Black Belt | `modules/black-belt` | — | `/blackbelt` | (webapp only) | Black belt rank module |
| Languages | `modules/languages` | — | `/languages` | (webapp only) | Language pack management |
| Daemon | `modules/daemon` | 49188 | — | `ModuleLoaderDaemon` | Standalone module loader service |
| Brarner.M.Alete | `modules/black/presidential/Brarner.M.Alete` | 49152 | `/brarner.m.alete` | `source-code.Main` | Presidential species/postal/art/science |

---

## Script Reference

### Orchestration (run from project root)

| Script | Purpose |
|--------|---------|
| `scripts/start-all.sh` | Full startup: MySQL → Backends → Frontends |
| `scripts/shutdown-all.sh` | Full shutdown: Frontends → Backends → MySQL |
| `scripts/start-backends.sh` | Start all backend TCP servers (per-module) |
| `scripts/shutdown-backends.sh` | Stop all backend TCP servers |
| `scripts/start-frontends.sh` | Deploy all webapps to Tomcat |
| `scripts/shutdown-frontends.sh` | Undeploy all webapps |
| `scripts/start-mysql.sh` | Start MySQL |
| `scripts/shutdown-mysql.sh` | Stop MySQL |
| `scripts/startup.sh` | Start Main.java directly (G1GC, 4GB heap) |
| `scripts/start-backend-modules.sh` | Start Main.java + verify all 19 ports |
| `scripts/status.sh` | Report status of all services |
| `scripts/compile-all-modules.sh` | Compile all Java sources → `out/` |
| `scripts/build-jar.sh` | Build fat JAR (`nwe.jar`) |
| `scripts/test-local.sh` | Full test suite (TCP, HTTP, XML, integrity) |
| `scripts/install-jwstf.sh` | Install NWE from Ubuntu Alpha Restricted OS |
| `deploy-all-modules.sh` | Deploy all module frontends to Tomcat |

### Deployment

| Script | Purpose |
|--------|---------|
| `scripts/web/post-clone.sh` | First-time server setup (Java, MySQL, Tomcat, firewall, databases, deploy) |
| `scripts/web/deploy-all.sh` | Deploy all enabled modules from `web-deploy-config.xml` |
| `scripts/web/deploy-missing.sh` | Re-deploy modules returning HTTP 404 |
| `scripts/ufw-allow-all.sh` | Open all NWE ports in UFW firewall |

### Mail (Postfix + Dovecot)

| Script | Purpose |
|--------|---------|
| `scripts/mail/postfix/install_postfix.sh` | Install and configure Postfix MTA |
| `scripts/mail/postfix/configure-mail.sh` | Full mail system configuration |
| `scripts/mail/postfix/mail-config.xml` | Mail configuration (shared with Dovecot) |
| `scripts/mail/dovecot/install_dovecot.sh` | Install and configure Dovecot IMAP/POP3 |

### Per-Module (run from `modules/<name>/`)

| Script | Purpose |
|--------|---------|
| `start-backend.sh` | Start the module's TCP backend server |
| `shutdown-backend.sh` | Stop the module's TCP backend server |
| `start-frontend.sh` | Deploy webapp to Tomcat |
| `shutdown-frontend.sh` | Undeploy webapp from Tomcat |
| `start.sh` | Legacy: deploy + start Tomcat (used by `start-frontends.sh`) |
| `shutdown.sh` | Legacy: undeploy (`--stop-tomcat` to also stop Tomcat) |

---

## Configuration

| File | Purpose |
|------|---------|
| `configuration/nwe-config.xml` | Master config: ports, admin, servers, scheduling |
| `configuration/masquerade-modules.xml` | NIO masquerade module registry + auto-discover |
| `configuration/print-method.xml` | Output formatting, capitalization, color, trademarks |
| `configuration/nio-masquerade-config.xml` | NIO layer enable/disable and IP bindings |
| `configuration/protocol-handlers.xml` | Telnet command handler registry |
| `configuration/port-2000-directory-config.xml` | Directory server routing config |
| `scripts/web/web-deploy-config.xml` | Tomcat deploy targets, cron schedules |

---

## Communicator™ — Encrypted Chat (Port 49199)

Persistent 1-hour telnet chat server with end-to-end encryption negotiation.

**Cipher Options:**

| # | Cipher | Key Size | Notes |
|---|--------|----------|-------|
| 1 | AES-256-GCM | 256-bit | Default. Authenticated encryption. |
| 2 | RSA-2048 | 2048-bit | DH derives symmetric key, RSA for signing. |
| 3 | RSA-4096 | 4096-bit | Higher security RSA variant. |
| 4 | Twofish-256 | 256-bit | BouncyCastle; falls back to AES-256-CBC. |
| 5 | ECC-secp256r1 | 256-bit | ECDH key exchange + AES-GCM. |
| 6 | ChaCha20-Poly1305 | 256-bit | Modern stream cipher with authentication. |

**Key Exchange:** DH-2048 (RFC 3526 Group 14) for ciphers 1–4,6. ECDH (secp256r1) for cipher 5.

```
telnet localhost 49199
identify <nationalId>
encrypt 1                        ← initiate AES-256-GCM via DH
encrypt accept <your_pubkey_hex> ← complete key exchange
encrypt off                      ← disable encryption
profile cipher 6                 ← save ChaCha20 as default
```

---

## TandemEquals™ — Human Intellect Modulator (Port 49223)

Four-layer simplex control curve system for perception → cognition → modulation → expression.

**TCP Protocol:**

```
telnet localhost 49223
PERCEPTION          — list all signals
COGNITION           — list all patterns
MODULATION          — list all modulators
EXPRESSION          — list all outputs
CURVE               — list control curves
EVALUATE|<id>       — evaluate full simplex path
STATUS              — table counts
QUIT                — disconnect
```

**Database:** `nwe_tandem_equals` — 6 tables: perception, cognition, modulation, expression, control_curve, intellect_log.

---

## Fiduciary™ — ACH Transfer Service (Port 49240)

TCP server for fiduciary outbound connections and ACH transfer processing. Hybrid C/Java implementation with native `fiduciary.c` and `ach_transfer.c` compiled via Makefile alongside Java `FiduciaryServicesServer` and `FiduciaryOutboundConnector`.

**Database:** `nwe_fiduciary`

**Source:** `modules/fiduciary/source/` — Java server + C native ACH engine.

---

## ArmorerSteve™ — Knowledge Q&A (Port 49235)

TCP Q&A interface with a fulltext-searchable knowledge base. Hybrid C/Java implementation with native `armorer.c` compiled via Makefile alongside `ArmorerSteveServer.java`.

**Database:** `nwe_armorer` — knowledge_base table with fulltext indexing.

---

## Integrity System

Post-install SHA-256 file verification. Non-blocking — program continues regardless of findings.

**Schedule:** Every 2 days at 06:00 (`0 6 */2 * *`)

| File | Purpose |
|------|---------|
| `integrity/post-install-integrity-check.sh` | Main integrity scan (SHA-256 + MD5) |
| `cron/integrity-check.sh` | Cron wrapper for periodic runs |
| `integrity/integrity-schema.sql` | MySQL schema for `nwe_integrity` database |

**Behavior:**
1. Self-integrity check first
2. Full SHA-256 + MD5 scan of all git-tracked files
3. On corruption → auto-restore from GitHub
4. On update → preserve original digests in `integrity/history/`
5. Concerns logged to `integrity/concerns/` (non-blocking, append-only)

**Database:** `nwe_integrity` — No DELETE on any table. No UPDATE on history or concerns.

---

## Directory Layout

```
Java.Web.Server.Telnet.Front.Java.21/
├── source/                    Core Java source (Main, servers, strernary, communicator)
├── modules/
│   ├── fbi/                   CaliforniaFBI (port 49210)
│   ├── cia/                   CaliforniaCIA (port 49211)
│   ├── nsa/                   CaliforniaNSA (port 49212)
│   ├── duke/                  DukeUniversity (port 49213)
│   ├── library/               StanfordLibrary (port 49214)
│   ├── vietnam/               Vietnam (port 49215)
│   ├── emeter/                Emeter (port 49216)
│   ├── spectrum-tandem/       SpectrumTandem (port 49222)
│   ├── tandem-equals/         TandemEquals (port 49223)
│   ├── chat/                  NWE Chat (port 49230)
│   ├── uncw/                  UNCW Wilmington (port 49231)
│   ├── armorer/               ArmorerSteve (port 49235)
│   ├── fiduciary/             Fiduciary (port 49240)
│   ├── gray/                  GrayPortRegistry (port 9999)
│   ├── gray.a85/              Gray85Crème (port 10085)
│   ├── AE6E66/                UK Parliament contact
│   ├── Green.Durham.Grass.and.Herb/   Labor/ethics (port 20000)
│   ├── red/Futures/           Democratic AI (port 5000)
│   ├── Defined/               Dark Gray moral surveillance (port 49220)
│   ├── bitcoin/               Bitcoin wallet frontend
│   ├── dictionary/            Dictionary (DB-only)
│   ├── calendar/              Calendar (webapp)
│   ├── analytics/             Analytics (DB-only, passive)
│   ├── black-belt/            Black Belt (webapp only)
│   ├── languages/             Language packs (webapp only)
│   ├── daemon/                ModuleLoaderDaemon (port 49188)
│   └── black/presidential/    Brarner.M.Alete
├── configuration/             XML config files
├── scripts/                   Orchestration, deploy, test scripts
│   └── mail/                  Postfix + Dovecot mail system
├── jars/                      Dependencies (MySQL connector, Lanterna, DJL)
├── out/                       Compiled .class files
├── logging/                   NWE main logs
└── data/                      PID files, runtime data
```

---

## Ports Summary

| Range | Services |
|-------|----------|
| 2000 | StrernaryDirectory |
| 5000 | Futures (DemocraticAI) |
| 5512 | AES encryption |
| 6682 | Bitcoin |
| 7743–7744 | RSA, DSA |
| 8080 | Tomcat (all web frontends) |
| 9999 | Gray Port Registry |
| 10085 | Gray85 Crème Registry |
| 20000 | Strernary AI inference |
| 49111–49216 | NWE core + signal + modules |
| 49220–49223 | Defined, SpectrumTandem, TandemEquals |
| 49230–49231 | NWE Chat, UNCW |
| 49235 | ArmorerSteve (knowledge Q&A) |
| 49240 | Fiduciary (ACH transfer) |

**Open all ports:** `sudo bash scripts/ufw-allow-all.sh`

---

## Ubuntu Alpha Restricted Integration

This project is bundled as userland in the [Ubuntu.Determinant.Alpha.Restricted](https://github.com/mearvk/Ubuntu.Determinant.Alpha.Restricted) distribution at `userland/java-web-server/`. The OS also provides native C tools:

| Tool | Location (in Ubuntu repo) | Purpose |
|------|---------------------------|---------|
| `fiduciary.c` | `tools/fiduciary/` | Native ACH transfer engine |
| `ach_transfer.c` | `tools/fiduciary/` | ACH transfer C implementation |
| `armorer.c` | `tools/armorer/` | Native armorer knowledge engine |
| `configure-mail.sh` | `tools/postfix/` | Full Postfix/Dovecot mail configuration |
| `install_postfix.sh` | `tools/postfix/` | Postfix MTA installer |
| `install_dovecot.sh` | `tools/dovecot/` | Dovecot IMAP/POP3 installer |

These native sources are also kept locally in the corresponding `modules/*/source/` directories.

---

## Contact

- GitHub: https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions
- Email: mearvk@mearvk.us | mearvk@outlook.com
- Phone: 1.919.923.4239 (USA)
