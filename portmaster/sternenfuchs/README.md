## Sternenfuchs

ARM64/PortMaster packaging of the open-source [Star Fox Enhanced](https://github.com/kandowontu/starfox-enhanced)
runtime, a fan-made native PC/handheld build of the 1993 SNES Star Fox/Starwing,
built on the Star Fox EX and UltraStarFox community projects. No Nintendo ROM
or ROM-derived runtime data is included in this package.

### ROM

Copy your own legally obtained Star Fox/Starwing `.sfc` or `.smc` ROM into
`ports/sternenfuchs/`. The runtime validates it and builds a local
`Starfox-Assets.BIN` on first launch; neither file is distributed with this
port or leaves the device.

### Status

Tested on an Anbernic RG40XX H (H700, aarch64) running KNULLI at 640x480,
4:3, native OpenGL ES rendering (the CPU/software renderer path is not
reachable through the bundled SDL3-to-SDL2 shim on this device -- see
`Technical notes` below). Menu, native gamepad input, audio, and gameplay are
confirmed working. Performance is CPU-bound single-core SNES CPU+PPU
emulation, not GPU-bound, so expect roughly 30-45 FPS in flight on this
reference hardware rather than a locked 60; presentation and simulation speed
are decoupled, so game speed itself stays correct regardless.

This has only been directly verified on the one device above. **We're looking
for testers** on ArkOS, AmberELEC, muOS, dArkOS, and ROCKNIX (especially
across its Panfrost/Libmali/Adreno GPU driver variants) -- please open an
issue with what you find, working or not. See `Technical notes` for a couple
of device-specific issues this package already had to work around on KNULLI,
and for a fallback this port takes if your CFW's default audio device fails
to open.

### Controls

The game reads the gamepad natively via SDL (no keyboard-remap layer); it
uses the original SNES joypad face-button layout. Use the in-game controls
menu to review/remap bindings.

| Button | Action |
|--|--|
| Select + Start | Quit to the frontend |

### Technical notes

For other porters hitting similar issues on Mali/`mali-fbdev`-style SDL2
targets:

- The pinned `bmdhacks/SDL` sdl2-backend shim's window-framebuffer path
  (`SDL2_CreateWindowFramebuffer`) is an unconditional stub that always
  returns unsupported, so an SDL3 app's CPU/software `SDL_Renderer` can
  never be created through it -- use the GPU/OpenGLES2 render path instead.
- If the CFW's `control.txt`/`get_controls()` only populates
  `SDL_GAMECONTROLLERCONFIG_FILE` with a single unrelated controller's
  mapping (check for a `# TODO: figure out SDL_GAMECONTROLLERCONFIG`-style
  comment), point it at the CFW's own complete `gamecontrollerdb.txt`
  instead -- this also fixes gptokeyb's own select+start exit-kill switch,
  which depends on the same recognition.
- A dArkOS tester hit a fatal `SDL_OpenAudioDeviceStream` failure: ALSA's
  `default` device's `dmix`/`dsnoop` plugin failed to create its IPC
  semaphore in that CFW's sandbox, and the engine treats a failed audio
  open as unrecoverable. `Sternenfuchs.sh` now retries once with audio
  forced off (SDL2's dummy driver) whenever the first launch fails on that
  specific error, so the port stays playable (without sound) instead of
  refusing to start. We don't have that hardware to find the actual
  correct ALSA device string, so this is a fallback, not a real fix --
  reports of *why* the default device fails on your CFW are welcome.

### Credits

- **Original Star Fox / Starwing (1993)**: Nintendo / Argonaut Software.
- **Star Fox EX**: Team SFEX (KandoWontU, Sunlit, and contributors).
- **UltraStarFox**: SunlitSpace542 and contributors.
- **Star Fox Enhanced native runtime**: KandoWontU.
- **SDL3-to-SDL2 backend shim**: bmdhacks.

Full individual credits and third-party library licenses (RetroCPU, snes_spc,
SDL, dr_flac, the Misaki Gothic font, ScaleFX) are in this package's
`sternenfuchs/licenses/` folder and upstream at
[CREDITS.md](https://github.com/kandowontu/starfox-enhanced/blob/main/CREDITS.md)
and [THIRD_PARTY_NOTICES.md](https://github.com/kandowontu/starfox-enhanced/blob/main/THIRD_PARTY_NOTICES.md).

### Porting support

Handheld/PortMaster packaging by [mtoensing](https://github.com/mtoensing).
