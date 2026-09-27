# PIXEL.md

## Purpose

This document is the project-facing **PIXEL** description for NitroWebExpress™ / Java.Web.Server.Telnet.Front.Java.21.

PIXEL is a compact way to explain a large software project in two complementary views:

1. **What's Made** — the capabilities and working architectural pieces represented by the project.
2. **What's Included** — the concrete source, configuration, scripts, modules, deployment material, tests, and supporting assets that make those capabilities part of the repository.

The purpose is to make a large repository understandable without reducing it to a single marketing paragraph or an unverified claim of production readiness.

---

# 1. What's Made

## 1.1 Core Server Platform

The project is a Java 21 multi-module server platform centered on **NitroWebExpress™**.

The core architecture combines:

- Java TCP and Telnet-facing services.
- NIO-based routing and masquerade infrastructure.
- Shared startup and shutdown orchestration.
- Configurable service and port registries.
- Tomcat-deployed web frontends.
- MySQL-backed application modules.
- Native C/C++ components where a module calls for a lower-level implementation.
- Administrative and installation tooling.

The repository therefore represents a server ecosystem rather than a single HTTP endpoint.

## 1.2 Network and Protocol Services

The repository contains multiple network-facing services with explicitly assigned ports, including:

- NitroWebExpress main service.
- AES, RSA, and DSA service implementations.
- Bitcoin service components.
- Connection-status service.
- ASCII creator.
- Module installation service.
- Module loader daemon.
- Binary HTTP service.
- Communicator encrypted-chat service.
- Strernary inference and directory services.
- Signal-oriented TCP services.
- Additional module-specific TCP servers.

The port registry and configuration files provide a central vocabulary for how these services are identified and started.

## 1.3 NIO Masquerade and Routing

The NioMasquerade layer provides a dedicated routing concept for multiplexing and presenting configured network services through a controlled NIO layer.

Its configuration is represented separately from ordinary application modules so that routing policy, bindings, and module discovery remain inspectable.

## 1.4 Web Frontend System

The project includes a Tomcat-oriented web deployment system.

The frontend layer includes web applications for areas such as:

- Bitcoin.
- Dictionary.
- Calendar.
- Analytics.
- Language packs.
- Black Belt.
- Institutional and module-specific interfaces.
- Other configured application modules.

Deployment is coordinated through repository scripts and XML configuration rather than requiring each web application to invent its own lifecycle.

## 1.5 Communicator™

The Communicator service provides an encrypted TCP/Telnet chat design with negotiated cryptographic options.

The documented design includes:

- AES-256-GCM.
- RSA-2048.
- RSA-4096.
- Twofish-256.
- ECC/secp256r1.
- ChaCha20-Poly1305.
- DH-2048 or ECDH key exchange as applicable.
- Profile-based cipher selection.

This PIXEL document records the implementation as represented by the repository; cryptographic security claims should continue to be verified through independent testing and review.

## 1.6 TandemEquals™

TandemEquals™ provides a four-layer simplex model:

1. Perception.
2. Cognition.
3. Modulation.
4. Expression.

The service exposes a TCP protocol for inspecting signals, patterns, modulators, outputs, curves, evaluation paths, and status.

Its associated database schema provides persistence for the model.

## 1.7 Fiduciary and Native Service Work

The Fiduciary module combines Java services with native C components for ACH-related processing.

The repository also contains native integration for other specialized modules, including ArmorerSteve.

These components demonstrate the project's hybrid Java/native architecture:

- Java for service orchestration and application logic.
- Native C where lower-level or OS-integrated processing is required.
- Makefiles and shell scripts for native build steps.
- Shared configuration and deployment conventions.

## 1.8 Module Ecosystem

The `modules/` tree provides a large collection of independently recognizable service areas.

The current repository documents modules for:

- Institutional interfaces.
- Library and academic services.
- Chat.
- Knowledge/Q&A.
- Fiduciary services.
- Port registries.
- AI/futures services.
- Defined AI services.
- Calendar and dictionary applications.
- Analytics.
- Language management.
- Module loading.
- Additional named application and research modules.

A PIXEL description should name these as **repository components** rather than implying that every module has the same runtime maturity, deployment requirements, or operational status.

## 1.9 Integrity System

The project includes a post-install integrity system centered on SHA-256 and MD5 file verification.

The documented workflow includes:

1. Self-integrity checking.
2. Scanning Git-tracked files.
3. Recording historical digests.
4. Recording integrity concerns.
5. Optional restoration behavior through the configured GitHub source.

