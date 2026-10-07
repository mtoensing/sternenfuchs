#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROM="${1:-}"

if [[ -z "$ROM" ]]; then
  echo "usage: $0 /absolute/path/to/StarFox.sfc" >&2
  exit 2
fi
if [[ ! -f "$ROM" ]]; then
  echo "ROM not found: $ROM" >&2
  exit 2
fi

bash "$ROOT/scripts/build-rcheevos-arm64.sh"

SRC="$ROOT/.work/rcheevos/src"
LIB="$ROOT/.work/rcheevos/librcheevos.a"
OUT="$ROOT/.work/rcheevos/ra-hash-rom"

c++ -std=c++20 -O2 -Wall -Wextra -Wpedantic \
  -I"$ROOT" -I"$SRC/include" -I"$SRC/src" \
  "$ROOT/ra/game_identity.cpp" \
  "$ROOT/tools/ra_hash_rom.cpp" \
  "$LIB" -lm \
  -o "$OUT"

"$OUT" "$ROM"
