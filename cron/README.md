# Cron — Noble Registry

Reliable cron services for NitroWebExpress™ — a Noble Mear before Noble Ministries.

## Install

```bash
sudo bash cron/install-cron.sh
```

Installs to `/etc/cron.d/nwe-mearvk`. Logs to `/var/log/nwe/`.

## Schedule

| Job | Schedule | Script | Purpose |
|-----|----------|--------|---------|
| AE6E66-Crawl | `0 3 1 * *` | `cron/install-cron.sh` | Monthly HOL/HOC crawl |
| GitHubPullNewer | `0 4 * * *` | `scripts/github/pull-newer-only.sh` | Daily pull newer files only |
| SignalHealth | `*/15 * * * *` | `cron/signal-health.sh` | Signal server liveness |
| PostfixFlush | `*/30 * * * *` | `/usr/sbin/postqueue -f` | Flush mail queue |
| MySQLBackup | `0 2 * * *` | `cron/mysql-backup.sh` | Daily DB backup (14-day retention) |
| StrernaryLiveness | `*/5 * * * *` | `cron/strernary-liveness.sh` | Strernary™ port 20000 check |
| GrayLeaseCheck | `0 * * * *` | `cron/gray-lease-check.sh` | Port registry lease expiry |
| CryptoVerify | `0 */48 * * *` | `cron/crypto-verify.sh` | Binary integrity (BTC/Dash/LTC/Star) |
| IntegrityCheck | `0 6 */2 * *` | `cron/integrity-check.sh` | SHA-256 file integrity vs GitHub |

## Noble Registry Configuration

In `configuration/nwe-config.xml` under `<noble-registry>`:
- **Enabled:** true (default)
- **Reset interval:** 48 hours (noble 2rways days)
- **Shutdown concern:** Saves brothers' state before termination (`cron/.noble-state`)

## Shutdown Concern

On shutdown (`scripts/bash/Shutdown.sh`), `cron/save-noble-state.sh` runs first:
- Records last-run timestamps for all jobs
- Captures port liveness status
- Saves postfix queue count
- State preserved to `cron/.noble-state`

## Scripts

| Script | Purpose |
|--------|---------|
| `install-cron.sh` | Install all cron jobs to system |
| `signal-health.sh` | Probe signal server ports |
| `strernary-liveness.sh` | Probe Strernary™ port 20000 |
| `mysql-backup.sh` | Backup all NWE databases |
| `gray-lease-check.sh` | Check Gray port registries |
| `crypto-verify.sh` | SHA-256 verify crypto binaries |
| `integrity-check.sh` | File integrity wrapper |
| `save-noble-state.sh` | Shutdown state preservation |
