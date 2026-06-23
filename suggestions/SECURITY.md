# SECURITY.md — Security Suggestions

Phone:      1.919.923.4239 (USA)
Languages:  American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, Turkish

## Key Management

- The `secret.key` (3996 bytes) is used as SHA-256 salt for all wallet signatures. If this file is lost or corrupted, all wallet signatures become unverifiable. Maintain an encrypted backup separate from the repository.
- The `public.key` verification (PublicKeyVerifier) uses HTTP HEAD to GitHub. If GitHub is unreachable (network outage, DNS failure), the software defaults to "restricted mode." Consider a cached grace period (e.g., last-verified timestamp within 24 hours = still authorized).
- The GitHub PAT (`ghp_...`) referenced in EdgeSchedule should never appear in source code or commit history. Store it exclusively in environment variables or a local-only credentials file.

## Authentication

- The default admin password in nwe-config.xml is `n21admin`. The INSTALL.readme mentions changing it before production, but the software doesn't enforce this. Add a first-boot password change prompt.
- ModuleInstallationService uses `admin <password>` over plaintext telnet. Any network sniffer can capture credentials. Consider challenge-response auth or restrict admin commands to localhost-only connections.
- National ID identification (`identify <nationalId>`) has no password — anyone who knows an 8-digit ID can impersonate that user. Add a PIN or keypair verification step.

## Network Exposure

- 12+ ports are bound on `localhost`. If the host has public-facing interfaces and binding changes to `0.0.0.0`, all services become internet-exposed. Ensure firewall rules (iptables/ufw) restrict external access to only intended ports.
- The HeuristicClassifier drops connections with score ≥ 40, but scoring logic should be reviewed for false positives on legitimate high-frequency users.
- TLS is not used on any telnet port. Credentials, wallet names, and trade commands travel in cleartext. Consider wrapping telnet services in stunnel or migrating to SSH-based access.

## Data Protection

- Wallet BLOBs in MySQL are unencrypted at rest. If the MySQL data directory is compromised, all wallet data is exposed. Enable MySQL Transparent Data Encryption (TDE) or encrypt blobs before insertion.
- The Transfer of Summary document contains financial valuations. It's gitignored but exists on disk. Ensure file permissions restrict access (`chmod 600`).
- Bitcoin trade records (`bitcoin_trades_v*`) contain NationalID → wallet mappings. This is sensitive PII-adjacent data. Access should be restricted to admin roles only.

## Dependency Security

- The MySQL connector JAR (`mysql-connector-j-9.7.0.jar`) should be verified against its published SHA-256 checksum. Pin the version and verify on install.
- No other third-party JARs are vendored except Lanterna. Keep the dependency surface minimal.
