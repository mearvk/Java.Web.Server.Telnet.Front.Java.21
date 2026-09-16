CXX ?= g++
CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
CXXFLAGS ?= -O2 -Wall -Wextra -std=c++17
JAVAC ?= javac
PREFIX ?= /bin
OLLAMA ?= ollama
MODEL_CONFIG ?= .blackbelt-model
DEFAULT_MODEL ?= llama3.2:latest
SAVE_DIR ?= $(HOME)/.local/state/blackbelt/responses

.PHONY: all c cpp java clean install models select-model doctor config show-config run run-c run-cpp run-java save-help transport-help

all: c cpp java

c: blackbelt-c
cpp: blackbelt-cpp
java: BlackBeltCLI.class

blackbelt-c: blackbelt-c.c
	$(CC) $(CFLAGS) -o $@ $<

blackbelt-cpp: blackbelt.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

BlackBeltCLI.class: BlackBeltCLI.java
	$(JAVAC) --release 21 -d . $<

models:
	@command -v $(OLLAMA) >/dev/null 2>&1 || { echo "Ollama not found in PATH."; exit 2; }
	@echo "Available Ollama models:"
	@$(OLLAMA) list

select-model:
	@command -v $(OLLAMA) >/dev/null 2>&1 || { echo "Ollama not found in PATH."; exit 2; }
	@tmp=$$(mktemp); trap 'rm -f "$$tmp"' EXIT; \
	$(OLLAMA) list | awk 'NR > 1 {print $$1}' > "$$tmp"; \
	if [ ! -s "$$tmp" ]; then echo "No Ollama models are installed."; exit 3; fi; \
	printf '\nSelect a Black Belt model:\n'; \
	n=1; while IFS= read -r model; do printf '  %s) %s\n' "$$n" "$$model"; n=$$((n+1)); done < "$$tmp"; \
	printf 'Choice [1]: '; read choice; choice=$${choice:-1}; \
	model=$$(sed -n "$${choice}p" "$$tmp"); \
	if [ -z "$$model" ]; then echo "Invalid model selection."; exit 4; fi; \
	printf '%s\n' "$$model" > "$(MODEL_CONFIG)"; \
	echo "Selected Black Belt model: $$model"; \
	echo "Saved to $(MODEL_CONFIG)."

config:
	@if [ ! -f "$(MODEL_CONFIG)" ]; then printf '%s\n' "$(DEFAULT_MODEL)" > "$(MODEL_CONFIG)"; echo "Initialized $(MODEL_CONFIG) with $(DEFAULT_MODEL)."; fi
	@echo "Model: $$(cat $(MODEL_CONFIG))"

show-config: config
	@echo "BBEA_MODEL override: $${BBEA_MODEL:-<not set>}"
	@echo "Engine URL: $${BBEA_ENGINE_URL:-http://127.0.0.1:11434/api/generate}"
	@echo "Prompt: $${BBEA_SYSTEM_PROMPT:-black.belt/sharp/system.prompt}"
	@echo "Response directory: $${BBEA_SAVE_DIR:-$(SAVE_DIR)}"
	@echo "Network transport: $${BBEA_TRANSPORT:-<disabled>}"

# Validate Ollama connectivity and verify that the selected model exists.
doctor: config
	@command -v $(OLLAMA) >/dev/null 2>&1 || { echo "FAIL: Ollama executable not found."; exit 2; }
	@model="$${BBEA_MODEL:-$$(cat $(MODEL_CONFIG))}"; \
	echo "Checking Ollama model: $$model"; \
	$(OLLAMA) show "$$model" >/dev/null 2>&1 || { echo "FAIL: model '$$model' is not installed."; echo "Run 'make models' or 'make select-model'."; exit 3; }; \
	echo "OK: Ollama model '$$model' is available."; \
	curl --fail --silent --show-error "$${BBEA_ENGINE_URL:-http://127.0.0.1:11434/api/tags}" >/dev/null || { echo "FAIL: Ollama HTTP endpoint is unavailable."; exit 4; }; \
	echo "OK: Ollama HTTP endpoint is reachable."

save-help:
	@echo "Local responses are saved by default to: $(SAVE_DIR)"
	@echo "Override with BBEA_SAVE_DIR=/path or disable with BBEA_NO_SAVE=1."
	@echo "A specific output file can be selected with --save FILE."

transport-help:
	@echo "BBEA_TRANSPORT examples:"
	@echo "  https://host.example/upload     HTTPS"
	@echo "  ssh://user@host/path            SSH/SFTP-style destination"
	@echo "  telnet://host:23                Telnet (plaintext; discouraged)"
	@echo "  raw://host:9000                 Raw TCP (plaintext; discouraged)"
	@echo "Network output should use HTTPS, SSH, or another authenticated encrypted channel."
	@echo "For public-key protection use an RSA-2048+ or equivalent recipient key with the transport layer."

run: all
	@./blackbelt-c

run-c: blackbelt-c
	@./blackbelt-c

run-cpp: blackbelt-cpp
	@./blackbelt-cpp

run-java: BlackBeltCLI.class
	@java BlackBeltCLI

install: all
	install -Dm755 blackbelt-c $(DESTDIR)$(PREFIX)/blackbelt-c
	install -Dm755 blackbelt-cpp $(DESTDIR)$(PREFIX)/blackbelt-cpp
	install -Dm755 blackbelt-engine.sh $(DESTDIR)$(PREFIX)/blackbelt-engine.sh
	install -Dm644 BlackBeltCLI.class $(DESTDIR)$(PREFIX)/BlackBeltCLI.class
	install -Dm644 BlackBeltCLI.java $(DESTDIR)$(PREFIX)/BlackBeltCLI.java
	install -Dm644 ../black.belt/sharp/system.prompt $(DESTDIR)/usr/share/blackbelt/sharp/system.prompt

clean:
	rm -f blackbelt-c blackbelt-cpp BlackBeltCLI.class
