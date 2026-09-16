# Black Belt Linux Command-Line Interface

This directory adds a Linux terminal interface for the Black Belt Ethical Auditor (BBEA) without requiring the JSP/Tomcat front end. It is a front-end transport layer: the existing Black Belt `sharp` schemas, system prompt, and AI engine remain authoritative.

## Implementations

- `blackbelt-c.c` — C11 client.
- `blackbelt.cpp` — C++17 client.
- `BlackBeltCLI.java` — Java 21 client.
- `blackbelt-engine.sh` — shared Ollama-compatible engine transport.
- `Makefile` — build/install targets.

The existing BBEA input schema requires `style`, `belt_level`, `jurisdiction`, `conduct_observations`, and `ethical_responses`; optional fields include `legitimacy_hint`, `legal_context`, and `auditor_notes`. The CLI therefore accepts the same structured JSON rather than inventing a second input format. fileciteturn18file0

The existing model output contract includes `legitimacy_assessment`, `ethical_risk_profile`, `legal_alignment`, `conduct_score`, and `risk_rating`, with closure fields in the established output schema. fileciteturn17file3

## Build

From this directory:

```bash
make
```

This produces:

```text
bin/blackbelt-c
bin/blackbelt-cpp
bin/BlackBeltCLI.class
```

## Use

Interactive/pipe mode:

```bash
cat audit.json | ./blackbelt-c
cat audit.json | ./blackbelt-cpp
cat audit.json | java BlackBeltCLI
```

File mode:

```bash
./blackbelt-c --file audit.json
./blackbelt-cpp --file audit.json
java BlackBeltCLI --file audit.json
```

## Engine connection

The default transport targets an Ollama-compatible service at:

```text
http://127.0.0.1:11434/api/generate
```

The default model is `llama3.1:8b`. Override either without recompiling:

```bash
export BBEA_ENGINE_URL=http://127.0.0.1:11434/api/generate
export BBEA_MODEL=llama3.1:8b
```

The Java client connects directly to the engine. The C and C++ clients use the shared `blackbelt-engine.sh` adapter, which packages the canonical JSON request and sends it to the same engine endpoint. This gives all three front ends one engine contract and permits the transport to evolve later into a local Unix socket, TCP service, or direct native library without changing the audit input format.

## Prompt selection

By default the engine adapter loads:

```text
black.belt/sharp/system.prompt
```

Override it with:

```bash
export BBEA_SYSTEM_PROMPT=/path/to/system.prompt
```

## Installation

For a system-wide Linux installation, from `bin/`:

```bash
sudo make install PREFIX=/bin
```

For a conventional local installation instead:

```bash
sudo make install PREFIX=/usr/local/bin
```

The repository keeps the implementation under `/bin` as requested; the installation prefix remains configurable so distributions can choose their normal executable location.

## Architecture

```text
                 +----------------------+
                 | Black Belt Web/JSP   |
                 +----------+-----------+
                            |
                            v
+------------+    +----------------------+    +-------------------+
| C CLI      |--->|                      |--->| Ollama / Llama    |
+------------+    | BBEA Engine Contract |    | BBEA model        |
                  |                      |    +-------------------+
+------------+    | JSON in / JSON out   |
| C++17 CLI  |--->|                      |
+------------+    +----------------------+

+------------+
| Java 21 CLI|---------------------------> same engine endpoint
+------------+
```

The current Black Belt repository already contains the web module's startup/shutdown scripts and the `sharp` model artifacts. fileciteturn14file0 fileciteturn15file0

The CLI intentionally does not duplicate the model prompt or create a second scoring system. It feeds the existing BBEA contract so the terminal and web interfaces can converge on the same AI evaluation path.
