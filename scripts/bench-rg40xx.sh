#!/usr/bin/env bash
# Repeatable on-device benchmark. Loads a named save state and replays a
# scripted, deterministic input sequence (fire held, steering sweep, periodic
# bombs) for N presented frames, printing the per-stage profile the runtime
# collects (see include/starfox/app/frame_profile.hpp in the patched source).
#
#   bench-rg40xx.sh make-state NAME SAVE_FRAME [PRESS_MODE]
#       Boot, press Start through the menus, play Corneria with PRESS_MODE
#       input (fire = default, none) and save the state at presented frame
#       SAVE_FRAME. States are user data and stay on the device
#       ($GAMEDIR/bench-states/NAME/).
#   bench-rg40xx.sh run NAME [FRAMES] [RUNS]
#       Load state NAME, run FRAMES frames (default 900) RUNS times (default 3).
#   bench-rg40xx.sh verify NAME [FRAMES]
#       Deterministic (unpaced) run printing a digest of every frame and of the
#       audio stream, for byte-exact serial-vs-parallel comparisons.
#   bench-rg40xx.sh explore FRAMES [PRESS_MODE]
#       Boot and play through from the start, printing a per-second series of
#       frame cost. Used to find heavy scenes worth saving as states.
#
# Env: BENCH_EXTRA="VAR=1 ...", BENCH_CFG=device|packaged, BENCH_PC=1 (also collect game-thread PC samples), RG40XX_HOST, RG40XX_USER, BENCH_UNPACED=1 (no 60 FPS pacer),
#      BENCH_VSYNC=1, BENCH_WARMUP (default 150), BENCH_LOG_DIR (local copy).
set -euo pipefail
HOST="${RG40XX_HOST:-192.168.178.76}"
USER="${RG40XX_USER:-root}"
CMD="${1:?usage: bench-rg40xx.sh make-state|run|explore ...}"; shift
LOG_DIR="${BENCH_LOG_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/device-logs/bench}"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOCAL_LOG="$LOG_DIR/$STAMP-$CMD-${1:-}.log"

# ssh joins its arguments into one remote command line, so quote the values.
ssh "${USER}@${HOST}" "CMD=$(printf %q "$CMD") ARGS=$(printf %q "$*")" \
    "BENCH_UNPACED=$(printf %q "${BENCH_UNPACED:-0}") BENCH_VSYNC=$(printf %q "${BENCH_VSYNC:-0}")" \
    "BENCH_WARMUP=$(printf %q "${BENCH_WARMUP:-150}") BENCH_SERIES=$(printf %q "${BENCH_SERIES:-}")" \
    "BENCH_PC=$(printf %q "${BENCH_PC:-}") BENCH_CFG=$(printf %q "${BENCH_CFG:-device}") BENCH_EXTRA=$(printf %q "${BENCH_EXTRA:-}")" \
    bash -s <<'REMOTE' 2>&1 | tee "$LOCAL_LOG"
set -u
GAMEDIR="/userdata/roms/ports/sternenfuchs"
STATES="$GAMEDIR/bench-states"
cd "$GAMEDIR" || exit 1
mkdir -p "$STATES"
set -- $ARGS

ES_PID="$(pgrep -f 'exit-on-reboot-required' | head -1)"
resume_es() { [ -n "$ES_PID" ] && kill -CONT "$ES_PID" 2>/dev/null || true; }
trap resume_es EXIT
[ -n "$ES_PID" ] && kill -STOP "$ES_PID" 2>/dev/null || true

export LD_LIBRARY_PATH="$GAMEDIR/libs.aarch64"
export SDL3SHIM_SDL2_LIB=libSDL2-2.0.so.0 SDL3SHIM_SDL2_VIDEODRIVER=mali
export SDL3SHIM_SDL2_AUDIODRIVER="${BENCH_AUDIO:-alsa}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run}"
export SDL_VIDEODRIVER=sdl2 SDL_AUDIODRIVER=sdl2
export STARFOX_TEST_SKIP_PREROLL=1 STARFOX_TEST_RENDERER=GPU
export STARFOX_TEST_RENDER_SCALE=1 STARFOX_TEST_PRESENTATION_FPS=60
export STARFOX_TEST_VSYNC="$BENCH_VSYNC"
[ "$BENCH_UNPACED" = 1 ] && export STARFOX_TEST_UNPACED=1
export STARFOX_TEST_PRESS_FRAMES=30
# BENCH_EXTRA="NAME=value NAME2=value" adds arbitrary environment variables.
[ -n "$BENCH_EXTRA" ] && export $BENCH_EXTRA
# BENCH_CFG=device (default) keeps whatever pregame.cfg the device has;
# BENCH_CFG=packaged forces the shipped defaults for the expensive presentation
# options (RTX lighting, HDR effect, FPS overlay all off).
if [ "$BENCH_CFG" = packaged ]; then
  export STARFOX_TEST_RTX_LIGHTING=0 STARFOX_TEST_HDR_EFFECT=0 STARFOX_TEST_SHOW_FPS=0
fi

