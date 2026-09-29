#!/usr/bin/env bash
# Regenerates pgo-data/ from the current source tree on the real device.
#
#   1. builds an instrumented (non-LTO) binary                (dev-build.sh, PGO=generate)
#   2. runs the benchmark scenarios on the device unpaced, so every run executes
#      the same frames whatever the instrumented speed; the gcov runtime merges
#      the counters of all runs (GCOV_PREFIX keeps them off the read-only rootfs)
#   3. copies the .gcda files back into pgo-data/ (old ones are removed first)
#
# Afterwards rebuild with scripts/dev-build.sh (PGO=use is the default) and
# re-run the benchmarks. Needs the saved states from bench-rg40xx.sh make-state.
# Usage: pgo-collect.sh [--skip-build]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${RG40XX_HOST:-192.168.178.76}"; USER="${RG40XX_USER:-root}"
GAMEDIR=/userdata/roms/ports/sternenfuchs
PGO_REMOTE=/userdata/pgo

if [ "${1:-}" != --skip-build ]; then
  STARFOX_PGO_PHASE=generate "$ROOT/scripts/dev-build.sh" build
fi
scp -q "$ROOT/.work/dev-out/starfox.aarch64" "$USER@$HOST:$GAMEDIR/starfox.pgo"
ssh "$USER@$HOST" "rm -rf $PGO_REMOTE && mkdir -p $PGO_REMOTE"

export BENCH_BINARY=starfox.pgo BENCH_UNPACED=1
export BENCH_EXTRA="GCOV_PREFIX=$PGO_REMOTE GCOV_PREFIX_STRIP=0"
cd "$ROOT"
# Device configuration (RTX lighting, HDR, FPS overlay on) and the packaged
# defaults exercise different presentation paths; cover both, plus a cold start
# through the intro, menus and level launch.
BENCH_CFG=device   scripts/bench-rg40xx.sh run heavy 1500 1
BENCH_CFG=packaged scripts/bench-rg40xx.sh run heavy_pkg 1500 1
BENCH_CFG=device   scripts/bench-rg40xx.sh run w1800 1500 1
BENCH_CFG=device   scripts/bench-rg40xx.sh run light 1200 1
BENCH_CFG=device   scripts/bench-rg40xx.sh verify boot 2400

find "$ROOT/pgo-data" -name '*.gcda' -delete
ssh "$USER@$HOST" "cd $PGO_REMOTE && find . -name '*.gcda' | wc -l"
# Files land under the compile-time absolute profile directory.
ssh "$USER@$HOST" "cd $PGO_REMOTE/__w/sternenfuchs/sternenfuchs/pgo-data && tar cf - ." | tar xf - -C "$ROOT/pgo-data"
echo "collected $(find "$ROOT/pgo-data" -name '*.gcda' | wc -l) profile files"
ssh "$USER@$HOST" "rm -f $GAMEDIR/starfox.pgo"