The integrity system is part of the repository's operational tooling and should be evaluated separately from application-level security.

## 1.10 Operations and Lifecycle

The project includes scripts for:

- Installation.
- Compilation.
- JAR construction.
- Backend startup.
- Backend shutdown.
- Frontend deployment.
- Frontend undeployment.
- MySQL startup/shutdown.
- Overall startup/shutdown.
- Status reporting.
- Local testing.
- UFW configuration.
- Mail installation and configuration.
- Integrity checks.

This makes lifecycle management part of the project's source rather than an undocumented collection of manual commands.

---

# 2. What's Included

## 2.1 Core Source

The repository includes Java source for the central server and supporting services, including:

- `source/`
- Core `Main` entry point.
- Server implementations.
- Communicator.
- Strernary services.
- NIO-related components.
- Supporting protocol and service classes.

## 2.2 Module Source

The `modules/` directory contains the individual service implementations and their supporting material.

Modules may contain:

- Java sources.
- JSP/web resources.
- Configuration.
- SQL schemas.
- Native C/C++ sources.
- Makefiles.
- Startup/shutdown scripts.
- Module-specific documentation.

## 2.3 Configuration

The configuration layer includes XML definitions for:

- Master NWE configuration.
- Port and server definitions.
- NIO masquerade modules.
- NIO bindings.
- Output formatting.
- Protocol handlers.
- Port-directory routing.
- Tomcat web deployment.
- Mail configuration.

Configuration is deliberately separated from implementation so operators can inspect deployment behavior without reading every Java class.

## 2.4 Build and Deployment Scripts

The repository includes executable shell tooling for:

- Full compilation.
- JAR creation.
- Server orchestration.
- Backend orchestration.
- Frontend deployment.
- Installation.
- Status checks.
- Testing.
- Firewall setup.
- Mail setup.
- Integrity verification.

These scripts are part of the project and should be documented as source, not treated as incidental convenience files.

## 2.5 Database Material

Database-backed services include their associated schema/configuration material.

Documented databases include areas such as:

- Integrity.
- TandemEquals.
- Fiduciary.
- ArmorerSteve.
- Dictionary.
- Other module-specific persistence layers.

Database names, tables, credentials, and deployment behavior should remain configuration-driven and should never require committing production secrets.

## 2.6 Web Application Material

The repository contains Tomcat-oriented web application resources and deployment configuration.

The web layer is intended to work alongside the TCP backend layer, allowing the project to present both:

- Network/service interfaces.
- Browser-facing interfaces.

## 2.7 Native Components

Where appropriate, native C/C++ source is included beside the Java module that consumes it.

Examples include:

- `fiduciary.c`
- `ach_transfer.c`
- `armorer.c`

The native layer is part of the source architecture and should be compiled and tested according to the module's actual build requirements.

## 2.8 Testing and Verification

The repository includes a local testing entry point and CI configuration.

Relevant project infrastructure includes:

- `scripts/test-local.sh`
- Maven workflow.
- CodeQL workflow.
- Qodana workflow.
- Installer workflow.
- Integrity tooling.

CI presence means that validation infrastructure exists; it does not, by itself, establish that every module is production-ready or that every environment has been tested.

## 2.9 Documentation

The repository includes project-level and module-level Markdown documentation covering:

- Architecture.
- Revisions.
- Installation.
- Configuration.
- Operational procedures.
- Module behavior.
- Integrity.
- Engineering notes.

PIXEL adds a high-level index of those materials.

---

# 3. How to Write This Kind of Stuff

A good PIXEL document should answer a reader's first practical questions.

## 3.1 Start With What the Project Is

Give the reader one clear sentence describing the software category.

For this project:

> A multi-module Java 21 server platform combining TCP/Telnet services, NIO routing, Tomcat web applications, databases, native components, and operational tooling.

That sentence establishes the architectural shape before details begin.

## 3.2 Separate "Made" From "Included"

**What's Made** describes capabilities.

Examples:

- A server.
- A router.
- An encrypted-chat service.
- A deployment system.
- A module ecosystem.
- An integrity system.

**What's Included** describes repository objects.

Examples:

- Java source.
- Shell scripts.
- XML.
- SQL.
- C source.
- JSP/web resources.
- CI workflows.
- Documentation.

This distinction prevents a source file from being mistaken for a finished capability.

## 3.3 Name Concrete Things

Prefer:

> `scripts/compile-all-modules.sh` compiles Java sources into `out/`.

over:

> The project has a sophisticated compiler system.

Concrete names make the documentation auditable.