# Start presses walk the menus into Corneria (same as the original state script).
menu_presses() { local p=""; for f in $(seq 90 90 1350); do p="$p${p:+,}$f:4096"; done; echo "$p"; }
# Deterministic play input from frame $1 to $2, in 30-frame steps (the press
# length): B (fire) held; a left/right/up/down sweep; A (bomb) every 300 frames.
# Bit layout: B=32768 Y=16384 Start=4096 Up=2048 Down=1024 Left=512 Right=256 A=128
play_presses() {
  local from=$1 to=$2 mode=${3:-fire} i0=${4:-0} out="" i=${4:-0} f
  [ "$mode" = none ] && return
  local sweep=(512 512 256 256 2048 2048 1024 1024 768 0 256 256 512 512 1280 0)
  for ((f = from; f < to; f += 30)); do
    local m=32768
    m=$((m | ${sweep[$((i % ${#sweep[@]}))]}))
    [ $((i % 10)) -eq 9 ] && m=$((m | 128))
    out="$out${out:+,}$f:$m"; i=$((i + 1))
  done
  echo "$out"
}
join_presses() { echo "$1${2:+,$2}"; }
base_env() {
  STARFOX_TEST_STATE_DIRECTORY="$1"; export STARFOX_TEST_STATE_DIRECTORY
  mkdir -p "$1"
}
one_run() {  # $1 frames; PRESSES/ACTIONS in env
  [ -n "${BENCH_PC:-}" ] && export STARFOX_TRACE_PC=1 STARFOX_TRACE_PC_FILE=/tmp/starfox-pc.txt
  STARFOX_TEST_FRAMES="$1" STARFOX_TRACE_PROFILE=1 \
    STARFOX_TEST_PROFILE_WARMUP="$BENCH_WARMUP" \
    timeout 900 ./starfox.aarch64 2>&1 | grep -E '^(profile-|parallel-verify|audio-frame|frame-hash|state saved|state loaded|render-|starfox_pc failed|.*[Ss]tate)'
}

case "$CMD" in
make-state)
  name=$1 save=$2 mode=${3:-fire}
  base_env "$STATES/$name"; rm -f "$STATES/$name"/*.sfe
  export STARFOX_TEST_PRESSES="$(join_presses "$(menu_presses)" "$(play_presses 1400 "$save" "$mode")")"
  export STARFOX_TEST_STATE_ACTIONS="$save:1"
  echo "$save $mode" > "$STATES/$name/meta"
  one_run $((save + 5))
  ls -l "$STATES/$name"
  ;;
explore)
  frames=$1 mode=${2:-fire}
  base_env "$STATES/_explore"
  export STARFOX_TEST_PRESSES="$(join_presses "$(menu_presses)" "$(play_presses 1400 "$frames" "$mode")")"
  STARFOX_TRACE_PROFILE_SERIES=1 one_run "$frames"
  ;;
run)
  name=$1 frames=${2:-900} runs=${3:-3}
  base_env "$STATES/$name"
  ls "$STATES/$name"/*-0.sfe >/dev/null 2>&1 || { echo "no state $name"; exit 1; }
  for i in $(seq 1 "$runs"); do
    echo "=== run $i ($name, $frames frames, unpaced=$BENCH_UNPACED vsync=$BENCH_VSYNC cfg=$BENCH_CFG rtx=${STARFOX_TEST_RTX_LIGHTING:-cfg})"
    # The state loads at frame 5; input starts afterwards so it is identical
    # every run. Presses are keyed to presented-frame numbers.
    # Continue the sweep at the same phase the state was saved in, so the
    # scene is the one the exploration run passed through.
    read -r save_frame save_mode < "$STATES/$name/meta" 2>/dev/null || { save_frame=1400; save_mode=fire; }
    export STARFOX_TEST_PRESSES="$(play_presses 10 $((frames + BENCH_WARMUP + 10)) "$save_mode" $(( (save_frame - 1400) / 30 )))"
    export STARFOX_TEST_STATE_ACTIONS="5:2"
      [ -n "${BENCH_SERIES:-}" ] && export STARFOX_TRACE_PROFILE_SERIES=1
    one_run $((frames + BENCH_WARMUP))
  done
  ;;
verify)
  # Byte-exact regression check. Unpaced runs advance the simulation per
  # presented frame, so they are deterministic; the printed digest covers the
  # framebuffer of every frame plus the audio stream. Compare digests between
  # builds/settings (BENCH_EXTRA="STARFOX_RENDER_THREADS=1 STARFOX_SYNC_AUDIO=1"
  # is the serial reference).
  name=$1 frames=${2:-600}
  BENCH_WARMUP=60   # fixed: the digest covers every frame, so runs must be the same length
  base_env "$STATES/$name"
  read -r save_frame save_mode < "$STATES/$name/meta" 2>/dev/null || { save_frame=1400; save_mode=fire; }
  export STARFOX_TEST_UNPACED=1 STARFOX_TEST_PRESSES="$(play_presses 10 $((frames + BENCH_WARMUP + 10)) "$save_mode" $(( (save_frame - 1400) / 30 )))"
  export STARFOX_TEST_STATE_ACTIONS="5:2" STARFOX_TRACE_FRAME_HASH=1 STARFOX_TEST_AUDIO_SIGNATURES=1
  one_run $((frames + BENCH_WARMUP)) > /tmp/verify.out
  echo "frames hashed: $(grep -c '^frame-hash' /tmp/verify.out)  audio ticks: $(grep -c '^audio-frame' /tmp/verify.out)"
  echo "video digest: $(grep '^frame-hash' /tmp/verify.out | md5sum | cut -c1-16)"
  echo "audio digest: $(grep '^audio-frame' /tmp/verify.out | md5sum | cut -c1-16)"
  ;;
*) echo "unknown command $CMD"; exit 1 ;;
esac
REMOTE
if [ -n "${BENCH_PC:-}" ]; then
  scp -q "${USER}@${HOST}:/tmp/starfox-pc.txt" "${LOCAL_LOG%.log}.pc"
  echo "pc samples: ${LOCAL_LOG%.log}.pc (resolve with scripts/resolve-pc-samples.sh)"
fi
echo "log: $LOCAL_LOG"
