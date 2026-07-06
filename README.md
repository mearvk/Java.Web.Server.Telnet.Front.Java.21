


---

## Communicator™ — Encrypted Chat (Port 49199)

Persistent 1-hour telnet chat server with end-to-end encryption negotiation.

**Cipher Options (dropdown):**

| # | Cipher | Key Size | Notes |
|---|--------|----------|-------|
| 1 | AES-256-GCM | 256-bit | Default. Authenticated encryption. |
| 2 | RSA-2048 | 2048-bit | DH derives symmetric key, RSA for signing. |
| 3 | RSA-4096 | 4096-bit | Higher security RSA variant. |
| 4 | Twofish-256 | 256-bit | BouncyCastle; falls back to AES-256-CBC. |
| 5 | ECC-secp256r1 | 256-bit | ECDH key exchange + AES-GCM. |
| 6 | ChaCha20-Poly1305 | 256-bit | Modern stream cipher with authentication. |

**Key Exchange:** DH-2048 (RFC 3526 Group 14) for ciphers 1–4,6. ECDH (secp256r1) for cipher 5.

**Protocol:**

```
telnet localhost 49199
identify <nationalId>
encrypt                          ← show cipher dropdown
encrypt 1                        ← initiate AES-256-GCM via DH
  → server sends DH public key (hex)
encrypt accept <your_pubkey_hex> ← complete key exchange
  → session now encrypted
encrypt off                      ← disable encryption
```

**Profile (persistent settings):**

```
profile                      ← view current settings
profile cipher 6             ← save ChaCha20 as default (auto-suggests on next login)
profile clear                ← clear preference
```

**Source:**
- `source/communicator/Communicator.java` — Chat server
- `source/communicator/CommunicatorCrypto.java` — Cipher negotiation, DH/ECDH, encrypt/decrypt
- Database: `communicator_profiles` table (national_id → preferred_cipher)

---

## Module Startup/Shutdown Scripts

All modules have dedicated scripts at their root for frontend (webapp) and backend (TCP servers).

### Brarner.M.Alete™

| Script | Purpose |
|--------|---------|
| `start.sh` | Build WAR + deploy to Tomcat + start Tomcat |
| `shutdown.sh` | Undeploy from Tomcat (`--stop-tomcat` to also stop Tomcat) |
| `start-backend.sh` | Start TCP servers (Postal, SSA, Art, Legal) |
| `shutdown-backend.sh` | Stop all backend TCP servers |

**Location:** `modules/black/presidential/Brarner.M.Alete/`

### Green.Durham.Grass.and.Herb™

| Script | Purpose |
|--------|---------|
| `start-frontend.sh` | Deploy webapp to Tomcat + start Tomcat |
| `shutdown-frontend.sh` | Undeploy from Tomcat (`--stop-tomcat`) |
| `installation/start.sh` | Start backend TCP server (Appree, listeners) |
| `installation/stop.sh` | Stop backend |

**Location:** `modules/black/presidential/Green.Durham.Grass.and.Herb/`

### Futures™ (Democratic ProFront National 1.0)

| Script | Purpose |
|--------|---------|
| `start-frontend.sh` | Deploy webapp to Tomcat + start Tomcat |
| `shutdown-frontend.sh` | Undeploy from Tomcat (`--stop-tomcat`) |
| `bash/start.sh` | Start AI server on port 5000 |
| `bash/shutdown.sh` | Stop port 5000 server |

**Location:** `modules/black/red/Futures/`

### Black Belt™

| Script | Purpose |
|--------|---------|
| `start.sh` | Deploy webapp to Tomcat + setup MySQL + start Tomcat |
| `shutdown.sh` | Undeploy from Tomcat (`--stop-tomcat`) |

**Location:** `modules/black/belt/`

### Main NWE (all backend modules)

| Script | Purpose |
|--------|---------|
| `scripts/startup.sh` | Start NWE Main (all servers, G1GC, 4GB heap) |
| `scripts/start-backend-modules.sh` | Start NWE + verify all 19 ports |
| `scripts/start-backend-modules.sh --stop` | Stop NWE Main |

---

## Integrity System

Post-install SHA-256 file verification. Non-blocking — program continues running regardless of findings.

**Tech ID:** Gifted Install Tech ID (not MEARVK LLC Installer Tech ID)

**Schedule:** Every 2 days at 06:00 (`0 6 */2 * *`)

**Scripts:**

| File | Purpose |
|------|---------|
| `integrity/post-install-integrity-check.sh` | Main integrity scan (SHA-256 + MD5) |
| `cron/integrity-check.sh` | Cron wrapper for periodic runs |
| `integrity/integrity-schema.sql` | MySQL schema for `nwe_integrity` database |
| `modules/black/red/Futures/bash/integrity.sh` | Futures-specific integrity check |
| `modules/black/presidential/Brarner.M.Alete/install/verify-integrity.sh` | BMA integrity verification |
| `modules/black/presidential/Brarner.M.Alete/install/generate-integrity.sh` | BMA digest generation |

**Behavior:**
1. Self-integrity check first (verifies its own scripts)
2. Full SHA-256 + MD5 scan of all git-tracked files
3. On corruption (same commit, different hash) → auto-restore from GitHub
4. On update (different commit) → preserve original digests in `integrity/history/`
5. Concerns logged to `integrity/concerns/` (non-blocking, append-only)

**Database:** `nwe_integrity` — tables: `honor_oath`, `file_digests`, `file_digests_history`, `integrity_concerns`, `scan_history`

**No DELETE on any table. No UPDATE on history or concerns.**

**Trusted servers:**
- `github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21` (primary)
- `github.com/ElisabethHarkins5509` (secondary)

**Install:**
```bash
mysql < integrity/integrity-schema.sql
bash integrity/post-install-integrity-check.sh
sudo bash cron/install-cron.sh
```
