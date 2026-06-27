# AE6E66 — House of Lords + House of Commons Contact Module

## Structure

```
modules/AE6E66/
├── configuration/
│   ├── ae6e66-config.xml          # Module config (URLs, SMTP, domain, crawl state)
│   └── .last-crawl                # Date of last successful MPUK crawl
├── source/
│   ├── AE6E66Main.java            # Main: crawl 0–999, portraits, contacts, distribute
│   └── EmailDistributor.java      # SMTP distributor via local Postfix (mail.lauradei.us)
├── scripts/
│   ├── install-postfix-dovecot.sh # Basic Postfix/Dovecot install (direct MX delivery)
│   ├── configure-local-server.sh  # Static IP local server style config
│   └── setup-dkim-lauradei.sh     # DKIM/SPF/DMARC for lauradei.us @ 45.32.31.139
├── marrister/                     # Stationary — draft messages here (*.txt)
├── personal/                      # Outlook/Exchange importable CSV for Lords/Ministers
│   └── lords-ministers-outlook.csv
├── portraits/                     # Portraits by ministry subfolder
│   └── {MinistryName}/
│       └── {memberId}.jpg
├── sent/                          # Archived sent messages by date
│   └── {YYYY-MM-DD}/
│       ├── message.txt
│       ├── message.txt.sha256
│       ├── message.txt.success.log
│       └── message.txt.failure.log
├── contacts.csv                   # Full contacts (HOL + HOC sections with headings)
├── README.md                      # This file
└── AE6E66.RDRS                    # Registry Descriptor Record Sheet
```

## Crawl Behavior

- Brute-force scans member IDs 0–999 on `members.parliament.uk/member/XXX/contact`
- Also hits `/member/XXX/career` for career data
- Downloads portraits to `portraits/{Ministry}/`
- Auto-detects HOL vs HOC from page content
- Scrapes HOC Enquiries Service page for general `@parliament.uk` contacts
- **Skip logic:** If `.last-crawl` exists and is < 30 days old, crawl is skipped. Delete the file or wait for new election season (Lords/Commons) to re-crawl.

## contacts.csv Format

```
# House of Lords - Year of Our Lord - 2026
id,name,email,phone,ministry,gender,age,source,career
...

# House of Commons - Year of Our Lord - 2026
id,name,email,phone,ministry,gender,age,source,career
...
```

## personal/ — Outlook Import

`lords-ministers-outlook.csv` uses standard Outlook CSV headers:
```
First Name,Last Name,E-mail Address,Business Phone,Company,Job Title,Categories
```

Import directly into Outlook, Exchange, or any compatible contact manager.

## Email Distribution

1. Draft a `.txt` message in `marrister/`
2. Run the module
3. Each recipient gets the message via local Postfix SMTP
4. Success/failure counts written to separate log files in `sent/{date}/`

### Mail Server Setup

| Script | Purpose |
|--------|---------|
| `install-postfix-dovecot.sh` | Basic install, direct MX delivery |
| `configure-local-server.sh` | Static IP binding, rate limiting |
| `setup-dkim-lauradei.sh` | Full DKIM/SPF/DMARC for `mail.lauradei.us` @ `45.32.31.139` |

**Server ID:** `mail.lauradei.us`
**From:** `contact@lauradei.us`
**Target install:** Japanese VPS (chance/luck)

## Usage

```bash
# First time — install mail
sudo bash modules/AE6E66/scripts/setup-dkim-lauradei.sh

# Run module
javac modules/AE6E66/source/*.java
java -cp modules/AE6E66/source source.AE6E66Main

# Force re-crawl
rm modules/AE6E66/configuration/.last-crawl
```

## Print

All output via CommonRails in Emerald Green (`\033[38;5;35m`) — designates Royals.
