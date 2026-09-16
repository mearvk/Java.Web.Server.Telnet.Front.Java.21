#!/usr/bin/env bash
set -euo pipefail

# Save the exact stdout bytes produced by a Black Belt response.
# Network transport is opt-in through BBEA_TRANSPORT.
OUTPUT="${1:?response file required}"

mkdir -p "$(dirname -- "$OUTPUT")"

if [[ "${BBEA_NO_SAVE:-0}" != "1" ]]; then
  cat > "$OUTPUT"
else
  cat >/dev/null
fi

if [[ -n "${BBEA_TRANSPORT:-}" ]]; then
  transport="$BBEA_TRANSPORT"
  case "$transport" in
    https://*|http://*)
      if [[ "$transport" == http://* && "${BBEA_ALLOW_INSECURE:-0}" != "1" ]]; then
        echo "Refusing plaintext HTTP transport; use HTTPS or set BBEA_ALLOW_INSECURE=1." >&2
        exit 8
      fi
      curl --fail-with-body --silent --show-error --data-binary "@$OUTPUT" \
        -H 'Content-Type: application/octet-stream' "$transport" >/dev/null
      ;;
    ssh://*)
      target="${transport#ssh://}"
      hostpart="${target%%/*}"
      remotepath="/${target#*/}"
      if [[ "$target" == "$hostpart" ]]; then
        echo "SSH transport requires ssh://user@host/path." >&2
        exit 9
      fi
      scp -- "$OUTPUT" "${hostpart}:${remotepath}"
      ;;
    telnet://*|raw://*)
      if [[ "${BBEA_ALLOW_INSECURE:-0}" != "1" ]]; then
        echo "Refusing plaintext Telnet/Raw transport; set BBEA_ALLOW_INSECURE=1 explicitly." >&2
        exit 10
      fi
      target="${transport#*://}"
      host="${target%%:*}"
      port="${target##*:}"
      command -v nc >/dev/null 2>&1 || { echo "nc is required for raw/telnet transport." >&2; exit 11; }
      nc "$host" "$port" < "$OUTPUT"
      ;;
    *)
      echo "Unsupported BBEA_TRANSPORT: $transport" >&2
      exit 12
      ;;
  esac
fi
