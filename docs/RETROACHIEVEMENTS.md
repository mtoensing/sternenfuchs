# RetroAchievements integration status

This document is the **single entry point** for RetroAchievements work in Sternenfuchs.

For the next AI with local ROM/device access, use [ra/LOCAL-HANDOFF.md](ra/LOCAL-HANDOFF.md) as the execution checklist.

Final target: **official RetroAchievements Hardcore support for the existing SNES Star Fox achievement set**.

Parent issue: https://github.com/mtoensing/sternenfuchs/issues/6  
Full project plan: [RETROACHIEVEMENTS-HARDCORE-PLAN.md](RETROACHIEVEMENTS-HARDCORE-PLAN.md)

## Current status

The project is still in the **technical compatibility / offline proof** stage.

Confirmed so far:

- rcheevos is pinned to release-line commit `1433173220a7eaede6a9ed7a18e94117be1821e0` (v12.5.0).
- Sternenfuchs' pinned Star Fox Enhanced revision is `6612cb05e4bda0a5e25e8e805d64d0e3db50896a`.
- The pinned upstream exposes read-only SNES state through `MapVm::peek_ram_byte` / `peek_ram_word`, backed by the 65C816 compatibility layer.
- The minimal RetroAchievements WRAM adapter has been implemented and unit-tested.
- The current Star Fox achievement-set snapshot contains **39 achievements** using only **27 unique logical memory addresses**.
- **All 27 addresses are inside standard SNES 128 KiB WRAM.**
- No achievement in the analyzed snapshot currently requires an additional save-RAM, VRAM, CGRAM or hardware-register region.
- Real ROM identification and real-gameplay trigger validation still require access to a user-owned Star Fox ROM.
- The pinned rcheevos runtime activates **39/39** analyzed real Star Fox achievement definitions on ARM64.
- Synthetic-WRAM tests produce correct local trigger events for a single-value achievement (#5158), a delta/prior achievement (#851), and a multi-address achievement (#880).
- `RetroAchievementsBridge` is linked into the actual ARM64 `starfox_pc` runtime and exposes runtime activation, preserved-phase evaluation, bounded byte reads, generic runtime events, measured progress and local trigger callbacks.
- A centralized `HardcorePolicy` is connected to the real runtime.
- Full ARM64 runtime integration is green in CI.
- No server-side unlock submission is enabled.

## Architecture

The intended narrow integration boundary is:

```text
user-owned Star Fox ROM
        |
        +--> rcheevos / rhash
        |       |
        |       +--> RetroAchievements game identity
        |
        +--> existing Sternenfuchs asset generation

starfox_pc
        |
        +--> RetroAchievementsBridge
                |
                +--> read-only MemoryReader
                |       |
                |       +--> MapVm::peek_ram_byte
                |
                +--> rcheevos runtime / rc_client
                |
                +--> HardcorePolicy
                |
                +--> network transport (later)
```

RetroAchievements logic should observe truthful emulated/native state. It should not introduce achievement-specific gameplay hooks.\n\nImplemented modules:

- `ra/retroachievements_bridge.hpp` / `.cpp`
- `ra/hardcore_policy.hpp`
- `ra/ra_memory_adapter.hpp`
- `ra/starfox_achievements.hpp`

The bridge is now wired into `starfox_pc` for **offline-only** evaluation. No login, HTTP transport, public unlock submission or official Hardcore credit is enabled.

## SNES WRAM mapping

rcheevos exposes normal SNES system RAM to achievements as:

```text
RA logical address: 0x000000 .. 0x01FFFF
SNES WRAM address:  0x7E0000 .. 0x7FFFFF
```

The Sternenfuchs adapter therefore maps:

```text
SNES address = 0x7E0000 + RA logical address
```

Implementation:

- `ra/ra_memory_adapter.hpp`
- `tests/ra_memory_adapter_test.cpp`

Boundary tests cover:

- `0x000000 -> 0x7E0000`
- `0x010000 -> 0x7F0000`
- `0x01FFFF -> 0x7FFFFF`
- `0x020000 -> rejected`

The adapter is intentionally **read-only** and uses `peek_ram_byte`, so achievement evaluation cannot mutate gameplay through this interface.

## Star Fox achievement memory inventory

Detailed inventory:

- [ra/starfox-addresses.md](ra/starfox-addresses.md)

Snapshot analyzed:

- RetroAchievements game ID: **351**
- Core achievements: **39**
- Unique logical addresses: **27**
- Addresses inside ordinary WRAM: **27/27**
- Addresses outside ordinary WRAM: **0**

This is currently the strongest positive compatibility signal: the entire analyzed achievement set appears to depend only on the memory region Sternenfuchs already exposes faithfully through the SNES compatibility bridge.

### Some addresses already have useful upstream symbols

The pinned Star Fox Enhanced symbol table provides semantic names for several RA-referenced addresses, including:

| RA address | Upstream symbol |
|---:|---|
| `0x0015AF` | `FIRECNT` |
| `0x0015BA` | `SVAR_BYTE4` |
| `0x0016BD` | `VIEWROTZ` |
| `0x0016BE` | `PXX` |
| `0x0016DB` | `MR14OLD` |

Not every address has an unambiguous symbol yet. Continue semantic mapping only where it improves diagnosis; raw RA address compatibility remains the authoritative requirement.

## rcheevos ARM64 foundation

Pinned in:

- `scripts/versions.sh`

Standalone ARM64 compilation:

- `scripts/build-rcheevos-arm64.sh`

CI:

- `.github/workflows/ra-foundation.yml`

The foundation job is deliberately isolated from the production `starfox_pc` build. Its purpose is to prove that the pinned rcheevos release can be compiled and linked on the same ARM64 / Ubuntu 22.04 class of environment without risking regressions in the existing game build.

The workflow also compiles and runs the WRAM adapter unit test.

Issue:

- https://github.com/mtoensing/sternenfuchs/issues/12

#12 is complete and closed. ARM64 rcheevos and full runtime builds have been observed green.

## Best first real achievement tests

The first live-ROM proof should deliberately use a simple achievement with a small condition set.

Good candidates from the current set include conditions such as:

```text
0xH0015af=5
```

This is preferable to beginning with a route-completion achievement that combines delta/prior state, multiple addresses and stage-transition state.

The desired proof sequence is:

```text
real existing RA definition
        |
        v
rcheevos parses it
        |
        v
RA memory callback reads Sternenfuchs WRAM
        |
        v
gameplay changes the expected byte(s)
        |
        v
rcheevos emits a local trigger event
```

No network submission is required for this proof.

## What can still be proven without a local ROM/device

Before real gameplay is available, the following work can be completed in CI:

1. Parse all 39 current Star Fox achievement definitions with the pinned rcheevos version.
2. Verify that every definition activates successfully in `rc_runtime`.
3. Feed real achievement definitions synthetic WRAM through the same callback shape intended for Sternenfuchs.
4. Prove simple real triggers transition from false to true with synthetic values.
5. Exercise representative delta/prior/hit-count conditions using controlled frame sequences.
6. Use those definitions to identify which achievements are timing-sensitive.
7. Audit the Sternenfuchs runtime for functionality that must be blocked in Hardcore mode.

This is the preferred work before investing in account login, HTTP, overlays or public unlock submission.

## Evaluation cadence: working decision established

Sternenfuchs separates presentation frequency from original gameplay logic.

Relevant runtime flow in the pinned upstream includes:

```cpp
game.present_frame();

if (game.logic_tick_ready()) {
    ...
    const auto tick_result = game.tick(controls);
    ...
}
```

Offline analysis and ARM64 synthetic testing establish a conservative working decision: evaluate once per preserved SNES/video phase (~60 Hz), not only at the 20 Hz logic tick.

The working implementation evaluates once per preserved SNES/video phase.

Do **not** attach achievement evaluation to arbitrary display/render FPS or move it back to 20 Hz logic ticks.

The remaining task is live-ROM validation of this already-selected conservative hook.

Detailed analysis: [ra/cadence-analysis.md](ra/cadence-analysis.md)\n\nLive offline runtime integration: [ra/runtime-integration.md](ra/runtime-integration.md)

Tracking issue:

- https://github.com/mtoensing/sternenfuchs/issues/17 (live-ROM validation still open)

## Hardcore compliance audit

Hardcore is an end goal, not part of the initial compatibility proof.

The current Sternenfuchs/upstream runtime already contains features that will need an explicit centralized Hardcore policy.

Known audit targets include:

- save-state loading;
- frame freeze / frame advance;
- slowdown or altered playback speed;
- host god mode;
- infinite bombs;
- infinite boost;
- infinite lives;
- planet-select or similar gameplay cheats;
- scripted/test input such as `STARFOX_TEST_PRESSES`;
- state-action test hooks;
- diagnostic/direct-entry paths;
- resume/quick-resume semantics.

Examples confirmed in the pinned runtime include:

- `GameSimulation::save_state()` and corresponding load-state paths;
- `set_god_mode(bool)`;
- `infinite_bombs_`;
- `infinite_boost_`;
- `infinite_lives_`;
- direct selected-level support;
- `STARFOX_TEST_PRESSES`;
- `STARFOX_TEST_STATE_ACTIONS`;
- playback speed multiplier support.

The later upstream Planet Select Cheat is **not present in the pinned revision**, so it is not claimed as a pinned-runtime blocker.

Do not scatter individual RA checks around the codebase. Prefer one authoritative policy object/state such as:

```cpp
enum class AchievementMode {
    disabled,
    casual,
    hardcore
};
```

All prohibited runtime actions should consult that policy.\n\nThe isolated policy model is now implemented in `ra/hardcore_policy.hpp`. It defaults to `disabled`, requires a clean session origin before entering Hardcore, forces resumed/diagnostic attempts to Casual, and blocks save/load, cheats, scripted input, direct-stage entry and non-normal playback while Hardcore is active. Fast-forward is deliberately blocked for now until the then-current RA compliance rules are reconfirmed.

Detailed source-level audit: [ra/hardcore-audit.md](ra/hardcore-audit.md)\n\nDetailed implementation belongs to Phase 3 of the project plan.

## Official Hardcore approval is a separate gate

A technically functional client is **not automatically an approved Hardcore client**.

Before public Hardcore unlocks are enabled:

- RetroAchievements' current compliance requirements must be reviewed again;
- Sternenfuchs' eligibility must be discussed with the RetroAchievements team;
- any required minimum public-availability period must be satisfied;
- the client/integration must receive explicit approval;
- only approved builds should submit Hardcore unlocks.

The project must not attempt to bypass RetroAchievements' client approval or game-identity rules.

## Quick-win issue map

### Foundation

- #12 — build rcheevos on ARM64 — **completed**
- #13 — identify a real Star Fox ROM with official rcheevos hashing
- #14 — expose RA logical WRAM through MapVm — **completed**
- #15 — inventory current Star Fox achievement addresses — **completed**
- #16 — verify one real achievement condition against live gameplay
- #17 — determine correct evaluation cadence — **offline proof complete; live validation open**\n- #18 — parse real Star Fox definitions against synthetic WRAM — **completed; ARM64 CI PASS**\n- #19 — audit Hardcore-incompatible runtime features — **completed**

### Larger phases

- #7 — memory compatibility proof
- #8 — offline evaluator and regression tests
- #9 — Hardcore enforcement
- #10 — complete rc_client functionality and PortMaster UX
- #11 — Hardcore compliance/approval

## Recommended next work order

Without ROM/device access:

```text
rcheevos ARM64 CI
        |
        v
parse all 39 real definitions
        |
        v
synthetic-WRAM trigger tests
        |
        v
delta/prior/timing-sensitive tests
        |
        v
Hardcore source audit
```

With ROM/device access:

```text
official ROM identification
        |
        v
trace one simple RA address during gameplay
        |
        v
one real local achievement trigger
        |
        v
confirm evaluation cadence
        |
        v
expand representative test coverage
```

Only after those gates should work move to account authentication, Rich Presence, leaderboards, UI/overlays and network unlock submission.

## Safety / repository constraints

Always follow `AGENTS.md`.

In particular:

- never commit a Star Fox/Starwing ROM;
- never commit `Starfox-Assets.BIN`;
- never commit ROM-derived dumps;
- never commit RetroAchievements credentials or access tokens;
- keep the pinned Star Fox Enhanced revision unless a specific blocker requires changing it;
- preserve existing gameplay, audio, controls, rendering and performance when RA is disabled;
- make changes directly to `main` for this repository;
- do not claim official Hardcore support before RetroAchievements approval.

## Definition of technical compatibility success

Before official integration work begins, the project should be able to answer **yes with evidence** to:

> Can the existing RetroAchievements Star Fox definitions be evaluated correctly against Sternenfuchs using the original game identity and the preserved SNES WRAM state?

The smallest convincing proof is:

1. official ROM identity succeeds;
2. a real existing Star Fox achievement definition is loaded by rcheevos;
3. the definition reads through the Sternenfuchs WRAM adapter;
4. real gameplay produces the expected memory transition;
5. rcheevos emits the expected local trigger;
6. no public unlock is submitted.


## In-game RetroAchievements account menu

The Sternenfuchs ARM64 build now applies `scripts/apply-ra-menu.py` to the pinned Star Fox Enhanced source. CI verifies the transform against the exact pinned upstream revision and a full ARM64 PortMaster runtime build has completed successfully with the transformed menu code.

The desktop/PortMaster setup menu gains:

```text
OPTIONS
  -> RETROACHIEVEMENTS
       USERNAME
       PASSWORD
       HARDCORE
       BACK
```

Username and password can be entered with controller input:

- Left/Right: select character
- A: append character
- Y: delete character
- Start/Select/B: finish editing

The password is displayed only as `********` once set. Account credentials are deliberately session-only and are not added to Star Fox save-state serialization. The raw password is intended only for the future login exchange; when server authentication is implemented, persist a server-issued token rather than the raw password.

The HARDCORE row currently represents the user's requested mode only. Actual Hardcore activation still has to pass the centralized `HardcorePolicy`, perform the required clean reset and later be accepted by the RA client/server integration.

No login request, credential transmission or public unlock occurs yet. Full ARM64 build proof: https://github.com/mtoensing/sternenfuchs/actions/runs/37477740762

## Official SNES game hashing

Issue: https://github.com/mtoensing/sternenfuchs/issues/13

Implemented:

- `ra/game_identity.hpp`
- `ra/game_identity.cpp`
- `tests/ra_game_identity_test.cpp`

The implementation uses rcheevos' official `rc_hash_initialize_iterator` and `rc_hash_generate(..., RC_CONSOLE_SUPER_NINTENDO, ...)` path.

ARM64 CI proves:

- repeated hashing of the same SNES media is deterministic;
- a normal unheadered `.sfc` and the equivalent media with a 512-byte copier header as `.smc` resolve to the **same rcheevos identity**, confirming SNES copier-header normalization;
- missing media fails cleanly;
- no custom production MD5 implementation is used;
- hashing performs no login or unlock submission.

The remaining part of #13 requires a user-owned Star Fox ROM: compute its official hash and prove the corresponding RetroAchievements game identity. No ROM bytes or ROM-derived assets will be committed.

## Isolated RA bridge and Hardcore policy proof

ARM64 CI run:

https://github.com/mtoensing/sternenfuchs/actions/runs/37474269262

Verified components:

- `ra/retroachievements_bridge.cpp`
- `tests/ra_bridge_test.cpp`
- `ra/hardcore_policy.hpp`
- `tests/ra_hardcore_policy_test.cpp`

The bridge test activates a real Star Fox achievement definition through pinned rcheevos, feeds synthetic WRAM through a bounded callback, evaluates a phase and verifies the local trigger callback.

The policy test verifies:

- default mode is disabled;
- Casual mode permits existing functionality;
- resumed/diagnostic sessions cannot enter Hardcore;
- clean-session Hardcore entry succeeds;
- save/load is blocked in Hardcore;
- cheats are blocked in Hardcore;
- scripted/test input is blocked in Hardcore;
- direct-stage entry is blocked in Hardcore;
- slowdown/frame-step/test-super-speed are blocked;
- returning to Casual restores the permissive policy state.

This proves the policy and RA-runtime abstraction can be built and exercised independently of a ROM, device or Mac.

### Still deliberately not implemented

- no ROM hashing result for a user-owned Star Fox ROM yet;
- no authenticated network transport;
- no public unlock submission;
- no claim of official Hardcore support.


## Live ARM64 runtime milestone

Successful full build:

https://github.com/mtoensing/sternenfuchs/actions/runs/37506330247

The real ARM64 PortMaster runtime now contains the offline RA evaluator and the connected Hardcore policy.

Current runtime behavior:

- activates all 39 analyzed Star Fox definitions for the Original experience;
- evaluates them once per preserved SNES/video phase;
- reads only through the bounded MapVm WRAM adapter;
- logs local rcheevos events/triggers;
- enforces the current pinned-runtime Hardcore restrictions;
- keeps network submission disabled.

See [ra/runtime-integration.md](ra/runtime-integration.md) for the exact architecture and remaining gates.
