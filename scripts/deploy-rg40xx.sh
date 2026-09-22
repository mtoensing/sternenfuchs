#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${RG40XX_HOST:-192.168.178.76}"
USER="${RG40XX_USER:-root}"
REMOTE="/userdata/roms/ports"

ZIP="$ROOT/dist/sternenfuchs.zip"
test -f "$ZIP" || { echo "Missing $ZIP"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -q "$ZIP" -d "$TMP"

ssh "${USER}@${HOST}" "mkdir -p '$REMOTE/sternenfuchs'"
# /userdata on KNULLI is a fuseblk mount with fixed ownership (user_id=0,
# group_id=0, default_permissions); rsync's -a tries to chown/chgrp and
# fails there even as root, aborting under set -euo pipefail. Preserve
# perms/times but skip owner/group preservation on this target.
# No --delete: the runtime keeps its user data next to the binary (its
# portable data directory is SDL_GetBasePath()) -- pregame.cfg,
# input-bindings.cfg, hud-layout.cfg, starfox-ex.srm -- alongside the
# user's ROM, Starfox-Assets.BIN and log.txt. Deploy only adds/overwrites
# packaged files; it never removes anything from the device.
rsync -rlptD -v \
  "$TMP/sternenfuchs/" "${USER}@${HOST}:$REMOTE/sternenfuchs/"
scp "$TMP/Sternenfuchs.sh" "${USER}@${HOST}:$REMOTE/Sternenfuchs.sh"
echo "Deployed to $HOST:$REMOTE"
