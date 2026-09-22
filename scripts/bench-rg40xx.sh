#!/usr/bin/env bash
# Repeatable in-flight benchmark on the real device.
#
# Loads a Corneria-flight save state (created once with --make-state from a
# scripted Start-press sequence; the state is ROM/user data and stays on
# the device) and times N presented frames with no input, real audio
# (the CFW's default SDL2 driver) and the packaged pregame.cfg settings.
# Startup cost cancels out: avg frame time = (T(long) - T(short)) / delta.
#
# Usage: bench-rg40xx.sh [--make-state] [runs]
set -euo pipefail
HOST="${RG40XX_HOST:-192.168.178.76}"
USER="${RG40XX_USER:-root}"
MAKE_STATE=0
[ "${1:-}" = "--make-state" ] && { MAKE_STATE=1; shift; }
RUNS="${1:-3}"

ssh "${USER}@${HOST}" MAKE_STATE="$MAKE_STATE" RUNS="$RUNS" BENCH_UNPACED="${BENCH_UNPACED:-0}" bash -s <<'REMOTE'
set -u
GAMEDIR="/userdata/roms/ports/sternenfuchs"
STATES="$GAMEDIR/bench-states"
cd "$GAMEDIR" || exit 1
mkdir -p "$STATES"

ES_PID="$(pgrep -f 'exit-on-reboot-required' | head -1)"
resume_es() { [ -n "$ES_PID" ] && kill -CONT "$ES_PID" 2>/dev/null || true; }
trap resume_es EXIT
[ -n "$ES_PID" ] && kill -STOP "$ES_PID" 2>/dev/null || true

export LD_LIBRARY_PATH="$GAMEDIR/libs.aarch64"
export SDL3SHIM_SDL2_LIB=libSDL2-2.0.so.0 SDL3SHIM_SDL2_VIDEODRIVER=mali
export SDL3SHIM_SDL2_AUDIODRIVER="${BENCH_AUDIO:-alsa}"
# KNULLI routes ALSA through PipeWire; its socket lives here (ES has it set,
# a bare SSH session does not).
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run}"
export SDL_VIDEODRIVER=sdl2 SDL_AUDIODRIVER=sdl2
export STARFOX_TEST_SKIP_PREROLL=1 STARFOX_TEST_RENDERER=GPU
export STARFOX_TEST_RENDER_SCALE=1 STARFOX_TEST_PRESENTATION_FPS=60 STARFOX_TEST_VSYNC=0
export STARFOX_TEST_STATE_DIRECTORY="$STATES"
# BENCH_UNPACED=1 removes the 60 FPS presentation pacer so the result shows
# real headroom (paced runs cap at ~60 and hide improvements).
[ "${BENCH_UNPACED:-0}" = 1 ] && export STARFOX_TEST_UNPACED=1

if [ "$MAKE_STATE" = 1 ]; then
  presses=""; for f in $(seq 90 90 1350); do presses="$presses${presses:+,}$f:4096"; done
  STARFOX_TEST_FRAMES=1720 STARFOX_TEST_PRESSES="$presses" STARFOX_TEST_STATE_ACTIONS=1700:1 \
    timeout 120 ./starfox_pc.aarch64 2>&1 | grep 'state saved' || { echo "state save failed"; exit 1; }
fi
ls "$STATES"/*-0.sfe >/dev/null 2>&1 || { echo "no bench state; run with --make-state"; exit 1; }

run() {  # $1 = frames, $2 = 1 to sample CPU mid-run; prints elapsed ms
  local start end pid
  start=$(date +%s%N)
  STARFOX_TEST_FRAMES="$1" STARFOX_TEST_STATE_ACTIONS=5:2 STARFOX_TRACE_PROFILE=1 \
    STARFOX_TEST_PROFILE_WARMUP=30 STARFOX_TRACE_PROFILE_DISTRIBUTION=1 \
    timeout 120 ./starfox_pc.aarch64 > /tmp/bench.log 2>&1 &
  pid=$!
  if [ "${2:-0}" = 1 ]; then
    sleep 6
    head -5 /proc/stat > /tmp/stat0; sleep 4; head -5 /proc/stat > /tmp/stat1
    top -bn1 -H -p "$(pgrep -f starfox_pc.aarch64 | head -1)" 2>/dev/null \
      | awk 'NR>7 && $9+0 >= 5 {printf "  thread %-16s %s%%\n", $12, $9}' > /tmp/threads.txt
  fi
  wait "$pid"
  end=$(date +%s%N)
  echo $(( (end - start) / 1000000 ))
}
SHORT=150 LONG=1050
for i in $(seq 1 "$RUNS"); do
  ts=$(run $SHORT); tl=$(run $LONG 1)
  grep -q 'render-profile' /tmp/bench.log || { cat /tmp/bench.log; exit 1; }
  awk -v ts="$ts" -v tl="$tl" -v n=$((LONG - SHORT)) \
    'BEGIN { ms=(tl-ts)/n; printf "run %s: avg_frame=%.2fms avg_fps=%.1f\n", "'"$i"'", ms, 1000/ms }'
  grep -E 'render-profile-us|render-distribution-us' /tmp/bench.log | sed 's/ bg-cache.*//'
  paste /tmp/stat0 /tmp/stat1 | awk '$1 ~ /^cpu[0-9]/ {
      b0=$2+$3+$4+$7+$8+$9; t0=b0+$5+$6; b1=$13+$14+$15+$18+$19+$20; t1=b1+$16+$17;
      printf "  %s %.0f%%", $1, 100*(b1-b0)/(t1-t0) } END { print "" }'
  cat /tmp/threads.txt
done
REMOTE
