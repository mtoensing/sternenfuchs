#!/usr/bin/env bash
# Run the original-game ending regressions with the user's private asset bundle.
# The bundle and extracted ROM never enter the source or distribution folders.
set -euo pipefail
BUILD="${1:?usage: validate-ending.sh BUILD_DIRECTORY Starfox-Assets.BIN}"
BUNDLE="${2:?usage: validate-ending.sh BUILD_DIRECTORY Starfox-Assets.BIN}"
test -x "$BUILD/starfox_ending_tests"
test -x "$BUILD/starfox_credits_restart_tests"
PRIVATE="$(mktemp -d "${TMPDIR:-/tmp}/sternenfuchs-ending.XXXXXXXX")"
trap 'rm -rf "$PRIVATE"' EXIT

python3 - "$BUNDLE" "$PRIVATE" <<'PY'
from pathlib import Path
import struct
import sys
import zlib

bundle = Path(sys.argv[1]).read_bytes()
if not 48 <= len(bundle) <= 64 * 1024 * 1024 or bundle[:8] != b'SFOXAS01':
    raise SystemExit('Unsupported asset bundle')
sizes = struct.unpack_from('<4I', bundle, 12)
checksums = struct.unpack_from('<4I', bundle, 28)
if sum(sizes) + 48 != len(bundle):
    raise SystemExit('Invalid asset bundle size')
if zlib.crc32(bundle[:-4]) != struct.unpack_from('<I', bundle, len(bundle) - 4)[0]:
    raise SystemExit('Asset bundle checksum mismatch')
cursor = 44
for index, size in enumerate(sizes):
    payload = bundle[cursor:cursor + size]
    cursor += size
    if zlib.crc32(payload) != checksums[index]:
        raise SystemExit('Asset payload checksum mismatch')
    if index < 2:
        name = ('original.sfc', 'original-symbols.txt')[index]
        (Path(sys.argv[2]) / name).write_bytes(payload)
PY

"$BUILD/starfox_ending_tests" --painter-order-only
"$BUILD/starfox_credits_restart_tests" "$PRIVATE/original.sfc" "$PRIVATE/original-symbols.txt"
"$BUILD/starfox_ending_tests" "$PRIVATE/original.sfc" "$PRIVATE/original-symbols.txt"
