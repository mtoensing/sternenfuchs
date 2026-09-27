## Notes

Thanks to KandoWontU for [Star Fox Enhanced](https://github.com/kandowontu/starfox-enhanced),
the open-source native runtime this port packages, and to Team SFEX
(Star Fox EX) and SunlitSpace542 (UltraStarFox) for the community projects it
builds on. Thanks to bmdhacks for the SDL3-to-SDL2 backend shim.

No Nintendo ROM or ROM-derived data is included. Copy your own legally
obtained Star Fox/Starwing `.sfc` or `.smc` ROM (USA, Japan or Europe retail
revision) into `ports/sternenfuchs/`. On first launch the game builds
`Starfox-Assets.BIN` from it.

Expect roughly 30-45 FPS in flight on H700-class devices; game speed stays
correct regardless.

Third-party licenses are in `sternenfuchs/licenses/`; full credits are in
upstream's [CREDITS.md](https://github.com/kandowontu/starfox-enhanced/blob/main/CREDITS.md).

## Controls

Buttons map to the SNES buttons with the same label. The in-game controls
menu can remap them.

| Button | Action |
| ------ | ------ |
| D-PAD / Left stick | SNES D-pad |
| A / B / X / Y | SNES A / B / X / Y |
| L1 / R1 | SNES L / R |
| SELECT | SNES Select |
| START | SNES Start |
| SELECT + START | Quit |
