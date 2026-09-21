#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/sternenfuchs"
BIN="$GAMEDIR/starfox_pc.${DEVICE_ARCH}"

cd "$GAMEDIR"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# control.txt's get_controls() only ever greps ONE hardcoded GUID (an
# unrelated Xbox 360 pad, 030000005e0400008e...) out of the CFW's mapping db
# into $SDL_GAMECONTROLLERCONFIG_FILE ("# TODO: figure out SDL_GAMECONTROLLERCONFIG"
# in control.txt), so that file (/tmp/gamecontrollerdb.txt) never actually
# contains this device's own mapping, and the derived SDL_GAMECONTROLLERCONFIG
# ends up holding that unrelated single line too. Neither the game nor
# gptokeyb (which also inherits SDL_GAMECONTROLLERCONFIG_FILE, and needs it
# to recognize select/start for its own "-1 <app>" exit-kill switch) can
# then see this device as a real gamepad (SDL_IsGamepad/IsGameController
# false). Point both at the CFW's own, complete gamecontrollerdb.txt instead.
export SDL_GAMECONTROLLERCONFIG_FILE="$controlfolder/${CFW_NAME}/gamecontrollerdb.txt"
RG40XX_H_GUID="19000000010000000100000000010000"
rg40xx_mapping="$(grep "^${RG40XX_H_GUID}," "$SDL_GAMECONTROLLERCONFIG_FILE" 2>/dev/null | head -1)"
export SDL_GAMECONTROLLERCONFIG="${rg40xx_mapping:-$sdl_controllerconfig}"
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# SDL3 shim -> CFW's patched SDL2.
if [ -n "${SDL_VIDEODRIVER:-}" ]; then
  export SDL3SHIM_SDL2_VIDEODRIVER="$SDL_VIDEODRIVER"
  export SDL_VIDEODRIVER=sdl2
fi
if [ -n "${SDL_AUDIODRIVER:-}" ]; then
  export SDL3SHIM_SDL2_AUDIODRIVER="$SDL_AUDIODRIVER"
  export SDL_AUDIODRIVER=sdl2
fi
export SDL3SHIM_SDL2_LIB="${SDL3SHIM_SDL2_LIB:-libSDL2-2.0.so.0}"

if [ ! -f "$GAMEDIR/pregame.cfg" ] && [ -f "$GAMEDIR/prototype-pregame.cfg" ]; then
  cp "$GAMEDIR/prototype-pregame.cfg" "$GAMEDIR/pregame.cfg"
fi

if [ ! -f "$GAMEDIR/Starfox-Assets.BIN" ]; then
  for rom in "$GAMEDIR"/*.sfc "$GAMEDIR"/*.smc; do
    if [ -f "$rom" ]; then
      export STARFOX_RETAIL_ROM="$rom"
      break
    fi
  done
fi

$ESUDO chmod +x "$BIN"

# gptokeyb's -c flag takes a *.gptk keymap file ("key = value" lines, for
# custom gamepad->keyboard key remapping) -- not a gamecontrollerdb.txt
# (comma-separated GUID database). The original bootstrap passed the
# latter, which gptokeyb's fscanf-based .gptk parser can't read at all
# (spammed "fscanf(): Invalid argument" on every line). We don't need
# custom keyboard remapping -- the game reads the gamepad natively via
# SDL -- so just drop it; gptokeyb's default mappings plus its built-in
# "-1 <app>" select+start exit-kill switch (which reads SDL_GAMECONTROLLERCONFIG_FILE
# above, not -c) don't need it.
$GPTOKEYB "starfox_pc.${DEVICE_ARCH}" >/dev/null 2>&1 &

pm_platform_helper "$BIN"
"$BIN"

pm_finish
