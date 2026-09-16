#!/usr/bin/env bash
set -euo pipefail

# Shared Black Belt AI transport. CLI front ends send canonical JSON here.
ENGINE_URL="${BBEA_ENGINE_URL:-http://127.0.0.1:11434/api/generate}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
MODEL_CONFIG="${BBEA_MODEL_CONFIG:-$SCRIPT_DIR/.blackbelt-model}"

if [[ -z "${BBEA_MODEL:-}" && -f "$MODEL_CONFIG" ]]; then
  MODEL="$(head -n 1 "$MODEL_CONFIG")"
else
  MODEL="${BBEA_MODEL:-llama3.2:latest}"
fi

PROMPT_FILE="${BBEA_SYSTEM_PROMPT:-../../../black.belt/sharp/system.prompt}"

if [[ ! -f "$PROMPT_FILE" ]]; then
  PROMPT_FILE="$ROOT/../../black.belt/sharp/system.prompt"
fi

if [[ ! -f "$PROMPT_FILE" && -f "/usr/share/blackbelt/sharp/system.prompt" ]]; then
  PROMPT_FILE="/usr/share/blackbelt/sharp/system.prompt"
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Black Belt system prompt not found: $PROMPT_FILE" >&2
  exit 2
fi

INPUT="$(cat)"
if [[ -z "${INPUT//[[:space:]]/}" ]]; then
  echo "No audit input received." >&2
  exit 2
fi

echo "[Black Belt] model=$MODEL" >&2

python3 - "$PROMPT_FILE" "$MODEL" "$INPUT" <<'PY' | curl --fail-with-body -sS "$ENGINE_URL" -H 'Content-Type: application/json' --data-binary @-
import json, pathlib, sys
prompt_path, model, raw_input = sys.argv[1], sys.argv[2], sys.argv[3]
system_prompt = pathlib.Path(prompt_path).read_text(encoding="utf-8")

try:
    parsed = json.loads(raw_input)
    json_mode = True
except json.JSONDecodeError:
    parsed = raw_input.strip()
    json_mode = False

if json_mode:
    request = {
        "model": model,
        "system": system_prompt,
        "prompt": json.dumps(parsed, ensure_ascii=False, separators=(",", ":")),
        "stream": False,
        "format": "json"
    }
else:
    # Natural-language questions are intentionally not sent through Ollama's
    # JSON-output constraint. The CLI advertises question mode, so the model
    # should receive the question as ordinary text and answer it directly.
    question_system = system_prompt + "\n\nQUESTION MODE\nThe user has entered a natural-language question rather than a structured audit object. Answer the question directly and concisely. Do not manufacture an audit report or JSON object unless the user explicitly asks for one."
    request = {
        "model": model,
        "system": question_system,
        "prompt": parsed,
        "stream": False
    }

print(json.dumps(request, ensure_ascii=False))
PY
