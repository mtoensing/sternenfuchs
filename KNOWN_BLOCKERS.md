# Known blockers and settled decisions

Only facts already demonstrated by CI or on the real Anbernic RG40XX H
(KNULLI, H700, 4x Cortex-A53, Mali-G31, 1 GB, 640x480) belong here. Anything
reported by someone else, or not yet reproduced here, is labelled as such.

## Graphics

- Vulkan is not part of the Sternenfuchs architecture. The SDL3 shim is
  built with `SDL_VULKAN=OFF`; do not reopen Vulkan (or RT64, Weston/
  WestonPack, custom Mesa, replacement Mali drivers, bundled CFW graphics
  libraries) unless new evidence specifically requires it.
- Runtime path: native aarch64 `starfox_pc` -> SDL3 API -> pinned
  `bmdhacks/SDL` SDL3->SDL2 shim (`libSDL3.so.0`, the only bundled library)
  -> KNULLI/PortMaster's own patched SDL2 (`mali` video driver) -> GLES.
- The upstream "GPU" renderer mode first asks for SDL3's GPU API, which is
  unavailable without Vulkan; the log line
  `SDL GPU unavailable: Unsupported GPU backend; using native renderer fallback`
  is expected. The engine then creates a default SDL_Renderer, which through
  the shim is SDL2's OpenGL ES 2 renderer.
- The game's frame is rasterized on the CPU (Star Fox Enhanced's native
  translation of the original rendering pipeline) and uploaded as an RGBA
  texture each frame (`SDL_UpdateTexture`); GLES does the upload, scaling
  and presentation.
- The shim's window-framebuffer path (`SDL2_CreateWindowFramebuffer`) is an
  unconditional stub, so SDL3's CPU "software" SDL_Renderer can never be
  created on this device. Use the GPU/GLES render path.
- This device's SDL2 has no `dummy` video driver; a diagnostic run over SSH
  must own the real display (`smoke-rg40xx.sh` pauses EmulationStation).

## Performance

- Goal: stable 60 FPS presentation at 640x480 with correct gameplay. Current
  numbers are an intermediate state, not a new target.
- First real-device measurement: ~35 FPS in flight.
- With the committed PGO profile (`pgo-data/`, applied by default in
  `build-arm64.sh`): ~42-44 FPS (three runs), a ~23-30% gain.
- The remaining bottleneck is predominantly single-thread CPU: one core sits
  at ~100% while the other three are largely idle; CPU was at its max
  1512 MHz with no thermal throttling (~60 C).
- Optimize measured hot paths (profile on the device) rather than applying
  random compiler flags. Not acceptable as "fixes": frame skipping, lowering
  the simulation rate, changing gameplay timing, resolution below 640x480,
  overclocking.

## Controller

- PortMaster's `get_controls` on KNULLI only greps one hardcoded, unrelated
  GUID (an Xbox 360 pad) into `/tmp/gamecontrollerdb.txt`, so neither the
  game nor gptokeyb recognized the RG40XX H as a gamepad
  (`gamepad=0`), and gptokeyb's Select+Start exit did not work.
- Fix in `Sternenfuchs.sh`: point `SDL_GAMECONTROLLERCONFIG_FILE` at the
  CFW's complete `$controlfolder/$CFW_NAME/gamecontrollerdb.txt` and export
  this device's line as `SDL_GAMECONTROLLERCONFIG`.
- RG40XX H GUID: `19000000010000000100000000010000`
  (`Anbernic RG40XX-H Controller`, 4 axes, 17 buttons, 1 hat).
- Native SDL gamepad input is used. Do not replace analog controls with
  keyboard emulation; gptokeyb runs only for the Select+Start exit.

## Audio

- On the RG40XX H, audio through the CFW's SDL2/ALSA default works normally.
- Reported by a dArkOS tester (not reproduced on this device): ALSA's
  `default` `dmix`/`dsnoop` plugin failed to create its IPC semaphore, so
  `SDL_OpenAudioDeviceStream` failed and the engine exited before the menu.
- `Sternenfuchs.sh` retries once with SDL2's `dummy` audio driver when the
  first launch fails on that error. Verified on the RG40XX H by forcing an
  invalid audio driver: the retry starts the game silently.
- The dummy driver is a fallback/diagnostic only; audio must work normally.

## Deployment and user data

- The runtime's data directory is its own folder (`SDL_GetBasePath()`):
  `pregame.cfg`, `input-bindings.cfg`, `hud-layout.cfg` and `starfox-ex.srm`
  live next to the binary, with the user's ROM, `Starfox-Assets.BIN` and
  `log.txt`.
- Deployment must never delete user data. `deploy-rg40xx.sh` previously used
  `rsync --delete`, which removed saves and settings on every deploy; it now
  only adds/overwrites packaged files.
- Never commit ROMs, `Starfox-Assets.BIN` or other ROM-derived data.

## ROM

- Supported inputs are exactly the pinned upstream's `retail_variants`
  table (1 MiB, optional 512-byte copier header, CRC-32 match). The
  launcher checks candidates with `check-rom.sh` and skips unsupported
  dumps instead of passing the first `*.sfc`/`*.smc` through.
