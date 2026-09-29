#!/usr/bin/env bash
# Writes the commits made on top of the `applied` tag (set by dev-build.sh
# prepare after applying patches/*.patch) in
# .work/starfox-enhanced as patches/NNNN-*.patch (git apply-compatible).
# Usage: dev-export-patches.sh <first-number>
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/.work/starfox-enhanced"
base=applied
git -C "$SRC" format-patch --no-stat --no-signature --zero-commit -N \
  --start-number "${1:?first patch number}" -o "$ROOT/patches" "$base"..HEAD
