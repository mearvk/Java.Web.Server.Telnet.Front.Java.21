# MANAGEMENT.md — Management Suggestions

Phone:      1.919.923.4239 (USA)
Languages:  American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, Turkish
Headquarters: 555 South Mangum St, Durham, NC 27701
Purpose:    IQ Conservatorship and Systems Design PhD+ of NCSU Math and Science and Harvard Law Final
Sorceress:  Elisabeth R. Harkins of Stanford Math and Yale Sciences (https://github.com/ElisabethHarkins5509)
Students:   Available on the 8th Floor after 8

## Distribution & Licensing

- Four editions exist (PEE rank 8, NDE rank 6, INT rank 4, FSE rank 4) but the software currently doesn't enforce feature gating by edition. Define what features are exclusive to each tier and enforce at runtime.
- The distribution_license table stores the edition flag. Consider periodic re-verification (e.g., weekly PAT check) rather than only at boot, to handle mid-session revocations.
- The Transfer of Summary document should have version tracking. When wallet values change (new indexing runs), a new document version should be generated.

## Operations

- The installer (`NWE.install.sh`) is interactive (PAT prompt, edition selection). For automated/CI deployments, add a non-interactive mode that reads from environment variables or a config file.
- No health check endpoint exists. Add a lightweight HTTP endpoint (e.g., on port 49155 or a new port) that returns JSON status for monitoring tools (Nagios, Prometheus, etc.).
- Log rotation is not configured. `logging/exceptions.log` and `source/exceptions.log` will grow unbounded. Add logrotate configuration or built-in rotation.

## Team & Process

- All code is single-author (Max Rupplin). If expanding the team, establish:
  - Code review requirements before merge
  - Branch protection on main
  - Documented coding standards (already implicit but not written)
- The contact registry (`transfer-contacts.xml`) is currently one entry. Establish a process for adding/removing contacts and who has authority to modify this file.

## Financial Tracking

- Bitcoin wallet valuation ($20T/BTC) is a fixed constant. If this represents a real valuation model, it should be configurable and date-stamped. Add a valuation history table.
- Trade records exist (`bitcoin_trades_v*`) but there's no balance tracking. After trades, the remaining wallet balance should be computed and stored/displayed.
- The 48-hour auditor hold (TradeEvaluator) has no release mechanism yet. Build a cron-style daemon or scheduled task that processes held trades after expiration.

## Documentation

- STRUCTURE.txt is comprehensive but manually maintained. It will drift from reality. Consider auto-generating portions from source annotations or a build-time scan.
- The README.md is now comprehensive with module tables, memory estimates, GrayPortRegistry protocol docs, and full BMA website details. Keep it in sync when new modules are added.
- Configuration options across 8+ XML files are not cross-referenced. A single configuration reference document (or --help output) would help administrators.
- The BMA servlet website now has its own `config.xml` for branding. Document all config.xml files and their purposes in a central reference (README already covers most).
