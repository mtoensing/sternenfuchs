#!/usr/bin/env bash
# Incremental aarch64 build in a local Docker container (Apple Silicon or an
# arm64 Linux host). Mirrors scripts/build-arm64.sh -- same Ubuntu 22.04
# userland, same compiler flags, same PGO data -- but keeps the SDL shim
# prefix and the game build directory in Docker volumes so an edit/rebuild
# cycle only recompiles what changed. The source tree is .work/starfox-enhanced
# (pinned upstream + patches/*.patch applied); edit it in place, then run
# scripts/dev-export-patches.sh to turn the edits into a patch file.
#
# Usage: dev-build.sh [prepare|build]      (default: build)
#   prepare  fetch upstream + apply patches/*.patch into .work/starfox-enhanced
#   build    compile; result in .work/dev-out/{starfox.aarch64,libs.aarch64/}
# Env: STARFOX_PGO_PHASE=none|use|generate (default: use if pgo-data exists)
#      DEV_SRC=<dir under .work> to build another source tree (e.g. a git
#      worktree of an earlier commit for A/B benchmarks); it gets its own build
#      volume and output directory .work/dev-out-<dir>.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/versions.sh"
CMD="${1:-build}"
DEV_SRC="${DEV_SRC:-starfox-enhanced}"
if [ "$DEV_SRC" = starfox-enhanced ]; then TAG=""; else TAG="-$DEV_SRC"; fi
IMAGE=sternenfuchs-dev:22.04
MOUNT=/__w/sternenfuchs/sternenfuchs   # PGO .gcda names embed this path

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build -t "$IMAGE" - <<'DOCKERFILE'
FROM ubuntu:22.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates git curl cmake ninja-build build-essential python3 \
    zip file binutils pkg-config && rm -rf /var/lib/apt/lists/*
DOCKERFILE
fi

if [ "$CMD" = prepare ]; then
  SRC="$ROOT/.work/starfox-enhanced"
  rm -rf "$SRC"; mkdir -p "$SRC"
  curl -fsSL --retry 5 --retry-delay 10 \
    "https://archive.softwareheritage.org/api/1/vault/flat/swh:1:dir:$STARFOX_SWH_DIR/raw/" \
    | tar xz --strip-components=1 -C "$SRC"
  git -C "$SRC" init -q
  git -C "$SRC" add -A >/dev/null 2>&1
  git -C "$SRC" -c user.name=base -c user.email=base@local commit -qm "upstream $STARFOX_COMMIT"
  git -C "$SRC" tag -f upstream >/dev/null
  for p in "$ROOT"/patches/*.patch; do
    git -C "$SRC" apply "$p"
    git -C "$SRC" add -A >/dev/null 2>&1
    git -C "$SRC" -c user.name=base -c user.email=base@local commit -qm "patch $(basename "$p")"
  done
  git -C "$SRC" tag -f applied >/dev/null
  echo "source ready in $SRC"; exit 0
fi

PGO="${STARFOX_PGO_PHASE:-}"
if [ -z "$PGO" ]; then
  if [ -n "$(find "$ROOT/pgo-data" -name '*.gcda' -print -quit 2>/dev/null)" ]; then PGO=use; else PGO=none; fi
fi

docker run --rm \
  -v "$ROOT":"$MOUNT" \
  -v sternenfuchs-prefix:"$MOUNT/.work/prefix" \
  -v sternenfuchs-build"$TAG":"$MOUNT/.work/starfox-build" \
  -v sternenfuchs-sdlbuild:"$MOUNT/.work/SDL" \
  -e PGO="$PGO" -e DEV_SRC="$DEV_SRC" -e TAG="$TAG" -e SDL_SHIM_REPO="$SDL_SHIM_REPO" -e SDL_SHIM_COMMIT="$SDL_SHIM_COMMIT" \
  -e SPIRV_CROSS_REPO="$SPIRV_CROSS_REPO" \
  -w "$MOUNT" "$IMAGE" bash -euo pipefail -c '
WORK=$PWD/.work; PREFIX=$WORK/prefix; SDL=$WORK/SDL; SPIRV=$WORK/SPIRV-Cross
SRC=$WORK/$DEV_SRC; BUILD=$WORK/starfox-build; OUT=$WORK/dev-out$TAG
PGO_DIR=$PWD/pgo-data
case "$PGO" in
  generate) F="-fprofile-generate=$PGO_DIR -fprofile-update=atomic"; L="-fprofile-generate=$PGO_DIR"; LTO=OFF ;;
  use) F="-fprofile-use=$PGO_DIR -fprofile-correction -Wno-error=coverage-mismatch -Wno-missing-profile"; L="-fprofile-use=$PGO_DIR"; LTO=ON ;;
  *) F=""; L=""; LTO=ON ;;
esac
if [ ! -f "$PREFIX/.shim-$SDL_SHIM_COMMIT" ]; then
  [ -d "$SDL/.git" ] || git clone "$SDL_SHIM_REPO" "$SDL"
  git -C "$SDL" checkout "$SDL_SHIM_COMMIT"
  [ -d "$SPIRV" ] || git clone --depth 1 "$SPIRV_CROSS_REPO" "$SPIRV"
  cmake -S "$SDL" -B "$SDL/build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_C_FLAGS="-march=armv8-a" \
    -DSDL_SDL2_BACKEND=ON -DSDL_SPIRV_CROSS_DIR="$SPIRV" \
    -DSDL_X11=OFF -DSDL_WAYLAND=OFF -DSDL_KMSDRM=OFF \
    -DSDL_PIPEWIRE=OFF -DSDL_PULSEAUDIO=OFF -DSDL_ALSA=OFF \
    -DSDL_SNDIO=OFF -DSDL_OSS=OFF -DSDL_JACK=OFF \
    -DSDL_OFFSCREEN=OFF -DSDL_DUMMYVIDEO=OFF -DSDL_DUMMYAUDIO=OFF -DSDL_DISKAUDIO=OFF \
    -DSDL_VULKAN=OFF -DSDL_GPU=ON -DSDL_RENDER_GPU=ON \
    -DSDL_UNIX_CONSOLE_BUILD=ON -DSDL_SHARED=ON -DSDL_STATIC=OFF
  cmake --build "$SDL/build" -j"$(nproc)"
  cmake --install "$SDL/build"
  touch "$PREFIX/.shim-$SDL_SHIM_COMMIT"
fi
# Reconfigure only when the flags change; otherwise stay incremental.
STAMP="$PGO|$F"
if [ ! -f "$BUILD/.stamp" ] || [ "$(cat "$BUILD/.stamp")" != "$STAMP" ]; then
  cmake -S "$SRC" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_CXX_FLAGS="-mcpu=cortex-a53 $F" -DCMAKE_C_FLAGS="-mcpu=cortex-a53 $F" \
    -DCMAKE_EXE_LINKER_FLAGS="$L" -DCMAKE_INTERPROCEDURAL_OPTIMIZATION="$LTO" \
    -DSTARFOX_USE_SYSTEM_SDL3=ON -DSTARFOX_BUILD_RUNTIME=ON -DSTARFOX_BUILD_TESTS=OFF \
    -DSTARFOX_BUILD_TOOLS=OFF -DSTARFOX_ENABLE_XBRZ=OFF -DSTARFOX_PACKAGE_MSU1_MUSIC=OFF
  echo "$STAMP" > "$BUILD/.stamp"
fi
cmake --build "$BUILD" -j"$(nproc)" --target starfox_pc
mkdir -p "$OUT/libs.aarch64"
cp "$BUILD/starfox_pc" "$OUT/starfox.aarch64"
cp "$(find "$PREFIX" -type f -name "libSDL3.so.0*" | head -1)" "$OUT/libs.aarch64/libSDL3.so.0"
echo "built: $OUT/starfox.aarch64 (PGO=$PGO)"
'
