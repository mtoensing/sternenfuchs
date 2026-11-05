# Current ARM64 PGO profile

Collected on the real RG40XX H on 2026-11-05 for downstream runtime source
`571457ed0aa1922a8809256fd6394efeeab867a0`, including the original-ending fixes
and the existing offline RA integration. Upstream remains pinned to
`6612cb05e4bda0a5e25e8e805d64d0e3db50896a`.

Toolchain: Ubuntu 22.04 ARM64 / GCC 11, Release, `-mcpu=cortex-a53`.
The instrumented build uses atomic counters and no LTO; profile-use builds
enable LTO, matching `scripts/build-arm64.sh`.

The 64 runtime `.gcda` files come from these device runs:

- Existing `heavy` Corneria state: 1800 measured frames plus 150 warm-up frames,
  deterministic unpaced input, real GLES presentation and ALSA audio.
- Cold start, menus and first flight: `bench-rg40xx.sh verify boot 2400`
  (2460 frames including the harness prefix).
- `starfox_credits_restart_tests`: held/repeated START through the complete
  credits and return to a playable front end, using private user assets.

The test executable's own profile is excluded. These files contain compiler
counters, not ROMs, assets, frame dumps or credentials.

Build/training paths must use `/__w/sternenfuchs/sternenfuchs`; GCC embeds the
object paths in profile filenames. Use the production build script with
`STARFOX_PGO_PHASE=generate` and preserve its RA transforms when retraining.
`GCOV_PREFIX` redirects device output into a private collection directory.
Normal production builds automatically use these profiles when present.

GCC 11 reports a generate/use control-flow mismatch for the monolithic `main`
function when switching to LTO, so that function's profile is discarded. The
simulation, rasterizer and other compatible profiles are applied. The existing
coverage-correction build options remain in place; see `PERFORMANCE.md` for
measured gains and validation rather than assuming all profiles were accepted.
