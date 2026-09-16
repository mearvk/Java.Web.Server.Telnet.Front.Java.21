# Bitcoin Security

**Review Date:** 2026-09-16

## Security Principles

- Never commit RPC passwords, private keys, seed phrases, or wallet credentials.
- Prefer Bitcoin Core cookie authentication for local RPC.
- Keep RPC bound to localhost unless a documented, authenticated remote configuration is required.
- Do not expose arbitrary bitcoin-cli command execution through the web UI.
- Allowlist supported RPC operations.
- Validate destination addresses and amounts before submission.
- Record state-changing operations without logging secrets.
- Treat wallet database files as sensitive artifacts.
- Do not infer balances from filenames, file sizes, or arbitrary metadata.
- Verify Bitcoin Core binaries before installation or execution.
- Require explicit authorization and backup procedures for destructive wallet operations.

## Changes Applied 2026-09-16

### RPC credentials

Hard-coded RPC username/password material was removed from `BitcoinBase.java` and the Bitcoin query script. Local authentication now follows Bitcoin Core's cookie-authentication model.

The RPC port is configurable with `BITCOIN_RPC_PORT`.

### Destructive wallet deletion

The legacy filesystem deletion path in `TraderModule` was disabled. The implementation no longer invokes `rm -r` against wallet directories.

### Valuation

The hard-coded $20T/BTC valuation was removed from active wallet-summary behavior. Optional fiat valuation is now operator supplied through `BTC_PRICE_USD`.

### Wallet indexing

Wallet file size is no longer interpreted as BTC balance. The indexer should use authenticated Bitcoin Core RPC for balances.

## Remaining Security Work

1. Replace legacy wallet-blob storage with metadata-only storage.
2. Add authenticated/authorized RPC command allowlisting.
3. Add CSRF protection to state-changing JSP actions.
4. Add session timeout and secure cookie attributes.
5. Add rate limiting for authentication and transaction endpoints.
6. Add audit records containing actor, action, result, timestamp, and transaction ID where applicable.
7. Add checksum/signature verification to Bitcoin Core installation/update workflows.
8. Add automated secret scanning to CI.