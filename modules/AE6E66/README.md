# AE6E66 — House of Lords Contact Module

## Structure

```
modules/AE6E66/
├── configuration/
│   └── ae6e66-config.xml          # Module config (URLs, SMTP, paths)
├── source/
│   ├── AE6E66Main.java            # Main: scrape, portraits, contacts, send
│   └── EmailDistributor.java      # SMTP distributor via local Postfix
├── scripts/
│   └── install-postfix-dovecot.sh # Postfix/Dovecot installer
├── marrister/                     # Draft messages here (*.txt)
├── portraits/                     # Portraits by ministry subfolder
│   └── {MinistryName}/
│       └── {memberId}.jpg
├── sent/                          # Archived sent messages by date
│   └── {YYYY-MM-DD}/
│       ├── message.txt
│       └── message.txt.sha256
└── contacts.csv                   # Scraped: id,name,email,phone,ministry,gender,age
```

## Usage

1. **Install Postfix/Dovecot** (required for sending):
   ```bash
   sudo bash modules/AE6E66/scripts/install-postfix-dovecot.sh
   ```

2. **Draft a message** in `modules/AE6E66/marrister/my-message.txt`

3. **Run the module**:
   ```bash
   javac modules/AE6E66/source/*.java
   java -cp modules/AE6E66/source modules.ae6e66.AE6E66Main
   ```

4. The module will:
   - Scrape all HOL member IDs from https://members.parliament.uk/members/Lords
   - Download portraits into `portraits/{Ministry}/`
   - Scrape contact pages for emails, phone, etc.
   - Write `contacts.csv`
   - SHA-256 hash each message, archive to `sent/{date}/`
   - Distribute via EmailDistributor to all scraped emails

## Postfix/Dovecot Requirement

EmailDistributor connects to `localhost:25` (Postfix). Without Postfix installed and running, email distribution will fail. Run the install script first.
