#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/versions.sh"

WORK="$ROOT/.work"
PREFIX="$WORK/prefix"
SRC="$WORK/starfox-enhanced"
SDL="$WORK/SDL"
SPIRV="$WORK/SPIRV-Cross"
BUILD="$WORK/starfox-build"
DIST="$ROOT/dist"

rm -rf "$WORK" "$DIST"
mkdir -p "$PREFIX" "$DIST/sternenfuchs/libs.aarch64" "$DIST/sternenfuchs/licenses"

git clone "$STARFOX_REPO" "$SRC"
git -C "$SRC" checkout "$STARFOX_COMMIT"

git clone "$SDL_SHIM_REPO" "$SDL"
git -C "$SDL" checkout "$SDL_SHIM_COMMIT"

git clone --depth 1 "$SPIRV_CROSS_REPO" "$SPIRV"

cmake -S "$SDL" -B "$SDL/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_C_FLAGS="-march=armv8-a" \
  -DSDL_SDL2_BACKEND=ON \
  -DSDL_SPIRV_CROSS_DIR="$SPIRV" \
  -DSDL_X11=OFF -DSDL_WAYLAND=OFF -DSDL_KMSDRM=OFF \
  -DSDL_PIPEWIRE=OFF -DSDL_PULSEAUDIO=OFF -DSDL_ALSA=OFF \
  -DSDL_SNDIO=OFF -DSDL_OSS=OFF -DSDL_JACK=OFF \
  -DSDL_OFFSCREEN=OFF -DSDL_DUMMYVIDEO=OFF \
  -DSDL_DUMMYAUDIO=OFF -DSDL_DISKAUDIO=OFF \
  -DSDL_VULKAN=OFF -DSDL_GPU=ON -DSDL_RENDER_GPU=ON \
  -DSDL_UNIX_CONSOLE_BUILD=ON \
  -DSDL_SHARED=ON -DSDL_STATIC=OFF
cmake --build "$SDL/build" -j"$(nproc)"
cmake --install "$SDL/build"

git -C "$SRC" apply "$ROOT/patches/0001-system-sdl3.patch"

cmake -S "$SRC" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DSTARFOX_USE_SYSTEM_SDL3=ON \
  -DSTARFOX_BUILD_RUNTIME=ON \
  -DSTARFOX_BUILD_TESTS=OFF \
  -DSTARFOX_BUILD_TOOLS=OFF \
  -DSTARFOX_ENABLE_XBRZ=OFF \
  -DSTARFOX_PACKAGE_MSU1_MUSIC=OFF
cmake --build "$BUILD" -j"$(nproc)" --target starfox_pc

cp "$BUILD/starfox_pc" "$DIST/sternenfuchs/starfox_pc.aarch64"

SDL_SO="$(find "$PREFIX" -type f -name 'libSDL3.so.0*' | head -1)"
test -n "$SDL_SO"
cp "$SDL_SO" "$DIST/sternenfuchs/libs.aarch64/libSDL3.so.0"

cp "$ROOT/portmaster/sternenfuchs/Sternenfuchs.sh" "$DIST/Sternenfuchs.sh"
cp "$ROOT/portmaster/sternenfuchs/port.json" "$DIST/port.json"
cp "$ROOT/portmaster/sternenfuchs/README.md" "$DIST/README.md"
cp "$ROOT/portmaster/sternenfuchs/gameinfo.xml" "$DIST/gameinfo.xml"
cp "$ROOT/portmaster/sternenfuchs/prototype-pregame.cfg" "$DIST/sternenfuchs/prototype-pregame.cfg"

cat > "$DIST/sternenfuchs/licenses/LICENSE.sdl.txt" <<'EOF'
Bundled libSDL3.so.0 is built from bmdhacks/SDL's sdl2-backend fork.
SDL is distributed under the zlib license:
https://github.com/libsdl-org/SDL/blob/main/LICENSE.txt
EOF

file "$DIST/sternenfuchs/starfox_pc.aarch64"
readelf -d "$DIST/sternenfuchs/starfox_pc.aarch64" | grep NEEDED || true

(
  cd "$DIST"
  zip -qr sternenfuchs.zip Sternenfuchs.sh port.json README.md gameinfo.xml sternenfuchs
)
echo "Created: $DIST/sternenfuchs.zip"
