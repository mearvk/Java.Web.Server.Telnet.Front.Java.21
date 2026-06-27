# Security Policy

**Owner:** Max Rupplin — MEARVK LLC
**Phone:** 1.919.923.4239 (USA)
**Headquarters:** 555 South Mangum St, Durham, NC 27701
**Contact:** mearvk@mearvk.us | mearvk@outlook.com

---

## Supported Versions

| Edition | Version | Supported |
|---------|---------|-----------|
| Personal Executive | 1.x | ✅ |
| National | 1.x | ✅ |
| International | 1.x | ✅ |
| Free | 1.x | ✅ |

---

## Authorization & Key Verification

All programs verify operational authorization via `psychiatry/secrets/public.key` on the central GitHub repository.

- **public.key present on GitHub** → Software authorized to operate
- **public.key removed from GitHub** → All installations revoked
- **secret.key** → NEVER pushed; retained locally by Owner only

---

## Programs & Security Scope

### Core

| Program | Ports | Security Notes |
|---------|-------|----------------|
| NitroWebExpress™ | 49152 | Main server. public.key boot verification. |
| NIO Masquerade Layer | 127.0.0.1–17 | NIO selector, local IP bindings only. |
| NWE Key Listener | 80 | Byte-for-byte public.key comparison. 30-min timeout. |
| NWE Module Installer | 8888 | JAR signature validation (PK magic + SHA-256). |

### Encryption

| Program | Ports | Security Notes |
|---------|-------|----------------|
| AesCompliant | 5512 | AES encryption module. Key material in memory only. |
| RsaCompliant | 7743 | RSA keypair. Private keys never serialized to disk. |
| DsaCompliant | 7744 | DSA signing. |
| BitcoinCompliant | 6682 | Wallet indexer. Trade session state isolated. |
| NationalFinanceID | 49152 | Keypair generator + profile cache. NationalID gated. |

### Inference & AI

| Program | Ports | Security Notes |
|---------|-------|----------------|
| Strernary™ | 20000 | DJL/PyTorch inference. No outbound data exfil. |
| Strernary™ Directory | 2000 | public.key verification for Rank 4 registration. |
| AIProctorModule™ | 49111 | NationalID session verification. |
| CityAnalysis™ | — | IQ-gated (180+). Belt requirement (Green/Brown). |

### International Signal Servers

| Program | Ports | Security Notes |
|---------|-------|----------------|
| JapanSignalServer™ | 49201 | Outbound fetch only. No inbound data acceptance. |
| RussiaSignalServer™ | 49202 | Same isolation model. |
| MexicoSignalServer™ | 49203 | Same isolation model. |
| GreeceInternationalSignalServer™ | 49204 | Same isolation model. |

### Modules/Black (Trusted 9.5+/10)

| Program | Ports | Security Notes |
|---------|-------|----------------|
| Futures™ | 5000 | Secure random wait. DJL inference. RSA-2048+/DH-2048. SHA-256 integrity (16 files). Masquerade-aware. |
| Green.Durham.Grass.and.Herb™ | 2000, 20000, 40002–49152 | JWSTFJ21 masquerade-integrated. NationalID gate on port 20000. GeoLite2 geo-resolution. |
| Brarner.M.Alete™ | 49152 | Maven multi-module. Servlet website. NC postal signal processing (40+ cities). SSA/TN signal nodes. |

**Module documentation:**
- `modules/black/red/Futures/README.md`
- `modules/black/presidential/Green.Durham.Grass.and.Herb/README.md`
- `modules/AE6E66/README.md`

### Port Registries

| Program | Ports | Security Notes |
|---------|-------|----------------|
| GrayPortRegistry™ | 9999 | AI binary gate per port binding. Bitcoin/Dashcoin payment verification. |
| Gray85 Crème Registry | 10085 | 15% Crème-locked ports ($1000 unlock). Planetary auditor control. |

### AE6E66 (House of Lords + Commons)

| Program | Ports | Security Notes |
|---------|-------|----------------|
| AE6E66Main | — | Web crawl only (0–999 IDs). No inbound listener. 30-day crawl skip. |
| EmailDistributor | localhost:25 | Local Postfix SMTP. DKIM-signed via mail.lauradei.us. Rate-limited (2s/msg). |

**Mail server:** `mail.lauradei.us` @ `45.32.31.139` — Postfix + Dovecot + OpenDKIM. Loopback submission only.
**Documentation:** `modules/AE6E66/README.md`, `modules/AE6E66/AE6E66.RDRS`

---

## Module Documentation Index

| Module | Path | .md |
|--------|------|-----|
| Futures™ | `modules/black/red/Futures/` | `README.md` |
| Green.Durham.Grass.and.Herb™ | `modules/black/presidential/Green.Durham.Grass.and.Herb/` | `README.md` |
| Brarner.M.Alete™ | `modules/black/presidential/Brarner.M.Alete/` | — (build.bat) |
| GrayPortRegistry™ | `modules/gray/` | — |
| Gray85 Crème Registry | `modules/gray.a85/` | — |
| AE6E66 | `modules/AE6E66/` | `README.md`, `AE6E66.RDRS` |

---

## Network Security

| Rule | Detail |
|------|--------|
| Outbound ports | 21, 22, 80, 443, 8080, 8888 |
| Inbound | Only managed ports via NIO Masquerade |
| Local bindings | 127.0.0.1–127.0.0.17 (extended mode) |
| TLS | Opportunistic outbound (`smtp_tls_security_level = may`) |
| Rate limiting | 2s destination delay, concurrency limit 2 (SMTP) |

---

## Reporting a Vulnerability

Report security issues directly:

- **Email:** mearvk@mearvk.us
- **Phone:** 1.919.923.4239
- **GitHub Discussions:** https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions

Response within 48 hours. Critical vulnerabilities patched within 24 hours of confirmation.

---

## Key Files (Do Not Expose)

| File | Status |
|------|--------|
| `psychiatry/secrets/secret.key` | NEVER committed. Local owner copy only. |
| `psychiatry/secrets/public.key` | On GitHub. Removal = revocation. |
| `/etc/opendkim/keys/lauradei.us/ae6e66.private` | DKIM private key. Server-local only. |
| `modules/AE6E66/configuration/.last-crawl` | Non-sensitive. Crawl timestamp. |

---

## Trust Ratings

All modules authored by Max Rupplin rated **9.5+/10**. Masquerade routing enabled globally.
