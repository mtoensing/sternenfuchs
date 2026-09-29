#!/usr/bin/env bash
# Byte-exact serial-vs-parallel regression matrix on the device: for each
# state, runs the serial reference (1 render thread, synchronous audio) twice
# and the threaded configuration twice, printing frame/audio digests. All four
# digests per state must match.
# Usage: verify-matrix.sh [frames] [state...]   (default: 900 heavy heavy_pkg)
cd "$(dirname "${BASH_SOURCE[0]}")/.."
FRAMES="${1:-900}"; shift || true
STATES=("${@:-heavy heavy_pkg}")
[ $# -eq 0 ] && STATES=(heavy heavy_pkg)
for st in "${STATES[@]}"; do
  for X in "STARFOX_RENDER_THREADS=1 STARFOX_SYNC_AUDIO=1" "STARFOX_RENDER_THREADS=1 STARFOX_SYNC_AUDIO=1" "THREADED=1" "THREADED=1"; do
    echo "== $st [$X]"
    BENCH_EXTRA="$X" scripts/bench-rg40xx.sh verify "$st" "$FRAMES" 2>&1 | grep -E "digest|hashed"
  done
done
echo VERIFY-DONE
