# Bitcoin Native/Platform Revisions — 2026-09-16

## C implementation

`linux/c/bitcoin/base/BitcoinBase.c` was brought into alignment with the hardened Java Bitcoin boundary.

- Removed RPC password and empty password flags.
- Uses `BITCOIN_RPC_PORT` with a validated default of `2222`.
- Uses Bitcoin Core cookie authentication through `bitcoin-cli` rather than command-line credentials.
- Replaced shell-based `popen()`/`system()` command execution with `fork()`/`execvp()` argument-based execution.
- Added bounded process waiting and forced termination on timeout.
- Keeps stderr/stdout inside the controlled child-process pipe.
- Disabled destructive wallet deletion instead of issuing `rm -r`.
- Keeps wallet creation/load/unload as explicit Bitcoin Core operations.
- Keeps transaction broadcasting disabled in the placeholder `send_local_to_remote` path.

## Windows installer

`scripts/windows/bitcoin/windows.install.bat` was updated to:

- stop generating placeholder `rpcuser` and `rpcpassword` credentials;
- configure local regtest mode;
- bind RPC to `127.0.0.1`;
- use a defined local RPC port;
- perform the Bitcoin Core health check through the same regtest endpoint;
- return a non-zero exit status when the health check fails.

## Remaining platform verification

The native C implementation and Windows script have been source-updated, but a native compiler run and Windows execution are not claimed from source inspection alone. Those environments should be exercised in CI or on their target systems.
