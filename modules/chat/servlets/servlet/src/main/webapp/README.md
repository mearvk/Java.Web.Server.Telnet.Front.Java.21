# Communicator™ — Encrypted Communication Module

**NitroWebExpress™ Module**
Author: Maximilian Eric Alexander Rupplin von Keffikon — MEARVK LLC
Installer Tech ID: Max Rupplin
Port: 49230
Database: nwe_chat
Context: /chat
Ethics: We conceal God but do not work for Her.

---

## Purpose

Full-featured encrypted chat server with:
- **Account Management** — Register, login, change username, delete account
- **End-to-End Encryption** — DH-2048 (RFC 3526 Group 14) + RSA-2048 + AES-256-GCM
- **Direct Messaging** — Encrypted user↔user communication
- **Broadcast** — Send to all connected users
- **File Transfer** — Send files up to 25MB with E2E encryption
- **Voice Notes** — Microphone recording up to 120s
- **Federation** — Connect to up to 5 external Communicator servers (Max Rupplin design)
- **Rank System** — Concealment 3 at 200+ federated connects, Gold Harvard Certificate at 300+
- **Admin Panel** — User management, ban/unban, logs, IP/Geo tracking
- **Chat Logging** — All messages stored with IPs and timestamps
- **Settings** — Reviewable, settable, revisable in XML and database

---

## Encryption

| Layer | Algorithm | Key Size | Purpose |
|-------|-----------|----------|---------|
| Key Exchange | Diffie-Hellman | 2048-bit | Server↔user session key derivation |
| Public Key | RSA | 2048-bit | User↔user direct message signing/encryption |
| Symmetric | AES-256-GCM | 256-bit | Authenticated bulk data encryption |

DH parameters: RFC 3526 Group 14 (2048-bit MODP).

---

## Federation & Ranks

Users can connect to up to 5 external Communicator™ servers (of Max Rupplin's design) by IP or domain.

| Connects | Rank | Reward |
|----------|------|--------|
| 50+ | CONNECTOR | Federation badge |
| 100+ | FEDERATION VETERAN | Veteran status + priority routing |
| 200+ | CONCEALMENT 3 | ★ Elevated encryption tier |
| 300+ | GOLD HARVARD CERTIFICATE | ★★ Gold Letter of Certificate from Harvard. Kids. |

---

## Protocol (Port 49230)

```
telnet localhost 49230

REGISTER|username|password|email   → Create account
LOGIN|username|password            → Authenticate
ADMIN|password                     → Enable admin mode
MSG|user|text                      → Direct message (encrypted)
BROADCAST|text                     → Send to all
LIST                               → Online users with geo
HISTORY                            → Last 30 messages
ENCRYPT|DH                         → Initiate DH-2048 key exchange
ENCRYPT|RSA                        → Initiate RSA-2048
ENCRYPT_ACCEPT|pubkey              → Complete handshake
ENCRYPT_OFF                        → Disable encryption
FILE|user|name|size|b64            → Send file
VOICE|user|durationMs|b64          → Send voice note
FEDERATE|host[:port]               → Connect to remote server
FEDERATION_STATUS                  → View rank and servers
CHANGE_USERNAME|new                → Change username
DELETE_ACCOUNT                     → Delete account
STATUS                             → Module status
QUIT                               → Disconnect

Admin commands:
ADMIN_USERS                        → List all users
ADMIN_BAN|user                     → Ban user
ADMIN_UNBAN|user                   → Unban user
ADMIN_LOGS                         → Event log
ADMIN_GEO|user                     → User IP/geo
ADMIN_IPS                          → All connected IPs
```

---

## Database Schema (nwe_chat)

- **users** — username, password_hash, salt, email, IPs, geo, admin/ban/delete flags, federation count
- **messages** — sender, receiver, content, type (DM/BROADCAST/FILE/VOICE/SYSTEM), IP, timestamp
- **event_log** — user events (login, register, ban, etc.) with IPs
- **federation_log** — remote server connections per user
- **ranks** — rank awards (CONCEALMENT_3, GOLD_HARVARD_CERTIFICATE)
- **chat_settings** — configurable settings (key/value with updater and timestamp)

---

## Webapp

Deep blue background with rich purple offsets. CD1 button connector in blue for Strernary™/direct port routing.

Pages:
- **index.jsp** — Live chat interface, CD1 connector, file/mic buttons
- **account.jsp** — Register, login, change username, delete account
- **federation.jsp** — Connect to remote servers, rank progression
- **settings.jsp** — Review and revise all settings
- **admin.jsp** — Admin panel (users, ban, geo, logs)
- **status.jsp** — Backend connectivity, protocol reference

---

## Scripts

| Script | Purpose |
|--------|---------|
| `start-backend.sh` | Start TCP backend on port 49230 |
| `shutdown-backend.sh` | Stop TCP backend |
| `start-frontend.sh` | Deploy webapp to Tomcat |
| `shutdown-frontend.sh` | Undeploy webapp |
| `servlets/deploy-local.sh` | Deploy webapp |
| `servlets/setup-db.sh` | Create database and seed settings |

---

## Contact

- GitHub: https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions
- Email: mearvk@mearvk.us | mearvk@outlook.com
