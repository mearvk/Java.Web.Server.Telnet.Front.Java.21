# Aptitude Module

The JWSTF Aptitude module is the Linux package-management integration for the Ubuntu Grand / US House software lifecycle.

## Reference source

The module references the Aptitude-related source and project conventions in:

`https://github.com/mearvk/Ubuntu.Determinant.Beta.Restricted`

The source repository is treated as the upstream project reference; this repository does not copy or claim ownership of unrelated Aptitude source code.

## Purpose

Aptitude provides a controlled interface for Debian/Ubuntu package discovery and lifecycle operations. It is the preferred package-management adapter when the host is Debian/Ubuntu and `aptitude` is available.

The module exposes the common JWSTF lifecycle:

```text
install → update → verify → remove
```

and supports:

- package search
- package installation
- package update
- package removal
- package status / verification
- dependency-aware planning
- dry-run/review before material changes
- provenance capture for package name, version, repository, and operation
- integration with the graphical installer
- `/user` and `/deck` deployment profiles without overriding Debian filesystem conventions

## Safety model

The adapter must prefer the native package manager over downloading arbitrary `.deb` files. Persistent or destructive operations must be visible to the caller and require the normal authorization available to the host environment.

`remove` means package-managed removal. It does not delete source repositories or unrelated user data unless the native package operation explicitly defines that behavior and the user authorizes it.

## Tomcat / Apache relationship

For Debian/Ubuntu hosts, Aptitude should be used when installing distribution-managed Apache or Tomcat packages. In that case their normal locations and service units remain authoritative, for example:

- Apache configuration: `/etc/apache2`
- Apache document root: `/var/www/html`
- Apache logs: `/var/log/apache2`
- Tomcat configuration: `/etc/tomcat10`
- Tomcat state: `/var/lib/tomcat10`

A manually managed Tomcat installation under `/opt/tomcat` is a separate deployment mode and must not be mixed with the package-managed Tomcat tree.

## Integration contract

The JavaFX installer can call this module for Debian/Ubuntu operations while displaying the proposed package changes first. Verification should report the installed version and package-management state after each operation.
