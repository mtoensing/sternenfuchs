#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${RG40XX_HOST:-192.168.178.76}"
USER="${RG40XX_USER:-root}"
mkdir -p "$ROOT/device-logs"

for name in log.txt smoke.log; do
  scp "${USER}@${HOST}:/userdata/roms/ports/sternenfuchs/$name" \
      "$ROOT/device-logs/$name" 2>/dev/null || true
done

ls -la "$ROOT/device-logs"
