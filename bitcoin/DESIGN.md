# Bitcoin Design

**Repository:** Java.Web.Server.Telnet.Front.Java.21  
**Area:** Bitcoin / BitcoinCompliant / BitcoinWalletIndexer / TraderModule  
**Review Date:** 2026-09-16

## Design Goals

1. **Correct** — wallet balances come from Bitcoin Core, not file size or filenames.
2. **Safe** — destructive wallet operations require explicit operator control.
3. **Private** — wallet files and credentials are not unnecessarily copied into databases or logs.
4. **Auditable** — state-changing operations have durable records.
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

The old `100 BTC per 2 MB` calculation is removed from the design.

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

### 5. Database model

The current `bitcoin_wallets_v24` through `bitcoin_wallets_v30` tables are legacy-compatible structures. The next migration should separate wallet artifact metadata, authenticated wallet balances, trade records, and session state.

This prevents an artifact index from being mistaken for financial state.

### 6. Wallet blob storage

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

### 7. Idempotent indexing

The indexer should eventually use a unique key such as `(version, canonical_path, sha256)` and upsert/deduplication semantics.

Repeated indexing should not create unlimited duplicate rows.

### 8. RPC isolation

Only the Bitcoin service should need access to the Bitcoin Core RPC interface. The web frontend should communicate with the service layer rather than receiving arbitrary command execution capability.

Allowed RPC commands should be explicitly allowlisted.

### 9. Transaction lifecycle

```text
REQUESTED -> VALIDATED -> AUTHORIZED -> SUBMITTED -> ACCEPTED -> CONFIRMED
```

A returned string from `bitcoin-cli` should not by itself be interpreted as proof of confirmation.

## Next Improvements

### Phase A — Immediate
- Add deterministic wallet-summary tests.
- Add RPC connectivity/health checks.
- Add command allowlisting.
- Add transaction amount/address validation.
- Add structured transaction result objects.
- Remove remaining legacy credential/configuration references.

### Phase B — Data model
- Introduce normalized wallet artifact/balance/trade tables.
- Add unique constraints and indexes.
- Migrate away from `wallet_blob`.
- Store balances in satoshis.
- Store fiat valuation with explicit source/time.

### Phase C — Verification
- Verify Bitcoin Core release checksums and signatures.
- Record binary version and verification date.
- Verify configuration before starting the node.
- Add startup self-test for RPC network and wallet selection.

### Phase D — Testing
Test invalid addresses, invalid amounts, excessive precision, insufficient balance, unavailable RPC, wrong network, unloaded wallets, duplicate indexing, changed/corrupted artifacts, transaction rejection, unconfirmed transactions, and service restart during an operation.

## Current Design State

**Architecture:** Great  
**Security posture:** Better after credential/removal hardening  
**Financial correctness:** Better after removing file-size valuation  
**Data model:** Better, with normalization still required  
**Operational safety:** Great direction; destructive operations remain intentionally restricted  
**Performance:** Not benchmarked  
**Production readiness:** Requires the Phase A–D verification work