# US House JavaFX Installer

Cross-platform GUI installer for Windows, macOS, and Linux.

## Installation model

The GUI presents the canonical installation stages:

1. **Core** — install the US House/JWSTF runtime.
2. **Tools** — install software-house tools and conveniences.
3. **Configure** — apply selected configuration and integrations.
4. **Verify** — inspect the resulting installation and produce a report.

The broader lifecycle is **install → update → verify → remove**, while the evidence lifecycle remains **1 Origin → 2 Custody → 3 Production → 4 Release**.

## GUI options

The installer should expose these options before execution:

- Install / repair
- Update
- Verify
- Remove installed artifacts
- `/user` professional/user-scoped profile
- `/deck` enterprise/machine-wide profile
- Linux / Windows / macOS target
- Distribution-managed or manually managed Tomcat on Linux
- Apache integration where available
- Java 21 prerequisite handling
- JWSTF application, configuration, state, and log paths
- Start/stop service after operation
- Dry-run / review changes
- Export an installation report

The GUI must never silently delete repository source. Removal concerns installed/generated artifacts and uses the platform's normal uninstall mechanism where available.

## Integrations

The UI provides Microsoft and Apple integration choices. Actual privileged changes are delegated to platform-specific launchers under `cmd/us-house/windows`, `cmd/us-house/macos`, and the corresponding Linux implementation. This keeps the JavaFX GUI platform-neutral.

## Standard paths

The installer reads `config/preferred-install-paths.json`. `/user` and `/deck` are logical deployment profiles; they resolve to native OS locations rather than replacing OS conventions.

For Linux, distribution-managed Tomcat retains its package-managed `/etc/tomcat10` and `/var/lib/tomcat10` layout. A deliberate manual Tomcat installation may use `/opt/tomcat`; these management models must not be mixed.

## Native packaging

The repository should build the GUI as a Java application/JAR and use `jpackage` on the target OS for native installation artifacts:

- **Windows:** `.exe` and/or `.msi`
- **macOS:** `.dmg` and/or `.pkg`
- **Linux:** `.deb` and/or `.rpm`, plus an application image where useful

Native installers should be generated on their corresponding operating system, signed where appropriate, checksummed, and published as release artifacts. The repository should not contain fabricated platform binaries.

The existing source is the GUI implementation layer; a JavaFX Maven or Gradle packaging project should be added/used by the release build before producing native installers.
