# Performance work on the RG40XX-H (KNULLI, H700)

Everything below was measured on the real device (Anbernic RG40XX-H, KNULLI,
4x Cortex-A53 @ 1512 MHz, 1 GB, 640x480, real ALSA/PipeWire audio, 60 FPS
pacing, no thermal throttling). Numbers come from `scripts/bench-rg40xx.sh`;
raw logs are written to `device-logs/bench/` (git-ignored).

## Where the missing FPS went

The earlier in-repo benchmark (59.5 FPS, "render median ~10 ms") measured only
the render half of the frame and started from an idle Corneria state. The
frame loop has two very different frame types:

* every third presented frame also runs the 20 Hz logic tick (65C816
  strategies, object sync) **and** the SPC/DSP audio render, all on the game
  thread, before its normal render;
* the two other frames only render.

On a plain frame the work fits in the 16.7 ms budget and the game sits in the
buffer swap. On a tick frame it did not, so a third of the frames missed the
display refresh. That is what showed up as `p95 ~32 ms` and 49-52 FPS.

Profile of the game thread on the heavy Corneria state (device settings:
RTX lighting + HDR + FPS overlay on), before any optimization, mean ms per
presented frame unless noted:

| Stage | Before |
| --- | ---: |
| logic tick (per tick frame, ~1/3 of frames) | 7.7 |
| audio SPC/DSP render (per tick frame) | 4.5 |
| background (`BackgroundRenderer::draw_bg2` dominates) | 6.2 |
| world / software rasterizer | 1.1 (p95 3) |
| layer composition | 1.0 |
| indexed -> RGBA expand | 0.25 |
| CPU presentation effects (RTX lighting, HDR, colour math) | 4.5 |
| `SDL_UpdateTexture` | 0.3-0.4 |
| `SDL_RenderTexture` | 0.01 |
| `SDL_RenderPresent` | blocks on the 60 Hz buffer swap (`FBIOPAN_DISPLAY`) |

* The **world rasterizer is not the bottleneck**: ~1 ms/frame (6-9% of
  game-thread CPU). The row-banded raster-command replay described in the task
  would save at most that ~1 ms, so it was *not* implemented (see below).
* One core sat at ~90%, the others mostly idle; the workers that exist
  (`RowWorkers`) were only used for a few presentation passes.
* CPU frequency stayed at 1512 MHz. `SDL_UpdateTexture` + expand are ~0.65 ms
  together; the swap wait is inherent to the 60 Hz fbdev display and is idle
  time, not work.
* `pregame.cfg` on the test device had RTX lighting, HDR effect and the FPS
  overlay **on** (the packaged `prototype-pregame.cfg` has them off). Those add
  ~4.5 ms/frame of CPU presentation work, and a loaded save state restores its
  own saved settings, so a benchmark state must be saved under the settings it
  is meant to measure (`heavy` = device settings, `heavy_pkg` = packaged).

## What changed (patches/0003 - 0012, in order)

Each step is a separate commit; every optimization is verified byte-identical
against the serial reference (next section).

| Patch | Change | Effect on `heavy` |
| --- | --- | --- |
| 0003 | Per-stage profiler (`STARFOX_TRACE_PROFILE`), thread/core/frequency report, PC sampler, per-second series | measurement only |
| 0004 | Mode 2 BG2 background rendered in row bands on `RowWorkers` | bg 6.2 -> ~4 ms |
| 0005 | SPC/DSP audio render on a worker thread; APU ports handed to the cartridge right before the next tick; `STARFOX_TRACE_FRAME_HASH` | audio leaves the game thread |
| 0006 | Object-record sync between object pool and 65C816 RAM done as bulk pack/unpack + block copy (it ran per strategy call, byte by byte, over every object) | tick 7.7 -> 4.9 ms |
| 0007 | Self-balancing BG2 bands, parallel HDR pass, shift/mask tile addressing | bg2 3.6 -> 2.4 ms |
| 0008 | NEON layer composite and HDR curve | composite 1.0 -> 0.65, HDR 1.2 -> 0.35 ms |
| 0009 | `RowWorkers` claims bands from a shared counter (all passes self-balance, late workers not waited for); table-driven parallel colour math | RTX 1.6 -> 1.45 ms, colour math 0.5 -> 0.17 ms |
| 0010 | Bulk unpack of the extended object record | tick 4.9 -> 4.4 ms |
| 0011 | Direct-row fast path for the common BG2 configuration | bg2 2.7 -> 1.8 ms |
| 0012 | Dump PGO counters before shutdown (instrumented runs used to lose their profile) | tooling |

## Correctness: byte-exact against the serial reference

`scripts/verify-matrix.sh` runs each state unpaced (deterministic: the
simulation advances per presented frame) in a *serial reference* configuration
(`STARFOX_RENDER_THREADS=1 STARFOX_SYNC_AUDIO=1 STARFOX_NO_SIMD=1`, twice) and
in the normal threaded/NEON configuration (twice), and compares a digest of

* the indexed framebuffer **and its layer tags** for every frame,
* the presented RGBA frame for every frame (after all CPU passes),
* the audio stream (CRC of every 50 ms tick).

