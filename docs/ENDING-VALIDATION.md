# Original-game ending fixes — 2026-11-05

Scope: the original Star Fox/Starwing ending and replay after completing it.
The community's separate EX progression report is outside this change.

## Implementation

`patches/0014-fix-original-ending-and-credits-restart.patch` selectively ports
these corrections from [Star Fox Enhanced](https://github.com/kandowontu2/starfox-enhanced):

- [4252643](https://github.com/kandowontu2/starfox-enhanced/commit/4252643d2fd6e174d247d669034eca49672ade03):
  capture the boss gallery's circle/window wipe state and clear the credits'
  BG2 scroll override at the host-owned restart. The stale override caused
  unrelated title tiles to appear after the ending.
- [099cb233](https://github.com/kandowontu2/starfox-enhanced/commit/099cb2339f27c521f4885232bdbe2b8118091228):
  prevent START from entering the cartridge's non-returning restart loop
  inside a suspended native task. The host still receives the original input.
- [ee6e92c6](https://github.com/kandowontu2/starfox-enhanced/commit/ee6e92c60f1fb2a6304831ca1875e1595a9e5c1a):
  use stable source painter ordering, including its wrapping 16-bit comparison,
  for ending objects. Ships must not overwrite foreground score lettering.

The upstream pin, existing ARM64 optimizations, SDL3-to-SDL2 shim, offline RA
evaluator and Hardcore policy remain in place. No server unlock submission is
enabled. The packaging script also now includes the existing ROM placeholder
file, as required by the port's documented installation layout.

## Reproduced failures in the previous code

The new tests were first linked against the unchanged downstream core:

- START held/repeated throughout the credits exceeded the 65C816 instruction
  limit inside a non-returning task.
- After the full ending and restart, title BG2 scroll was **0**, compared with
  **257** for a clean title start. Reaching the intro alone did not prove a
  clean restart.

## Regression coverage

The fixed ARM64 build passes both the credits input test and the full ending
test in the local ARM64 Linux environment, with network disabled. It uses the
user's own runtime asset bundle; no ROM or generated assets are published.

The full test starts at the actual map continuation after Andross, using
fixture scores/boss history for the preceding stages. It exercises the escape,
radio/cameras, all seven stage cards, total/average, all six boss displays,
palette preservation, wipe activity, staff credits and final score. It idles
on the final score for 20,000 source ticks before pressing START, then compares
the restarted title and 120 Space Armada tunnel ticks with a fresh game,
including background pixels at widths 256, 400 and 800. It runs with both
original timing and unlocked 20 Hz logic timing, including a special-route
score marker. This is targeted ending validation, not a complete playthrough.

Local results in both timing configurations: escape tick 976; total 1224;
average 1274; credits 3152; final score 5703; six bosses; 60/61 credit strings.
The repeated-START test returns safely after 2552 source ticks. Painter-order
tests cover depth, stable ties, wrapping comparisons and native-pool preservation.

The same validation helper also passes on the real RG40XX H under KNULLI,
including the 20,000-tick final-score idle in each timing configuration and the
post-ending Armada pixel comparisons. Its reported phase timings, boss counts
and credit-string counts match the local results above.

A separate real-display run uses the normal SDL shim/GLES path and ALSA audio,
starts at CREDITSMAP, displays THE END and accepts START back into the intro.
It completes 8100 presented frames at a reported 60 FPS. Device captures and
logs are kept privately under `device-logs/ending-20261105/`, outside Git.
A second 8400-frame run also skips the restarted intro and captures a clean
title screen after the ending, again reporting 60 FPS with real display/audio.

The existing `heavy` device benchmark (300 measured frames after warm-up) gave
59.75 FPS before the change. Three candidate runs give 59.76, 59.77 and 59.81
FPS, with p95 frame intervals of 17.76–18.74 ms. This is a short regression
check, not a whole-game performance claim. The delivered candidate binary's
SHA-256 is `baf846c1f82c26b70e567aa24d463225384e4481e717b75d6cfda324812bc18f`.

## Reproduction

In the prepared ARM64 build environment, after applying all patches and the
existing RA transforms:

```sh
cmake -S .work/starfox-enhanced -B .work/starfox-build -DSTARFOX_BUILD_TESTS=ON
cmake --build .work/starfox-build -j4 --target starfox_pc starfox_ending_tests starfox_credits_restart_tests
ctest --test-dir .work/starfox-build -R '^starfox_ending_painter_order$' --output-on-failure
bash scripts/validate-ending.sh .work/starfox-build /private/path/Starfox-Assets.BIN
```

The validation helper checks bundle checksums, extracts only original-game
assets into a private temporary directory and deletes them on exit. Tests must
use the asset companion generated by the pinned runtime. The verified candidate
uses Ubuntu 22.04 ARM64, Cortex-A53 flags and LTO, without reusing stale PGO data.
