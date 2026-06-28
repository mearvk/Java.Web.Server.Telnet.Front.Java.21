# AE6E66™ — House of Lords + House of Commons Contact Module

**Version:** 1.2  
**Author:** Max Rupplin — MEARVK LLC  
**Trust:** 9.5/10  
**Color:** Emerald Green (`\033[38;5;35m`) — Royals

## Structure

```
modules/AE6E66/
├── configuration/
│   ├── ae6e66-config.xml          # Module config (URLs, SMTP, domain, crawl state)
│   ├── .last-crawl                # Date of last successful MPUK crawl
│   └── .db-credentials           # MySQL credentials (chmod 600, gitignored)
├── source/
│   ├── AE6E66Main.java            # Main: crawl 0–999, portraits, contacts, distribute
│   └── EmailDistributor.java      # SMTP distributor — validated, dot-stuffed, timeout-safe
├── scripts/
│   ├── install-postfix-dovecot.sh # Postfix install (TLS 1.2+, relay-restricted)
│   ├── configure-local-server.sh  # Static IP config (HELO validation, header cleanup)
│   ├── setup-dkim-lauradei.sh     # Full DKIM/SPF/DMARC (Unix socket, quarantine policy)
│   └── setup-mysql.sh            # MySQL: nwe_ae6e66 DB, minimal-privilege user
├── marrister/                     # Stationary — draft messages here (*.txt)
├── personal/                      # Outlook/Exchange importable CSV for Lords/Ministers
│   └── lords-ministers-outlook.csv
├── portraits/                     # Portraits by ministry subfolder
│   └── {MinistryName}/{memberId}.jpg
├── sent/                          # Archived sent messages by date
│   └── {YYYY-MM-DD}/
│       ├── message.txt
│       ├── message.txt.sha256
│       ├── message.txt.success.log
│       └── message.txt.failure.log
├── contacts.csv                   # Full contacts (HOL + HOC sections)
├── AE6E66.RDRS                    # Registry Descriptor Record Sheet
└── README.md                      # This file
```

## Security

| Layer | Control |
|-------|---------|
| TLS | Enforced TLS 1.2+ for all outbound SMTP |
| DKIM | 2048-bit key, Unix socket milter (no inet exposure) |
| SPF | `-all` policy (hard fail for unauthorized senders) |
| DMARC | `p=quarantine` with aggregate reports |
| Relay | `reject_unauth_destination` — no open relay |
| HELO | Required, validated (reject invalid/non-FQDN) |
| Headers | Internal IPs stripped via regexp header_checks |
| Email Validation | RFC 5321 subset, 254-char max, header injection blocked |
| Dot-stuffing | RFC 5321 compliant body encoding |
| MySQL | Minimal-privilege user (SELECT/INSERT/UPDATE only) |
| Credentials | `.db-credentials` chmod 600, gitignored |
| Key Permissions | DKIM private key: 600, keys dir: 700 |
| Socket Timeout | 30s on SMTP connections |

## Crawl Behavior

- Scans member IDs 0–999 on `members.parliament.uk/member/XXX/contact`
- Hits `/member/XXX/career` for career data
- Downloads portraits to `portraits/{Ministry}/`
- Auto-detects HOL vs HOC from page content keywords
- Scrapes HOC Enquiries Service for `@parliament.uk` contacts
- **Skip logic:** If `.last-crawl` < 30 days old, crawl skipped. Delete file to force re-crawl.

## MySQL Database (nwe_ae6e66)

| Table | Purpose |
|-------|---------|
| `contacts` | Crawled member data (indexed by source, ministry) |
| `sent_log` | Email delivery audit trail (recipient, SHA-256, status) |
| `crawl_history` | Crawl run metadata (counts, duration) |

**Setup:** `sudo bash modules/AE6E66/scripts/setup-mysql.sh`

## Email Distribution

1. Draft a `.txt` message in `marrister/`
2. Run the module
3. Each recipient gets the message via local Postfix (DKIM-signed, TLS)
4. Success/failure counts logged to `sent/{date}/` and `sent_log` table

### Mail Server

| Property | Value |
|----------|-------|
| Server ID | `mail.lauradei.us` |
| Static IP | `45.32.31.139` |
| Domain | `lauradei.us` |
| From | `contact@lauradei.us` |
| DKIM Selector | `ae6e66` (2048-bit) |
| Target | Japanese VPS |
| Rate Limit | 2s/destination, 2 concurrent |

### Setup Scripts

| Script | OS | Purpose |
|--------|----|---------|
| `install-postfix-dovecot.sh` | Linux | Postfix install (TLS 1.2+, relay-restricted) |
| `install-postfix-macos.sh` | macOS | Built-in Postfix config + Homebrew opendkim |
| `install-mail-windows.ps1` | Windows | hMailServer + stunnel TLS + send-mail helper |
| `configure-local-server.sh` | Linux | Static IP, HELO validation, header cleanup |
| `configure-local-server-macos.sh` | macOS | Static IP via ipconfig, launchd Postfix |
| `configure-local-server-windows.ps1` | Windows | Firewall rules, server config generation |
| `setup-dkim-lauradei.sh` | Linux | Full DKIM/SPF/DMARC (Unix socket signing) |
| `setup-mysql.sh` | Linux | Database + tables + minimal-privilege user |
| `setup-mysql-macos.sh` | macOS | Homebrew MySQL, same schema |
| `setup-mysql-windows.ps1` | Windows | MySQL 8.x, ACL-restricted credentials |

## Usage

### Linux
```bash
sudo bash modules/AE6E66/scripts/setup-dkim-lauradei.sh
sudo bash modules/AE6E66/scripts/setup-mysql.sh
javac modules/AE6E66/source/*.java
java -cp modules/AE6E66/source source.AE6E66Main
```

### macOS
```bash
bash modules/AE6E66/scripts/install-postfix-macos.sh
bash modules/AE6E66/scripts/setup-mysql-macos.sh
javac modules/AE6E66/source/*.java
java -cp modules/AE6E66/source source.AE6E66Main
```

### Windows (PowerShell as Administrator)
```powershell
.\modules\AE6E66\scripts\install-mail-windows.ps1
.\modules\AE6E66\scripts\setup-mysql-windows.ps1
javac modules\AE6E66\source\*.java
java -cp modules\AE6E66\source source.AE6E66Main
```

### Force Re-crawl (all platforms)
```bash
rm modules/AE6E66/configuration/.last-crawl
```

## Cron

- Job: `AE6E66-Crawl`
- Schedule: `0 3 1 * *` (monthly, 1st, 03:00)
- Noble Registry: registered
- Integrity check: every 2 days

## Integrity

- SHA-256 digests in `integrity/digest.db` and MySQL `nwe_integrity`
- Auto-restore from trusted GitHub commit on corruption
- Originals preserved in `integrity/history/`
- Tech ID: Gifted Install Tech ID (non-blocking)

## Print

All output via CommonRails in Emerald Green — designates Royals.
