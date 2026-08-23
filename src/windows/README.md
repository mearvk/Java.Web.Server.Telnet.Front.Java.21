# Windows Execution Model

This package provides the Windows-side execution vocabulary for the Java 21 server/frontend reference architecture.

The model is deliberately separated into seven concepts:

- **Execution** — performs a controlled process launch and records its result.
- **Program** — identifies an executable and constructs its argument vector.
- **Directive** — expresses the policy under which execution is permitted.
- **Citizen** — supplies a non-secret identity/accountability context.
- **Call** — records who requested which program under which directive.
- **Choice** — represents ordered executable alternatives and selects an available one.
- **Structure** — binds the complete execution context into one immutable envelope.

The implementation uses Java 21 records where the object is naturally immutable and a final class for the executable operation. It does not embed credentials or silently elevate privileges.

For production hardening, process timeouts, Windows ACL checks, executable allow-lists, audit persistence, and explicit cancellation should be implemented by the surrounding service before unrestricted process execution is enabled.
