#!/usr/bin/env bash
# Production PortMaster artifacts must contain neither RA code nor RA menus.
set -euo pipefail
BINARY="${1:?usage: verify-portmaster-runtime.sh RUNTIME_BINARY}"
test -f "$BINARY"
REPORT="$(mktemp)"
trap 'rm -- "$REPORT"' EXIT
nm -C "$BINARY" > "$REPORT"
strings "$BINARY" >> "$REPORT"
if grep -Ei 'retroachievements|rcheevos|hardcore|ra_(username|password|hardcore|account|local_trigger)|rc_(runtime|client|hash)_' "$REPORT"; then
  echo "PortMaster runtime contains RA code or menu text" >&2
  exit 1
fi
echo "PortMaster runtime audit passed: no RA symbols or menu text"
