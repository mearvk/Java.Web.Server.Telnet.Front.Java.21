# Standard Installation Paths

JWSTF should follow the host operating system's normal filesystem conventions rather than inventing a single path for every platform.

## Linux

For Debian/Ubuntu package-managed services:

- Apache: `/etc/apache2`, `/var/www/html`, `/var/log/apache2`
- Tomcat package: `/etc/tomcat10`, `/var/lib/tomcat10`, with the distribution's systemd unit
- JWSTF configuration: `/etc/jwstf`
- JWSTF mutable state: `/var/lib/jwstf`
- JWSTF logs: `/var/log/jwstf`
- Application-managed/manual deployment: `/opt/jwstf`
- Source used for installation/building: `/usr/local/src/jwstf`

The important correction is that **distribution-managed Tomcat and manually installed Tomcat must not be mixed**. The existing installer currently uses `/opt/tomcat`; that is acceptable for a deliberately self-managed Tomcat installation, but a Debian/Ubuntu package installation should retain its package-managed `/etc/tomcat10` and `/var/lib/tomcat10` layout instead. The existing installer also correctly uses `/etc/apache2`, `/var/www/html/nwe`, and `/var/log`-based Apache logs for Apache integration. fileciteturn105file0

## Windows

Use normal Windows application/data separation:

- Installed machine-wide binaries: `C:\Program Files\JWSTF`
- Machine-wide mutable data/config/logs: `C:\ProgramData\JWSTF`
- Per-user application data: `%LOCALAPPDATA%\JWSTF`
- Per-user roaming data: `%APPDATA%\JWSTF`

Do not put mutable service state, databases, logs, or credentials inside `Program Files`.

## macOS

Use Apple filesystem conventions:

- Machine-wide GUI application: `/Applications/JWSTF.app`
- Machine-wide support data: `/Library/Application Support/JWSTF`
- Machine-wide logs: `/Library/Logs/JWSTF`
- Per-user application: `~/Applications/JWSTF.app`
- Per-user support data: `~/Library/Application Support/JWSTF`
- Preferences: `~/Library/Preferences`

Do not assume that a macOS installation has a system Apache available for application deployment; use the selected package manager or managed application distribution and preserve its paths.

## Profiles

The standard JSON source of truth is [`config/preferred-install-paths.json`](../config/preferred-install-paths.json).

Two deployment profiles are explicitly supported:

- **`/user`** — professional/user-scoped installations using the user's normal application-data locations.
- **`/deck`** — enterprise/centrally managed installations using machine-wide application locations.

These are **logical deployment profiles**, not literal filesystem directories that should replace operating-system conventions.
