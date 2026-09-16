# Black Belt Linux Command-Line Interface

This directory adds a Linux terminal interface for the Black Belt Ethical Auditor (BBEA) without requiring the JSP/Tomcat front end. It is a front-end transport layer: the existing Black Belt `sharp` schemas, system prompt, and AI engine remain authoritative.

## Implementations

- `blackbelt-c.c` — C11 client.
- `blackbelt.cpp` — C++17 client.
- `BlackBeltCLI.java` — Java 21 client.
- `blackbelt-engine.sh` — shared Ollama-compatible engine transport.
- `blackbelt-output.sh` — exact-response output/transport helper.
- `blackbelt-2.c` — alternate C client with local response saving disabled.
- `Makefile` — build/install targets.

The existing BBEA input schema requires `style`, `belt_level`, `jurisdiction`, `conduct_observations`, and `ethical_responses`; optional fields include `legitimacy_hint`, `legal_context`, and `auditor_notes`. The CLI therefore accepts the same structured JSON rather than inventing a second input format.

The existing model output contract includes `legitimacy_assessment`, `ethical_risk_profile`, `legal_alignment`, `conduct_score`, and `risk_rating`, with closure fields in the established output schema.

## Build

From this directory:

```bash
make
```

This produces the C/C++ executables and the Java 21 class. The standard build also normalizes the shell scripts in this directory to executable permissions.

## Use

Pipe mode:

```bash
cat audit.json | ./blackbelt-c
cat audit.json | ./blackbelt-cpp
cat audit.json | java BlackBeltCLI
```

Interactive C/C++ mode accepts either a natural-language question or a JSON audit object:

```text
Black Belt Ethical Auditor
Ask a question or enter a JSON audit object. Type 'help' or 'quit'.
black-belt>
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

The default model is `llama3.2:latest`. Override either without recompiling:

```bash
export BBEA_ENGINE_URL=http://127.0.0.1:11434/api/generate
export BBEA_MODEL=llama3.2:latest
```

The C and C++ clients use the shared `blackbelt-engine.sh` adapter, which packages the request and sends it to the same engine endpoint. Natural-language questions are sent without Ollama's JSON-output constraint; structured audit objects retain the established JSON output contract.

## Prompt selection

The repository prompt remains at:

```text
../../../black.belt/sharp/system.prompt
```

when running from this directory. A system-wide installation also places the prompt at `/usr/share/blackbelt/sharp/system.prompt`.

Override it with:

```bash
export BBEA_SYSTEM_PROMPT=/path/to/system.prompt
```

## Installation

The CLI source now lives under:

```text
modules/black-belt/bin/
```

From this directory:

```bash
make
sudo make install PREFIX=/bin
```

For a conventional local executable directory instead:

```bash
sudo make install PREFIX=/usr/local/bin
```

The installation prefix is configurable for Linux distributions and packaging systems.

## Output and transport

C and C++ save the exact engine stdout response bytes by default under:

```text
~/.local/state/blackbelt/responses/
```

Use `--save FILE` for an explicit output path or `--no-save` to disable the default local save. `blackbelt-2` is the alternate no-save binary.

Optional network transport is controlled with `BBEA_TRANSPORT`. HTTPS and SSH are supported directly; plaintext HTTP, Telnet, and raw TCP require explicit `BBEA_ALLOW_INSECURE=1`. Encrypted authenticated channels are recommended for network output.

## Architecture

```text
                         +----------------------+
                         | Black Belt Web/JSP   |
                         +----------+-----------+
                                    |
                                    v
+----------------+       +----------------------+       +-------------------+
| C CLI          |------>|                      |------>| Ollama / Llama    |
+----------------+       | BBEA Engine Contract |       | BBEA model        |
| C++17 CLI      |------>|                      |       +-------------------+
+----------------+       | JSON audit /        |
| blackbelt-2    |------>| natural language    |
+----------------+       | question modes      |
| Java 21 CLI    |------>|                      |
+----------------+       +----------------------+

Repository location:
modules/black-belt/bin/
```

The existing web module and `sharp` model artifacts remain authoritative. The CLI does not duplicate the model prompt or create a second scoring system. It feeds the existing BBEA contract so the terminal and web interfaces can converge on the same AI evaluation path.
