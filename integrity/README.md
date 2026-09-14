# Integrity System

Post-install SHA-256 file integrity verification with auto-restore.

## Gifted Install Tech ID

Operates under **Gifted Install Tech ID** — not MEARVK LLC Installer Tech ID.
Verifies software against trusted GitHub commits. Restores corrupted files automatically.

## How It Works

1. Cron runs every 2 days (`0 6 */2 * *`) via `cron/integrity-check.sh`
2. Self-integrity first — verifies its own scripts
3. Full SHA-256 + MD5 scan of all git-tracked files
4. Compares against stored digest database
5. Corruption (same commit, different hash) → auto-restore from GitHub
6. Update (different commit) → preserve originals in `integrity/history/`
7. Non-blocking — concerns logged, program continues

## Storage Awareness

- Detects MySQL on main drive vs `/mnt/blockstorage` via `scripts/detect-mysql.sh`
- Logs write to `/mnt/blockstorage/nwe/logs/` when mounted (keeps main drive free)
- Fallback: local `logging/` directory

## Files

| File | Purpose |
|------|---------|
| `integrity/post-install-integrity-check.sh` | Main integrity script |
| `integrity/integrity-schema.sql` | MySQL schema (`nwe_integrity`) |
| `cron/integrity-check.sh` | Cron wrapper |
| `scripts/detect-mysql.sh` | MySQL location detection |

## Module-Specific Integrity

| Module | Script | Purpose |
|--------|--------|---------|
| BMA | `install/verify-integrity.sh` | Verify INTEGRITY.manifest |
| BMA | `install/generate-integrity.sh` | Regenerate manifest |
| BMA | `install/test-jdbc.sh` | MySQL location + JDBC + config check |
| Futures | `bash/integrity.sh` | 39-file embedded SHA-256 baseline |

## Database (`nwe_integrity`)

- `honor_oath` — read-only after insert
- `file_digests` — SELECT, INSERT, limited UPDATE
- `file_digests_history` — append-only
- `integrity_concerns` — append-only
- `scan_history` — append-only

**No DELETE. No UPDATE on history/concerns.**

## Trusted Servers

- `github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21` (primary)
- `github.com/ElisabethHarkins5509` (secondary)

## Log Size Presets (nwe-config.xml)

| Preset | Max/file | Rotations | Total (nwe-main.log) |
|--------|---------|-----------|----------------------|
| 1 large | 2 GB | 5 | 10 GB |
| 2 medium | 512 MB | 4 | 2 GB |
| 3 small | 64 MB | 3 | 192 MB |

Block storage enabled by default for logs.

## Install

```bash
mysql < integrity/integrity-schema.sql
bash integrity/post-install-integrity-check.sh
sudo bash cron/install-cron.sh
bash modules/black/presidential/Brarner.M.Alete/install/test-jdbc.sh
```