States: Corneria flight with fire held and a steering sweep (explosions, enemy
waves, HUD, shadows, clipping), a light state, a cold start through the intro,
title, menus, level-launch wipe and first flight (transitions, palette fades,
text, sprites). Result for every state: video, RGBA and audio digests are
identical between the serial reference and the threaded build, and identical
run to run. `STARFOX_VERIFY_PARALLEL=1` additionally renders every BG2 pass
serially and in bands from the same start and compares the bytes in-process
(0 mismatches over 339 draws). The colour-math lookup table was checked
exhaustively against the original expression (32768 cases, 0 mismatches).
The live FPS readout is left out of digest runs (it differs run to run by
design).

## Benchmark states

`scripts/bench-rg40xx.sh make-state NAME SAVE_FRAME` plays Corneria with
scripted input (fire held, steering sweep, a bomb every 300 frames) and saves a
state; `run NAME` loads it and replays the same input. Timing is wall-clock
paced exactly like real play (game speed never changes; slow frames are
dropped, not slowed). Two effects of loading a state matter: the first ~100
frames after a load contain a ~110 ms hitch (excluded by the 150-frame
warm-up), and a state carries its own settings.

* `heavy` - Corneria, saved at frame 4700, device settings (RTX + HDR on).
* `heavy_pkg` - same scene saved with the packaged defaults.
* `w1800` - denser section (world up to 4.7 ms p95), device settings.

## Results

Frame interval statistics over 900 presented frames, 3 runs each, real audio,
paced (the FPS column is the mean of the runs).

| Version | State | FPS avg | p95 frame | p99 frame | Notes |
| --- | --- | ---: | ---: | ---: | --- |
| profiling build (0003) | heavy | 50.9 | 32.3 ms | 35.6 ms | tick frames miss the refresh |
| profiling build (0003) | heavy_pkg | 59.5 | 24.5 ms | 27.8 ms | |
| profiling build (0003) | w1800 | 49.8 | 32.7 ms | 34.6 ms | |
| + BG2 bands, async audio (0004-0005) | heavy | 57.2 | 26.3 ms | ~31 ms | |
| + bulk object sync (0006) | heavy | 58.3 | 21.7 ms | 27 ms | |
| + NEON, balanced workers (0007-0009) | heavy | 59.6 | 18.8 ms | 21 ms | |
| + object sync, BG2 fast path (0010-0011) | heavy | 59.7 | 17.3 ms | 19.8 ms | |
| + object sync, BG2 fast path (0010-0011) | heavy_pkg | 59.8 | 17.2 ms | 18.7 ms | |
| + object sync, BG2 fast path (0010-0011) | w1800 | 59.7 | 18.0 ms | 19.7 ms | |
| final (PGO retrained) | see below | | | | |

The 32-45 FPS reported from hand play was not reproduced by any scripted
state; the scripted heavy states reproduce the same mechanism (tick frames
missing the refresh, ~50 FPS) and the fix removes it.

## Multicore investigation: rasterizer

The task's preferred design (deterministic ordered command stream, workers
replay it for disjoint row ranges) fits the existing `RasterCommands` /
`replay_raster_commands` infrastructure, but the profile does not justify it:
the world rasterizer costs ~1.1 ms/frame on average (up to ~4.7 ms p95 in the
densest section), i.e. at most ~1 ms could be recovered against ~16 ms of
budget that is now mostly idle swap wait. Recording and replaying commands
also costs time of its own. The parallel work went where the time was: BG2
(the biggest single consumer), the presentation passes, the audio render and
the object sync.

## Presentation path

Per frame: indexed -> RGBA expand 0.25-0.35 ms, `SDL_UpdateTexture` 0.3-0.5 ms,
`SDL_RenderTexture` ~0.01 ms, `SDL_RenderPresent` blocks on the fbdev
`FBIOPAN_DISPLAY` vsync (idle, not work; `STARFOX_TEST_VSYNC=0` does not change
this). ~0.7 ms of copy/convert per frame is not worth an alternative upload
path (a palette texture would need shaders the GLES renderer path does not
expose). VSync/swap blocking is reported as `profile-present-blocking`.

## Upstream (kandowontu2/starfox-enhanced)

27 commits ahead of the pinned `6612cb05`; the source changes are visual
enhancements (backdrops, environment effects, FSR, touch overlay) and release
CI. The only performance items are GPU-path model upload scratch reuse and
`SDL_DelayPrecise` for the pacer, neither of which touches this
CPU-raster/GLES path (the pacer sleeps ~0 ms here; frames are paced by the
swap). Nothing was ported.

## Tools

* `scripts/dev-build.sh` - incremental aarch64 build in Docker (same flags/PGO
  as CI); `dev-export-patches.sh` turns commits in `.work/starfox-enhanced`
  into `patches/`.
* `scripts/bench-rg40xx.sh make-state|run|verify|explore`, `verify-matrix.sh`.
* `scripts/pgo-collect.sh` - retrain `pgo-data/` on the device.
* `scripts/resolve-pc-samples.sh` - game-thread PC samples by phase/symbol
  (`BENCH_PC=1`).
