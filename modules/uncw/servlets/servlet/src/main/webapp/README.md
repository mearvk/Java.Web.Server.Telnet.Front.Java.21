# UNCW™ — Wilmington at the Coast of NC

**NitroWebExpress™ Module**
Author: MEARVK LLC | Installer Tech ID: Max Rupplin
Port: 49231 | Database: nwe_uncw | Context: /uncw

---

## Purpose

University of North Carolina Wilmington — Computer Science Club & College Community.
Universal, fun. SeaCoast colors (teal + gold).

## Features

- **User Accounts** — Register with student ID, college, email. Login/profile.
- **Chancellor System** — Current + past Chancellors (up to 2000). Special login. Unlimited messaging. Notes.
- **Chancellor Status Indicators** — Half white/teal squares in nav (10 indicators). Gold = online now.
- **Messaging** — Chancellor unlimited. Users get 10 free messages/month to other users.
- **File Sharing** — Up to 80MB. Stored in DB or user folder (user's choice via FILE_STORAGE command).
- **Audio Awareness** — Server detects audio types (mp3, wav, ogg, flac, aac, m4a, opus). Frontend plays them.
- **National ID** — Set on profile, confirmed by NWE servers. Reminder shown on login.
- **User Profiles** — Viewable by other users. Shows student ID, college, verification status.
- **Chancellor Notes** — Chancellors post notes visible to all.
- **Admin Panel** — Ban/unban, set chancellor status, confirm National IDs.
- **Colleges** — CS, Marine Biology, Education, Business, Arts & Sciences, Health, Engineering.

## Protocol (Port 49231)

```
REGISTER|user|pass|email|studentId|college
LOGIN|user|pass
CHANCELLOR_LOGIN|user|pass
PROFILE / VIEW_PROFILE|user / USERS
MSG|user|text / INBOX
UPLOAD|filename|size|b64 / DOWNLOAD|fileId / SEND_FILE|user|fileId / MY_FILES
FILE_STORAGE|DATABASE or FOLDER
SET_NATIONAL_ID|id / CHECK_NATIONAL_ID
CHANCELLOR_STATUS / CHANCELLOR_NOTES / CHANCELLOR_NOTE|text
ADMIN|pass / ADMIN_USERS / ADMIN_BAN|user / ADMIN_SET_CHANCELLOR|user|true/false / ADMIN_CONFIRM_NID|user
```

## Database (nwe_uncw)

- **users** — accounts, student IDs, colleges, chancellor flags, national IDs, file storage prefs
- **messages** — sender, receiver, content, timestamps (10/month limit for non-chancellors)
- **files** — owner, filename, size, is_audio, storage type (DB or folder), blob or path
- **file_shares** — shared file records between users
- **chancellor_notes** — notes posted by chancellors

## Contact
- GitHub: https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions
