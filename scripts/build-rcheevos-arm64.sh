#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/versions.sh"

WORK="$ROOT/.work/rcheevos"
SRC="$WORK/src"
OBJ="$WORK/obj"
OUT="$WORK/librcheevos.a"

rm -rf "$WORK"
mkdir -p "$OBJ"

git clone "$RCHEEVOS_REPO" "$SRC"
git -C "$SRC" checkout "$RCHEEVOS_COMMIT"

mapfile -t SOURCES < <(
  find "$SRC/src" "$SRC/src/rcheevos" "$SRC/src/rapi" "$SRC/src/rhash"     -maxdepth 1 -type f -name '*.c' -print   | grep -v '/rc_libretro.c$'   | grep -v '/rc_client_external.c$'   | sort -u
)

if [ "${#SOURCES[@]}" -eq 0 ]; then
  echo "No rcheevos sources found" >&2
  exit 1
fi

CFLAGS=(
  -std=c99
  -O2
  -march=armv8-a
  -DRC_DISABLE_LUA
  -DRC_CLIENT_SUPPORTS_HASH
  -I"$SRC/include"
  -I"$SRC/src"
)

for source in "${SOURCES[@]}"; do
  rel="${source#"$SRC/"}"
  obj="$OBJ/${rel//\//_}.o"
  cc "${CFLAGS[@]}" -c "$source" -o "$obj"
done

ar rcs "$OUT" "$OBJ"/*.o

cat > "$WORK/smoke.c" <<'EOF'
#include <stdio.h>
#include "rc_version.h"
#include "rc_consoles.h"

int main(void) {
  printf("rcheevos=%s console=%s\n",
      rc_version_string(),
      rc_console_name(RC_CONSOLE_SUPER_NINTENDO));
  return 0;
}
EOF

cc -std=c99 -O2 -march=armv8-a   -I"$SRC/include"   "$WORK/smoke.c" "$OUT" -lm -o "$WORK/rcheevos-smoke"

"$WORK/rcheevos-smoke"

cc -std=c99 -O2 -march=armv8-a \
  -I"$SRC/include" -I"$SRC/src" \
  "$ROOT/tests/ra_starfox_runtime_test.c" "$OUT" -lm \
  -o "$WORK/ra-starfox-runtime-test"

"$WORK/ra-starfox-runtime-test"

file "$OUT" "$WORK/rcheevos-smoke" "$WORK/ra-starfox-runtime-test"

echo "Built: $OUT"
echo "Pinned rcheevos: $RCHEEVOS_COMMIT"