## 3.4 Record Ports Carefully

A port number should be accompanied by the service it represents and, when useful, the implementation class or module path.

Port tables should be treated as configuration-derived facts. If a port changes, update the relevant configuration and PIXEL documentation together.

## 3.5 Distinguish Architecture From Operational Status

A repository may contain:

- Implemented source.
- Experimental modules.
- Deployment scaffolding.
- CI validation.
- Production-oriented tooling.
- Components that still need broader testing.

PIXEL should describe the architecture accurately without turning the existence of source code into an unsupported production-readiness claim.

## 3.6 Explain Integration Boundaries

For a large project, show how the pieces connect:

```
Java 21 services
      |
      +---- TCP / Telnet
      |
      +---- NIO routing
      |
      +---- MySQL
      |
      +---- Tomcat webapps
      |
      +---- Native C/C++
      |
      +---- Shell deployment / operations
      |
      +---- Integrity / CI
```

A useful PIXEL document explains the boundaries as well as the individual components.

## 3.7 Use Version Language Carefully

When a component has a formal version, state it from the project's authoritative version source.

When no authoritative component version is present, do not invent one merely to make the PIXEL page look complete.

A documentation update is not automatically a software-version release.

## 3.8 Describe Security Without Overclaiming

Security-related source should be described by its concrete behavior:

- Hash verification.
- Encryption negotiation.
- Access controls.
- Firewall configuration.
- Credential configuration.
- Code scanning.

Do not convert those mechanisms into an absolute statement that the whole platform is secure.

## 3.9 Keep the Document Maintainable

When a module, port, script, or configuration file changes:

1. Update the source/configuration.
2. Update the relevant module documentation.
3. Update PIXEL when the high-level description changes.
4. Run the applicable validation.
5. Record any remaining limitations.

PIXEL is an architectural index, not a replacement for detailed module documentation.

---

# 4. Recommended PIXEL Pattern

For future projects, use this structure:

```markdown
# PIXEL.md

## Purpose

What this document is for.

# 1. What's Made

## 1.1 Core capability
## 1.2 Major services
## 1.3 Interfaces
## 1.4 Storage
## 1.5 Operations
## 1.6 Security / integrity
## 1.7 Validation

# 2. What's Included

## 2.1 Source
## 2.2 Modules
## 2.3 Configuration
## 2.4 Scripts
## 2.5 Tests
## 2.6 Documentation
## 2.7 CI / packaging

# 3. How to Write This Kind of Stuff

## 3.1 Describe
## 3.2 Separate
## 3.3 Identify
## 3.4 Verify
## 3.5 Avoid overclaiming

# 4. Recommended PIXEL Pattern

Reusable structure.

# 5. Current Project Snapshot

Version/status/technology summary.

# 6. Maintenance Rule

How PIXEL stays synchronized.
```

---

# 5. Current NitroWebExpress™ Snapshot

| Area | Current repository representation |
|---|---|
| Primary project | Java.Web.Server.Telnet.Front.Java.21 |
| Project name | NitroWebExpress™ |
| Primary language/runtime | Java 21 |
| Network model | TCP / Telnet / HTTP-oriented services |
| Routing | Java NIO / NioMasquerade |
| Web deployment | Apache Tomcat |
| Database | MySQL-backed modules |
| Native integration | C/C++ for selected services |
| Configuration | XML + shell deployment configuration |
| Operations | Installation, startup, shutdown, deployment, status, firewall, mail |
| Integrity | SHA-256 / MD5 verification tooling |
| Testing | Local test script + CI workflows |
| Major source areas | `source/`, `modules/`, `configuration/`, `scripts/` |
| Main documentation | `README.md`, `REVISIONS.md`, module documentation, `PIXEL.md` |

The repository currently presents a broad server-platform architecture. Individual modules should be evaluated on their own implementation, dependencies, test coverage, and deployment requirements.

---

# 6. Maintenance Rule

**PIXEL follows the repository.**

When the project changes materially:

- Keep the source as the authoritative implementation.
- Keep XML/configuration as the authoritative runtime configuration.
- Keep scripts synchronized with the actual lifecycle.
- Keep module documentation synchronized with module behavior.
- Keep port documentation synchronized with configured ports.
- Keep security descriptions limited to demonstrated mechanisms.
- Keep version statements tied to authoritative version sources.
- Keep validation claims tied to tests that actually ran.
- Record unfinished work rather than silently presenting it as complete.

The goal of PIXEL is simple:

> **Make the project easier to understand without making the project sound like something it is not.**
