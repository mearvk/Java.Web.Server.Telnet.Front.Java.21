# Integrity System

Post-install SHA-256 file integrity verification with auto-restore.

## Gifted Install Tech ID

This system operates under the **Gifted Install Tech ID** designation — not the Max Rupplin MEARVK LLC Installer Tech ID. It verifies software integrity against trusted GitHub commits and restores corrupted files automatically.

## How It Works

1. **Cron runs every 2 days** (`0 6 */2 * *`) via `cron/integrity-check.sh`
2. **Self-integrity first** — verifies its own scripts haven't been tampered with
3. **Full scan** — SHA-256 + MD5 for all git-tracked files
4. **Compare** — checks digests against stored database (same commit = must match)
5. **On corruption** — fetches original from trusted repo, restores, backs up corrupted file
6. **On software update** — preserves previous digests in `integrity/history/`
7. **Non-blocking** — program continues running; concerns logged to `integrity/concerns/`

## Files

| File | Purpose |
|------|---------|
| `post-install-integrity-check.sh` | Main integrity script |
| `integrity-schema.sql` | MySQL schema (`nwe_integrity` database) |
| `digest.db` | Current file digests (auto-generated) |
| `self.sha256` | SHA-256 of integrity scripts themselves |
| `concerns/` | Concern files (timestamped, non-blocking) |
| `history/` | Preserved original digests on update |

## Database (`nwe_integrity`)

| Table | Purpose | Permissions |
|-------|---------|-------------|
| `honor_oath` | Locks integrity system — swears honor to process and country | Read-only |
| `file_digests` | SHA-256/MD5 for all tracked files | SELECT, INSERT, limited UPDATE |
| `file_digests_history` | Preserved originals (append-only) | SELECT, INSERT only |
| `self_integrity` | SHA-256 of integrity scripts | SELECT, INSERT only |
| `integrity_concerns` | Logged concerns (append-only) | SELECT, INSERT only |
| `scan_history` | Scan results and stats | SELECT, INSERT only |

**No DELETE granted on any table. No UPDATE on history or concerns.**

## Trusted Servers

- `github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21` (primary)
- `github.com/ElisabethHarkins5509` (secondary)

## Restore Behavior

- Same commit + different hash = **corruption** → auto-restore from trusted repo
- Different commit + different hash = **update** → preserve original, update digest
- Self-integrity fail → restore integrity scripts first, then continue scan

## Install

```bash
# Create database
mysql < integrity/integrity-schema.sql

# Run first scan (creates digest.db)
bash integrity/post-install-integrity-check.sh

# Install cron (includes integrity check)
sudo bash cron/install-cron.sh
```

## Configuration

Configured in `configuration/nwe-config.xml` under `<integrity>`:
- `enabled`: true
- `restore-on-fail`: true
- `preserve-originals`: true
- `blocking`: false
- `honor-oath-table`: honor_oath
