# Bitcoin Revisions — 2026-09-16

## Runtime and accounting hardening

The Bitcoin subsystem received the next planned engineering pass.

### Implemented

- Added `BitcoinRpcPolicy.java` as the central RPC and monetary-input policy.
- Added an explicit allowlist for server-exposed Bitcoin Core RPC methods.
- Added wallet-name validation.
- Added exact BTC-to-satoshi conversion using `BigDecimal`.
- Added eight-decimal-place enforcement and positive-amount checks.
- Added Bitcoin address syntax validation before `sendtoaddress`.
- Added validated `BITCOIN_RPC_PORT` handling.
- Reworked `BitcoinBase` process execution around `ProcessBuilder`.
- Added a bounded RPC process timeout.
- Reduced command logging so raw command arguments are not logged.
- Added `BitcoinBalanceObserver` and the `bitcoin_balance_observations` table.
- Balance observations now originate from authenticated Bitcoin Core `getbalance`, not wallet-file size or filename inference.
- Monetary observations are persisted as satoshis.
- Wallet artifact metadata remains separate from monetary observations.
- Added deterministic `BitcoinRpcPolicyTest` regression checks.
- Changed the centralized Bitcoin Core installer to fail closed when SHA-256 verification data is missing or invalid.

## Data model

The Bitcoin data boundary is now explicitly separated into:

1. `bitcoin_wallet_artifacts` — file metadata and integrity information.
2. `bitcoin_balance_observations` — authenticated Bitcoin Core monetary observations.
3. `bitcoin_trade_events_v{N}` — application/session trade events.

A wallet file is not treated as a balance ledger.

## Transaction semantics

`BitcoinBase.send()` validates the destination and amount before requesting `sendtoaddress`. Bitcoin Core remains authoritative for final acceptance. The session command `trade btc <amount>` remains a recording-only operation and does not broadcast a transaction.

## Release provenance

The centralized Bitcoin Core installer now requires a matching SHA-256 entry before extraction or installation. Signature verification is intentionally treated as a separate trust-policy layer because signature validity depends on an operator-established trusted release-key set.

## Verification status

Source-level changes have been committed to `main`. A full repository build, full integration test run, and live Bitcoin Core regtest execution have **not** been claimed by source inspection alone.

## Remaining production verification

- Run the deterministic policy test in CI.
- Run Bitcoin Core in isolated regtest.
- Exercise wallet lifecycle and balance observation end-to-end.
- Verify rejected RPC methods never reach `bitcoin-cli`.
- Review all Bitcoin web state-changing endpoints for authenticated sessions, CSRF protection, authorization, and rate limiting.
- Establish a documented trusted Bitcoin Core release-keyring policy and signature verification workflow.
- Add transaction confirmation-state tracking for any future broadcast workflow.
