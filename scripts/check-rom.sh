#!/bin/sh
# Identify a Star Fox/Starwing ROM against the exact revisions the pinned
# Star Fox Enhanced source accepts (retail_variants in src/app/starfox_pc.cpp
# and src/app/asset_builder.cpp at STARFOX_COMMIT in versions.sh): a 1 MiB
# image, optionally preceded by a 512-byte copier header, whose CRC-32
# (IEEE/zlib) matches one of the table entries below. Read-only: the ROM is
# never modified.
#
# Usage: check-rom.sh [ROM]   (or STARFOX_RETAIL_ROM=ROM check-rom.sh)
# Prints "<variant name>" and exits 0 when supported; prints the reason and
# exits 1 when not; exits 2 on usage/tool errors.
#
# POSIX sh + busybox only (it ships inside the PortMaster package): the CRC
# is read from a gzip stream's trailer, which stores the CRC-32 of the
# uncompressed input, so no crc32/python binary is required on the device.

rom="${1:-${STARFOX_RETAIL_ROM:-}}"
if [ -z "$rom" ]; then
  echo "usage: $0 ROM (or set STARFOX_RETAIL_ROM)" >&2
  exit 2
fi
if [ ! -f "$rom" ] || [ ! -r "$rom" ]; then
  echo "cannot read ROM: $rom" >&2
  exit 2
fi
command -v gzip >/dev/null 2>&1 || { echo "gzip not found" >&2; exit 2; }

retail_size=1048576
size="$(wc -c < "$rom" | tr -d ' ')"
case "$size" in
  "$retail_size") skip=0 ;;
  "$((retail_size + 512))") skip=512 ;;
  *)
    echo "unsupported: $rom is $size bytes (expected $retail_size, or $((retail_size + 512)) with a copier header)"
    exit 1
    ;;
esac

# The last 8 bytes of a gzip stream are CRC32 then ISIZE, both little-endian.
crc="$(tail -c "+$((skip + 1))" "$rom" | gzip -1 -c | tail -c 8 | head -c 4 \
  | od -An -tx1 | tr -d ' \n')"
if [ "${#crc}" -ne 8 ]; then
  echo "failed to compute CRC-32 of $rom" >&2
  exit 2
fi
crc="$(printf '%s' "$crc" | sed 's/\(..\)\(..\)\(..\)\(..\)/\4\3\2\1/')"

case "$crc" in
  8fc4e6d0) name="Star Fox (USA) (Rev 2)" ;;
  0bae0941) name="Star Fox (USA)" ;;
  b18676b2) name="Star Fox (USA) (Rev 1)" ;;
  41a60b3f) name="Star Fox (Japan)" ;;
  ad668a41) name="Star Fox (Japan) (Rev 1)" ;;
  865f1a71) name="Starwing (Europe)" ;;
  ba64da2b) name="Starwing (Europe) (Rev 1)" ;;
  b48ca238) name="Starwing (Germany)" ;;
  *)
    echo "unsupported: $rom has CRC-32 $crc, which is not a supported unmodified retail Star Fox/Starwing revision (hacks, betas, competition carts and Star Fox 2 are not supported)"
    exit 1
    ;;
esac

echo "$name"
