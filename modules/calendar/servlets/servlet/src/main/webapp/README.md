# CalendarD44™ — NitroWebExpress™

**Port:** 49200
**Context:** /calendar
**Theme:** Fall Colors (rust, gold, amber)
**Backend Class:** calendar.d44.CalendarD44Server
**Database:** nwe_calendar_d44
**Installer Tech ID:** Max Rupplin

## Features

- Date routing and time-based message delivery
- Module interaction logging with timestamps
- Scheduled message delivery (Communicator integration)
- Task scheduling for module-level operations
- Multi-timezone delivery aligned to recipient locale
- D44 protocol for cross-module scheduling

## Protocol (Port 49200)

```
SCHEDULE|time|target|message   — Schedule delivery
LIST                           — Pending tasks
CANCEL|taskId                  — Cancel task
HISTORY                        — Completed deliveries
TODAY                          — Today's schedule
STATUS                         — Server status
```

## Contact

MEARVK LLC — mearvk@mearvk.us
