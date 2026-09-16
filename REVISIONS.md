# REVISIONS.md

**Repository:** Java.Web.Server.Telnet.Front.Java.21  
**Review Date:** 2026-09-16  
**Branch:** `main`

## 2026-09-16 — System-Wide Engineering Review

This revision records the current engineering state of the JWSTF/NitroWebExpress system after review of the root architecture, administration layer, Black Belt tooling, Bitcoin area, orchestration scripts, configuration, integrity tooling, and module registry.

### Important rating convention

The requested qualitative scale is used as a software maturity/code-quality description, not as a measured benchmark:

| Area | Rating | Current assessment |
|---|---|---|
| Overall system architecture | **Great** | Broad modular architecture with server, module, administration, deployment, and configuration layers. |
| Code organization | **Better** | Strong separation exists, but the repository remains large and contains legacy/parallel implementation paths. |
| Java 21 integration | **Great** | Java 21 is the declared primary platform with a coherent Java server/module model. |
| Administration layer | **Great** | Local JavaFX plus C/C++ administrative tooling is documented and separated from privileged host authority. |
| Black Belt subsystem | **Great** | Web and CLI surfaces are documented with C11/C++17/Java 21 clients and explicit transport/output behavior. |
| Bitcoin subsystem | **Better** | Substantial functionality exists, but descriptor, verification, and testing discipline should be strengthened. |
| Build/deployment tooling | **Better** | Many useful orchestration scripts exist; consolidation and reproducibility remain targets. |
| Integrity/security tooling | **Great** | SHA-256 verification, history, concerns, and restoration mechanisms are documented; enforcement should continue to be hardened. |
| Configuration management | **Better** | XML registries provide substantial centralization; systematic validation should be expanded. |
| Test coverage | **Good** | Test tooling exists, but this review did not establish comprehensive coverage or successful execution of every module. |
| Runtime performance | **Not benchmarked** | No reproducible benchmark run was performed during this documentation review. |
| Operational reliability | **Better** | Startup/shutdown/status/deployment tooling is extensive; failure-path testing should be expanded. |
| Documentation | **Great** | Root, administration, Black Belt, and revision documentation now provide substantially clearer system context. |
| Release discipline | **Better** | Versioned components exist, but manifests, checksums, provenance, and reproducible-build metadata should be standardized. |

## Current System State

The project is a multi-module Java 21 server platform with NIO/TCP and Telnet-oriented services, Tomcat web frontends, Java/C/C++ components, centralized orchestration, XML configuration, MySQL-backed modules, administrative tooling, integrity verification, AI/inference components, cryptographic communication, and Bitcoin-related services.

### Administration

The `admin/` area contains `LocalAdmin.java`, `RoyalsUSGuardIAdmin.java`, `StateSecurityDownIAdmin.java`, `admin-c.c`, and `admin-cpp.cpp`. The administrative model is review-first; privileged host changes remain subject to normal authorization controls.

### Black Belt

The Black Belt CLI layer is documented under `modules/black-belt/bin/` with C11, C++17, and Java 21 clients, structured JSON input, natural-language input, configurable model selection, exact-response output, save/no-save modes, HTTPS/SSH transport, and explicit insecure-transport opt-in.

### Bitcoin

The repository contains Bitcoin material at multiple architectural levels, including the top-level `bitcoin/` area and `modules/bitcoin/`. The current `bitcoin/bash/wallet-summary.sh` scans version-numbered wallet directories, extracts BTC quantities from wallet filenames, produces summaries, calculates aggregate BTC quantities, and applies a configured USD conversion.

**Engineering note:** the $20,000,000,000,000 BTC price in that script must be treated as a configured/test valuation, not a live market quotation. A future revision should make the valuation source explicit and preferably accept the price as an argument or configuration value.

Bitcoin Core is security-critical and its upstream project emphasizes unit tests, functional tests, cross-platform CI, and independent QA. JWSTF Bitcoin tooling should move toward an equally explicit verification model where applicable. citeturn0search1turn0search11

Bitcoin Core also documents platform-specific data directories and wallet/data-storage conventions. JWSTF wallet tooling should preserve those boundaries and avoid treating a filename alone as authoritative wallet state. citeturn0search4

## Improvements Completed

1. Root README updated with current administration and Black Belt information.
2. Administration README updated with descriptor dates and current component inventory.
3. Black Belt CLI documentation dated and consolidated.
4. Source descriptors dated for the administration programs.
5. This `REVISIONS.md` establishes a persistent engineering review record.
6. Bitcoin subsystem limitations and improvement targets are explicitly recorded.

## Recommended Next Engineering Pass

### Priority 1 — Verification

- Add a repository-wide build verification job.
- Run Java compilation for every supported module.
- Build C and C++ native components with warnings enabled.
- Run unit/integration tests.
- Record exact Java, GCC/Clang, Gradle/Maven, MySQL, and Tomcat versions.
- Publish pass/fail results as build artifacts.

### Priority 2 — Bitcoin hardening

- Replace the hard-coded BTC valuation with an explicit configured/test price.
- Add `bitcoin/DESCRIPTOR.md`.
- Add `bitcoin/SECURITY.md`.
- Add deterministic tests for wallet-summary parsing.
- Validate filenames before numerical aggregation.
- Prefer fixed-point integer satoshi accounting where monetary arithmetic is required.
- Add checksum/signature verification for downloaded Bitcoin Core releases.
- Record release version, source URL, SHA-256, signature status, and verification date.

### Priority 3 — Runtime performance

Create reproducible benchmarks for Main NIO connection handling, Telnet latency, concurrent connection throughput, Black Belt latency, Bitcoin service operations, database latency, startup/shutdown time, memory consumption, and heap behavior.

No numerical performance rating should be treated as established until these measurements have been run.

### Priority 4 — Reliability

- Add service-level health checks.
- Test partial startup failures.
- Test database-unavailable startup.
- Test Tomcat deployment failures.
- Test module restart isolation.
- Test integrity-repair failure paths.
- Add bounded retry/backoff behavior where appropriate.

### Priority 5 — Security

- Enforce least privilege for installation and repair operations.
- Keep privileged operations explicit and auditable.
- Verify all downloaded artifacts before execution.
- Avoid secrets in source, logs, committed configuration, and generated reports.
- Add automated dependency/security scanning.
- Establish a formal threat model for externally reachable TCP ports.

## Current Qualitative Summary

**Good → Better → Best → Great → Super**

- **System architecture: Great**
- **Code organization: Better**
- **Administration: Great**
- **Black Belt: Great**
- **Bitcoin: Better**
- **Build/deployment: Better**
- **Security/integrity: Great**
- **Documentation: Great**
- **Testing: Good**
- **Performance: Not benchmarked**
- **Overall engineering maturity: Great, with a clear path toward Super**

“Super” is intentionally reserved for a future state supported by reproducible builds, comprehensive automated testing, security verification, independent QA, and published performance measurements rather than documentation alone.

## Revision Record

### 2026-09-16
- Completed system-wide qualitative engineering review.
- Added current-state ratings.
- Documented administration and Black Belt changes.
- Reviewed Bitcoin subsystem structure and wallet-summary implementation.
- Recorded Bitcoin valuation and verification concerns.
- Added prioritized engineering roadmap.
- Established this file as the persistent revision record.