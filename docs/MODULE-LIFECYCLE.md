# Module Lifecycle Contract

The Java.Web.Server.Telnet.Front.Java.21 repository now defines a uniform lifecycle surface for its modules:

```text
install → update → verify → remove
```

The repository already contains many per-module backend start/shutdown hooks; for example, the module tree contains `start-backend.sh` and `shutdown-backend.sh` pairs across modules. The Windows US-House tooling also already exposes install/update/remove/status operations for Microsoft and Apple package aliases. fileciteturn103file0 fileciteturn103file15 fileciteturn100file0

## Controllers

Linux/macOS/WSL-style environments:

```bash
scripts/module-lifecycle.sh status all
scripts/module-lifecycle.sh install all
scripts/module-lifecycle.sh update all
scripts/module-lifecycle.sh verify all
scripts/module-lifecycle.sh remove <module>
```

Windows PowerShell:

```powershell
powershell -File scripts/module-lifecycle.ps1 -Action status -Module all
powershell -File scripts/module-lifecycle.ps1 -Action install -Module all
powershell -File scripts/module-lifecycle.ps1 -Action update -Module all
powershell -File scripts/module-lifecycle.ps1 -Action verify -Module all
powershell -File scripts/module-lifecycle.ps1 -Action remove -Module <module>
```

## Contract

Every module should eventually expose these optional repository-local hooks:

- `install.sh` — install/prepare the module.
- `update.sh` — update/rebuild the module.
- `verify.sh` — verify expected source/build/runtime state.
- `uninstall.sh` — remove installed artifacts using module-specific knowledge.
- `start-backend.sh` / `shutdown-backend.sh` — runtime lifecycle where applicable.
- `start-frontend.sh` / `shutdown-frontend.sh` — web deployment lifecycle where applicable.

The generic controllers use the best available repository-local build mechanism when a hook is absent: Make, Maven, or Gradle.

## Removal safety

**Remove does not delete source code.** It stops/undeploys supported services and removes recognized generated artifacts such as `out`, `build`, `target`, `.class`, and generated `.jar` files. A module-specific `uninstall.sh` takes precedence when one exists.

This keeps repository history, source, documentation, and configuration separate from installed/generated state.

## Windows ecosystem

The repository's existing US-House Windows PowerShell controller uses `winget` for Microsoft and Apple package operations and supports `install`, `update`, `remove`, `status`, and `list`. fileciteturn100file0

The new lifecycle controller complements that package layer: it manages **repository modules**, while US-House manages **host software packages**.

## Acceptance rule

A module is lifecycle-complete when it has:

1. a deterministic install path;
2. a deterministic update path;
3. a verification path with meaningful checks;
4. a safe removal path;
5. explicit runtime start/stop hooks when it is a service;
6. documentation of dependencies and generated artifacts.

No module should become an installation orphan merely because its build or deployment mechanism differs from another module.
