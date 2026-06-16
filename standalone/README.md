# NWE Module Installer — Standalone

A standalone, system-aware JAR that listens on port 8888 and accepts module installations exclusively from verified NWE instances.

## Build

```bash
bash standalone/build.sh
```

## Run

```bash
bash standalone/run.sh
# or
java -jar standalone/nwe-module-installer.jar
```

## Protocol (port 8888)

### Install a module
```
INSTALL <filename> <sha256hex> <bytecount>\r\n
<raw bytes>
```
Server verifies public.key on GitHub before accepting. SHA-256 of payload must match.

### Copy this installer to another server
```
COPY <target-host>\r\n
```
Sends `nwe-module-installer.jar` via HTTP POST to `target:80/install` with `X-SHA256` header.
Target must have `public.key` on GitHub to be authorized.

## Security

- Only accepts connections when `psychiatry/secrets/public.key` is present on GitHub
- SHA-256 verified before any module is written to disk
- COPY feature only sends to verified targets (public.key check)
- This is NOT part of NWE — it runs independently on any server

## Files

- `NWEModuleInstaller.java` — source
- `nwe-module-installer.jar` — compiled standalone JAR (after build)
- `build.sh` — compile and package
- `run.sh` — start the installer
