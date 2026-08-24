# US House JavaFX Installer

Cross-platform GUI installer for Windows, macOS, and Linux.

## Installation model

The GUI presents the canonical **1, 2, 3** installation stages:

1. **Core** — install the US House runtime.
2. **Tools** — install software-house tools and conveniences.
3. **Configure** — apply selected configuration and integration options.

The broader evidence lifecycle remains **1 Origin → 2 Custody → 3 Production → 4 Release**. The GUI's numbered installation choices are the actionable installation subset of that lifecycle.

## Integrations

The UI provides Microsoft and Apple integration choices. Actual privileged changes are intentionally delegated to the platform-specific launchers under `cmd/us-house/windows`, `cmd/us-house/macos`, and the corresponding Linux implementation. This keeps the JavaFX GUI platform-neutral.

## Build

The installer requires a JavaFX-capable JDK/toolchain. The repository currently does not contain a JavaFX build descriptor, so the Java source is the GUI implementation layer; a Maven or Gradle JavaFX packaging project should be added before producing signed native installers.

Recommended native targets are:

- Windows: `.msi` or `.exe`
- macOS: `.dmg` or `.pkg`
- Linux: `.deb` and/or `.rpm`

Native packaging should use platform-appropriate signing and should verify the resulting artifact before release.
