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

# Diagnostic run only: force dummy device backends so SSH does not have to own
# the handheld display. A successful exit proves ARM64/link/assets/runtime bring-up.
export SDL3SHIM_SDL2_VIDEODRIVER=dummy
export SDL3SHIM_SDL2_AUDIODRIVER=dummy
export SDL_VIDEODRIVER=sdl2
export SDL_AUDIODRIVER=sdl2
export STARFOX_TEST_FRAMES=120
export STARFOX_TEST_SKIP_PREROLL=1
export STARFOX_TEST_RENDERER=SOFTWARE
export STARFOX_TEST_RENDER_SCALE=1
export STARFOX_TEST_PRESENTATION_FPS=60
export STARFOX_TEST_VSYNC=0
export STARFOX_TRACE_FPS=1

./starfox_pc.aarch64 > smoke.log 2>&1
rc=$?
cat smoke.log
exit $rc
REMOTE
