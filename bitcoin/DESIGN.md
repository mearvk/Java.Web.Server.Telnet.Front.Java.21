# Bitcoin Design

**Repository:** Java.Web.Server.Telnet.Front.Java.21  
**Area:** Bitcoin / BitcoinCompliant / BitcoinWalletIndexer / TraderModule  
**Review Date:** 2026-09-16

## Design Goals

1. **Correct** — wallet balances come from Bitcoin Core, not file size or filenames.
2. **Safe** — destructive wallet operations require explicit operator control.
3. **Private** — wallet files and credentials are not unnecessarily copied into databases or logs.
4. **Auditable** — state-changing operations have durable, attributable records.
5. **Deterministic** — monetary calculations use fixed-point units such as satoshis.
6. **Verifiable** — downloaded binaries and important wallet artifacts are integrity checked.
7. **Modular** — UI, RPC, indexing, and persistence remain separate concerns.

## Current Architecture

```text
Web UI (/bitcoin)
       |
       v
BitcoinCompliant :6682
       |
       +--> BitcoinBase ----> bitcoin-cli / bitcoind
       +--> TraderModule
       +--> BitcoinWalletSession
       +--> BitcoinWalletIndexer ----> MySQL metadata
```

## Key Corrections

### 1. Wallet size is not wallet balance

A wallet database file contains implementation/state data. Its byte size does not represent BTC held by the wallet.

The indexer must treat:
- filename = metadata
- file size = metadata
- SHA-256 = integrity metadata
- Bitcoin Core RPC balance = authoritative balance

The old file-size-to-BTC calculation is removed from the design.

### 2. No embedded RPC passwords

Bitcoin RPC credentials must not be committed to Java or shell source. The local regtest design now relies on Bitcoin Core's normal cookie authentication path.

The RPC port remains configurable through `BITCOIN_RPC_PORT`.

### 3. No shell deletion of wallets

The previous trader implementation contained a filesystem `rm -r` path for wallet deletion. This has been disabled.

Wallet destruction is a high-impact operation and should be performed only through an explicit, separately reviewed Bitcoin Core lifecycle procedure with verified backup and operator confirmation.

### 4. Monetary representation

Where monetary values are stored or compared:
- Prefer satoshis (`long`) for exact BTC quantities.
- Do not use binary floating point for authoritative balances.
- Use decimal/fixed-point types for fiat display calculations.
- Keep exchange-rate source and timestamp separate from wallet state.

### 5. Wallet session accounting

`BitcoinWalletSession` now treats the `bitcoin_wallets_v24` through `bitcoin_wallets_v30` tables as **wallet metadata** rather than balance ledgers.

The session command `trade btc <amount>` is explicitly a **trade-event recording operation**. It does not broadcast, submit, or imply a blockchain transaction.

Trade amounts are parsed as BTC decimal values with at most eight decimal places and stored as exact satoshis. Optional fiat valuation is supplied through `BTC_PRICE_USD`; when no price is supplied, the event remains unvalued rather than inventing a market price.

Trade events are written to new `bitcoin_trade_events_v{N}` tables so that the old `bitcoin_trades_v{N}` schema cannot silently reinterpret legacy `btc_amount` units.

### 6. Database model

The current `bitcoin_wallets_v24` through `bitcoin_wallets_v30` tables are legacy-compatible metadata structures. The target model separates:

- wallet artifact metadata
- authenticated wallet balance observations
- trade events
- transaction lifecycle state
- session state

This prevents an artifact index from being mistaken for financial state.

### 7. Wallet blob storage

Whole wallet database files should not normally be copied into MySQL. They can contain sensitive wallet material and substantially increase the impact of a database compromise.

Preferred model:
```text
wallet artifact -> controlled filesystem
                  +--> SHA-256
                  +--> size
                  +--> modified time
                  +--> permissions
```

The database should store metadata and references, not unnecessary private wallet contents.

### 8. Idempotent indexing

The indexer should eventually use a unique key such as `(version, canonical_path, sha256)` and upsert/deduplication semantics.

Repeated indexing should not create unlimited duplicate rows.

### 9. RPC isolation

Only the Bitcoin service should need access to the Bitcoin Core RPC interface. The web frontend should communicate with the service layer rather than receiving arbitrary command execution capability.

Allowed RPC commands should be explicitly allowlisted.

### 10. Transaction lifecycle

```text
REQUESTED -> VALIDATED -> AUTHORIZED -> SUBMITTED -> ACCEPTED -> CONFIRMED
```

A returned string from `bitcoin-cli` should not by itself be interpreted as proof of confirmation.

## Code-Level Hardening Applied

- Removed the legacy `btc_value` balance calculation from wallet-session display paths.
- Removed the legacy USD multiplication from trade-event recording.
- Added strict Bitcoin version validation before constructing table names.
- Added prepared statements for wallet-name and trade-event values.
- Added null checks for command input and database availability.
- Added exact eight-decimal BTC parsing using `BigDecimal`.
- Converted BTC amounts to satoshis before persistence.
- Added an explicit `RECORDED` event state.
- Removed the implication that `trade btc` submits a blockchain transaction.
- Kept wallet metadata queries limited to the first 25 records.
- Suppressed database exception details from user-facing Telnet responses.

## Next Improvements

### Phase A — Immediate
- Add deterministic wallet-summary and BTC parsing tests.
- Add RPC connectivity/health checks.
- Add command allowlisting.
- Add transaction address/amount validation when real transaction submission is implemented.
- Add structured transaction result objects.
- Remove remaining legacy credential/configuration references.

### Phase B — Data model
- Introduce normalized wallet artifact/balance/trade tables.
- Add unique constraints and indexes.
- Migrate away from any `wallet_blob` storage.
- Store authoritative balances in satoshis.
- Store fiat valuation with explicit source and timestamp.

### Phase C — Verification
- Verify Bitcoin Core release checksums and signatures.
- Record binary version and verification date.
- Verify configuration before starting the node.
- Add startup self-test for RPC network and wallet selection.

### Phase D — Testing

Test invalid addresses, invalid amounts, excessive precision, insufficient balance, unavailable RPC, wrong network, unloaded wallets, duplicate indexing, changed/corrupted artifacts, transaction rejection, unconfirmed transactions, and service restart during an operation.

## Current Design State

**Architecture:** Great  
**Security posture:** Great direction after credential and destructive-operation hardening  
**Financial correctness:** Great direction after removing file-size valuation and floating-point BTC arithmetic  
**Data model:** Better, with normalization still required  
**Operational safety:** Great direction; destructive operations remain intentionally restricted  
**Performance:** Not benchmarked  
**Production readiness:** Requires the Phase A–D verification work