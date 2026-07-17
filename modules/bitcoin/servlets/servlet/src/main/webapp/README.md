# Bitcoin™ — NitroWebExpress™ Wallet & Transaction Module

**Port:** 6682
**Context:** /bitcoin
**Backend Class:** source.BitcoinCompliant
**Theme:** Warm Amber/Gold (₿ orange)
**Installer Tech ID:** Max Rupplin

## Features

- Wallet management (browse, select, balance check)
- Transaction indexing and history
- Trading interface via bitcoind RPC (TraderModule)
- Multi-timezone support (10 timezones: NYC, LA, Tokyo, Dakar, Denver, etc.)
- AI market analysis via Strernary™ (port 20000)
- Message ordering for sequenced blockchain communication

## Protocol (Port 6682)

```
telnet localhost 6682
LIST                    — List wallets
SELECT|wallet_id        — Select a wallet
BALANCE                 — Check balance
HISTORY                 — Transaction history
SEND|address|amount     — Send BTC
RECEIVE                 — Generate receive address
TRADE|BUY/SELL|amount   — Execute trade
STATUS                  — Server status
QUIT                    — Disconnect
```

## Wallet Directories

Wallets indexed from: `/bitcoin/24/` through `/bitcoin/30/`

## Contact

MEARVK LLC — mearvk@mearvk.us
