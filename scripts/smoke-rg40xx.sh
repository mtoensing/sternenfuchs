#!/usr/bin/env bash
set -euo pipefail
HOST="${RG40XX_HOST:-192.168.178.76}"
USER="${RG40XX_USER:-root}"
GAMEDIR="/userdata/roms/ports/sternenfuchs"

ssh "${USER}@${HOST}" bash -s <<'REMOTE'
set -u
GAMEDIR="/userdata/roms/ports/sternenfuchs"
cd "$GAMEDIR" || exit 1

echo "=== target ==="
uname -a
echo "=== binary ==="
file ./starfox_pc.aarch64 2>/dev/null || true
echo "=== deps ==="
LD_LIBRARY_PATH="$GAMEDIR/libs.aarch64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  ldd ./starfox_pc.aarch64 2>&1 || true

if [ ! -f pregame.cfg ] && [ -f prototype-pregame.cfg ]; then
  cp prototype-pregame.cfg pregame.cfg
fi

ROM=""
for f in ./*.sfc ./*.smc; do
  [ -f "$f" ] && ROM="$f" && break
done

if [ ! -f Starfox-Assets.BIN ] && [ -z "$ROM" ]; then
  echo "BLOCKER: copy a supported retail .sfc/.smc ROM into $GAMEDIR"
  exit 2
fi

chmod +x ./starfox_pc.aarch64

export LD_LIBRARY_PATH="$GAMEDIR/libs.aarch64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export SDL3SHIM_SDL2_LIB="${SDL3SHIM_SDL2_LIB:-libSDL2-2.0.so.0}"
[ -n "$ROM" ] && export STARFOX_RETAIL_ROM="$GAMEDIR/${ROM#./}"

# This device's SDL2 build has no "dummy" video driver (only "mali", "x11",
# "windows" are compiled in), so a diagnostic run cannot stay off-screen: it
# must own the real display via the "mali" driver. EmulationStation is still
# rendering in the foreground over SSH, so pause it for the duration and
# always resume it, even on failure/timeout.
ES_PID="$(pgrep -x emulationstation | head -1)"
resume_es() { [ -n "$ES_PID" ] && kill -CONT "$ES_PID" 2>/dev/null || true; }
trap resume_es EXIT
[ -n "$ES_PID" ] && kill -STOP "$ES_PID" 2>/dev/null || true

export SDL3SHIM_SDL2_VIDEODRIVER=mali
export SDL3SHIM_SDL2_AUDIODRIVER=dummy
export SDL_VIDEODRIVER=sdl2
export SDL_AUDIODRIVER=sdl2
export STARFOX_TEST_FRAMES=120
export STARFOX_TEST_SKIP_PREROLL=1
# The pinned bmdhacks/SDL sdl2-backend shim's window-framebuffer path
# (SDL2_CreateWindowFramebuffer) is an unconditional stub that always
# returns unsupported -- the CPU "software" SDL_Renderer can never be
# created through it. Use the shim's GPU/OpenGLES2 render path instead,
# which it does implement; scale/resolution/effects stay unchanged.
export STARFOX_TEST_RENDERER=GPU
export STARFOX_TEST_RENDER_SCALE=1
export STARFOX_TEST_PRESENTATION_FPS=60
export STARFOX_TEST_VSYNC=0
export STARFOX_TRACE_FPS=1

timeout 30 ./starfox_pc.aarch64 > smoke.log 2>&1
rc=$?
cat smoke.log
exit $rc
REMOTE
