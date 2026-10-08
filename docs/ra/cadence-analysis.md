# RetroAchievements cadence analysis

Tracking issue: https://github.com/mtoensing/sternenfuchs/issues/17

## Question

Should RetroAchievements evaluation run only at the 20 Hz game-logic tick, or once per preserved SNES/video phase (~60 Hz)?

## Relevant runtime structure

The pinned Star Fox Enhanced runtime separates output/presentation FPS from the original cartridge/video cadence.

In `src/app/starfox_pc.cpp`, the runtime advances preserved video phases independently of rendering:

```cpp
for (std::uint32_t phase = 0; phase < raster_batch.video_phases; ++phase) {
    ...
    game.present_frame();
    ...
    if (game.logic_tick_ready()) {
        ...
        const auto tick_result = game.tick(controls);
        ...
    }
}
```

This means:

- arbitrary monitor/display FPS is not a valid RA cadence;
- the preserved cartridge/video phase is the finest deterministic cadence already represented by the runtime;
- the 20 Hz logic tick is coarser and occurs only when `logic_tick_ready()` becomes true.

## Static analysis of the current Star Fox set

Snapshot analyzed: RetroAchievements game 351, 39 core achievements.

Stateful constructs found:

- **24 / 39** definitions use rcheevos delta memory (`d0x...`);
- **3 / 39** contain explicit hit-count syntax;
- **4 / 39** contain reset conditions;
- several use alternative groups / state-dependent multi-frame logic.

This matters because delta semantics compare values across consecutive calls to `rc_runtime_do_frame()`.

If achievement evaluation skips an intermediate WRAM state, the delta history seen by rcheevos is different from the history seen by a normal SNES emulator evaluating every emulated frame.

## Synthetic cadence proof

The ARM64 test suite now uses the real Star Fox achievement:

- #851 — **Crushing the Crusher I**
- definition: `d0xH0015ba=0_0xH0015ba=1_0x 001ff9=21096`

It feeds this controlled sequence for address `0x0015BA`:

```text
phase 0: 0
phase 1: 1
phase 2: 0
```

At preserved phase cadence, the `0 -> 1` transition is visible to rcheevos and the real achievement triggers.

At a simulated 20 Hz observer that samples only the first and last state:

```text
0 --------> 0
      1 is skipped
```

the same trigger is lost.

This proves an important architectural fact:

> Evaluating only at 20 Hz is not generically equivalent to evaluating at the preserved SNES/video cadence for the existing Star Fox achievement definitions.

It does **not yet prove** that real Star Fox gameplay produces a one-video-phase transient on `0x0015BA` or another RA-referenced address. That final empirical confirmation still requires live runtime/ROM tracing.

## Recommended integration hook

For the offline/runtime integration, the safest deterministic hook is:

```text
for each preserved video phase:
    game.present_frame()
    evaluate RetroAchievements memory
    if logic_tick_ready():
        game.tick(...)
```

In practice the RA call should be placed once per preserved cartridge/video phase, immediately after `game.present_frame()` and after any same-phase host code that intentionally mutates SNES-visible state, but before moving to the next preserved phase.

Do **not** call RA once per rendered host frame.

Do **not** call RA multiple times for interpolation-only frames.

## Why this recommendation is conservative

A preserved-phase observer can see every state a 20 Hz observer sees, plus intermediate deterministic cartridge/video states.

A 20 Hz observer cannot reconstruct states it skipped.

For rcheevos delta, reset and hit-count logic, skipped states can alter semantics.

Therefore the preserved video-phase cadence is the lower-risk default unless real-gameplay tracing proves all 39 current definitions are 20 Hz-safe.

## Remaining live validation

Issue #17 should remain open until a real ROM/runtime trace answers:

1. Do any of the 28 RA-referenced addresses change between 20 Hz logic ticks?
2. Do any such values transition through achievement-significant states for only one or two video phases?
3. Does evaluating at the recommended phase hook match a known-good SNES RA client/core?

The synthetic test has already established that this distinction can affect real Star Fox definitions.

## Current engineering decision

For implementation planning:

**Use the preserved SNES/video phase cadence (~60 Hz), not the 20 Hz logic cadence and not arbitrary presentation FPS.**

Treat this as the working architecture decision. The remaining live test is validation of that conservative choice, not a reason to design around 20 Hz first.
