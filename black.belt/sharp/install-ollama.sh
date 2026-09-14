#!/bin/bash
# Ollama Installation & Model Pull Script
# Installs Ollama LLM runtime and pulls the Llama 3.1 base for fine-tuning.
# Requires: Linux x86_64, curl, sudo

set -euo pipefail

echo "── Installing Ollama ──────────────────────────────────────────"
curl -fsSL https://ollama.com/install.sh | sh

echo "── Verifying installation ─────────────────────────────────────"
ollama --version

echo "── Pulling Llama 3.1 8B (base model for fine-tuning) ─────────"
ollama pull llama3.1:8b

echo "── Pulling Llama 3.1 70B (production auditor model) ──────────"
ollama pull llama3.1:70b

echo "── Creating Modelfile for Black Belt Ethical Auditor ──────────"
cat > /tmp/Modelfile.bbea <<'EOF'
FROM llama3.1:8b

PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER num_ctx 4096

SYSTEM """
You are "Black Belt Ethical Auditor" (BBEA), a fine-tuned Llama model that
evaluates martial-arts and combatives practitioners on conduct, ethics, and
legal alignment within the United States.

You accept structured JSON input describing a practitioner's style, rank,
conduct observations, and ethical responses.  You produce a single JSON
audit report covering: legitimacy, ethical risk, legal alignment, conduct
score, risk rating, closure status, and signature block.

Your tone is corporate-ethical, precise, and audit-ready.  You do not
provide legal advice, medical diagnoses, or promote discrimination.
"""
EOF

ollama create bbea -f /tmp/Modelfile.bbea

echo "── Done. Run with: ollama run bbea ────────────────────────────"
echo "── Or serve via API: ollama serve & curl localhost:11434 ───────"
