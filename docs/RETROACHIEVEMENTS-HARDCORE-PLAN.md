# RetroAchievements Hardcore Project Plan

Parent issue: https://github.com/mtoensing/sternenfuchs/issues/6

## Final goal

Ship **official RetroAchievements Hardcore support for the existing SNES Star Fox achievement set** in Sternenfuchs.

The goal is not merely to display or locally evaluate achievements. The end state is that a user can sign in with a RetroAchievements account, enable Hardcore, play Sternenfuchs on supported PortMaster hardware, and receive legitimate Hardcore unlocks for the existing Star Fox set without risking an Untracked account.

## Non-negotiable external constraint

RetroAchievements only accepts Hardcore unlocks from approved hardcore-compliant clients. Their current rules also state that decompilations/recompilations/unofficial ports are not eligible for Standalone support.

Therefore the intended route is:

1. prove that Sternenfuchs can evaluate the existing SNES Star Fox set from preserved SNES state;
2. prove Sternenfuchs can enforce all Hardcore restrictions;
3. present the implementation to RetroAchievements as a candidate emulator/client integration using the existing SNES game identity;
4. complete their review/approval process;
5. only then enable real Hardcore submissions.

Do not attempt to bypass the approval process.

## Known baseline

Sternenfuchs pins:

- Star Fox Enhanced: `6612cb05e4bda0a5e25e8e805d64d0e3db50896a`
- SDL3->SDL2 shim: `6057d79baf8321bf190479a699655f06cc2a962f`
- Runtime: `starfox_pc`
- Target: ARM64 PortMaster / KNULLI / RG40XX H
- Build entry: `scripts/build-arm64.sh`

Do not update those pins during bring-up unless a blocker requires it.

## Key findings

### Preserved SNES memory

The pinned upstream has a project-owned 65C816/SNES compatibility layer. `MapVm` exposes read-only access:

```cpp
peek_ram_byte(address)
peek_ram_word(address)
```

backed by `Wdc65816::peek_ram8/peek_ram16`.

This is the preferred RetroAchievements read path.

### RA SNES memory mapping

rcheevos maps logical SNES achievement addresses:

```text
0x000000..0x01FFFF -> SNES WRAM 0x7E0000..0x7FFFFF
```

So the initial adapter should be approximately:

```text
RA address < 0x20000
  -> native SNES address = 0x7E0000 + RA address
  -> MapVm::peek_ram_byte(native SNES address)
```

Only add other regions if the actual Star Fox set uses them.

### Correct evaluation cadence must be proven

The pinned runtime separates presentation FPS from cartridge/video progression and game logic.

A key point in `src/app/starfox_pc.cpp` is:

```cpp
if (game.logic_tick_ready()) {
    ...
    const auto tick_result = game.tick(controls);
    ...
}
```

Do not assume RA should run at render FPS or only at the 20 Hz logic tick. Compare against reference SNES execution and determine whether the achievement set depends on transient 60 Hz WRAM states.

## Milestone 1 — memory compatibility proof

### Goal

Prove that the existing Star Fox RetroAchievements logic can observe the same meaningful SNES state in Sternenfuchs.

### Work

- Pin rcheevos.
- Add official rcheevos ROM hashing.
- Identify the user's original Star Fox ROM through rcheevos.
- Implement a read-only SNES WRAM adapter.
- Obtain the current Star Fox achievement definitions through approved/public RA mechanisms.
- Extract every memory address used by the set.
- Classify all addresses:
  - directly compatible;
  - requires deterministic address mapping;
  - unavailable/incompatible.
- Run representative gameplay traces and compare observed state with a known-correct SNES RA client/core.

### Go/no-go gate

Proceed only if the existing set can be evaluated faithfully without achievement-specific gameplay hooks.

If a material subset of achievements depends on state Sternenfuchs does not preserve, document the exact gap before modifying the game runtime.

## Milestone 2 — offline rcheevos runtime

### Goal

Run the existing achievement logic locally without server-side unlocks.

### Work

- Integrate the rcheevos runtime behind a small `RetroAchievementsBridge`.
- Feed memory only through bounded read-only callbacks.
- Evaluate achievements at the cadence proven in Milestone 1.
- Log:
  - active achievements;
  - trigger progression;
  - measured values;
  - local unlock events.
- Add deterministic tests for representative progression and challenge achievements.
- Keep HTTP submission disabled.

### Exit criteria

Real gameplay produces the same achievement state transitions expected from a supported SNES emulator.

## Milestone 3 — Hardcore enforcement

### Goal

Make a Sternenfuchs Hardcore session incapable of using disallowed functionality.

RetroAchievements currently requires at minimum:

- no save-state loading;
- no rewind;
- no slowdown;
- no frame advance;
- no gameplay-altering cheats;
- no memory editor/debugger/TAS/scripted gameplay;
- switching Casual -> Hardcore requires a full reset;
- Hardcore -> Casual may happen mid-session;
- Rich Presence and leaderboards must remain enabled;
- resumed/quick-resumed sessions must drop to Casual;
- unique client user agent.

### Sternenfuchs audit items

The upstream already contains features that require explicit Hardcore handling:

- save-state creation/loading;
- frame-freeze/frame-step debugging;
- configurable timing/speed paths;
- host god mode;
- infinite bombs/lives;
- scripted/test input paths;
- diagnostic direct-entry/test modes.

Tests and developer tooling can remain in the source tree. They must not be usable to alter a live Hardcore session.

### Required design

Introduce one authoritative runtime state such as:

```cpp
enum class AchievementMode {
    disabled,
    casual,
    hardcore
};
```

All restricted features should query the same policy object instead of duplicating ad-hoc checks.

Hardcore entry must perform a clean game reset and validate that all restricted host-side settings are disabled.

### Automated negative tests

For Hardcore mode, tests must prove:

- load state request -> rejected;
- frame advance request -> rejected;
- slowdown request -> rejected;
- god/infinite-life/bomb toggle -> rejected;
- scripted gameplay input -> unavailable;
- Casual -> Hardcore -> full reset;
- Hardcore -> Casual -> allowed;
- resume from suspended/quick state -> Casual;
- fast-forward remains allowed if implemented consistently with RA rules.

## Milestone 4 — full RA client functionality

### Goal

Meet feature expectations for a real RA client.

Implement through `rc_client` where appropriate:

- authentication;
- game loading/identification;
- achievements;
- measured progress and challenge indicators;
- Rich Presence;
- leaderboards;
- secure offline unlock queue;
- reconnect/sync behavior;
- clear Hardcore/Casual status;
- achievement list accessible from the UI.

Do not build custom equivalents where rcheevos already provides the behavior.

Credentials/tokens must never be committed.

## Milestone 5 — PortMaster UX

### Goal

Make RA usable on the RG40XX H without harming the existing game UX.

Minimum UX:

- sign-in/configuration mechanism suitable for PortMaster;
- obvious Hardcore/Casual indication at game start;
- achievement list accessible with controller input;
- achievement unlock/progress popup;
- network failure is non-fatal to gameplay;
- credentials stored only in writable user config, with appropriate file permissions.

Keep graphical work deliberately small until compliance is proven.

## Milestone 6 — compliance package for RetroAchievements

### Goal

Give RA reviewers an auditable implementation rather than an informal request.

Prepare:

- architecture diagram;
- memory-map proof;
- ROM hashing behavior;
- list of all Hardcore restrictions and test evidence;
- unique user-agent definition;
- save/SRAM format documentation;
- offline queue behavior;
- licensing notices;
- privacy statement if any telemetry/account data is retained;
- release history and first-public-release date;
- test hardware/platform matrix;
- source repository and reproducible build instructions.

Important: current RA rules require an emulator, or its parent emulator, to have been publicly available for at least **six months** before Hardcore approval is considered. Track that eligibility date explicitly.

## Milestone 7 — RA review and test rollout

### Goal

Obtain approval before enabling real Hardcore credit.

Expected sequence:

1. contact RA admins/integration team with the completed technical package;
2. clarify whether Sternenfuchs qualifies as an emulator/client integration despite being a native decompilation-derived runtime;
3. respond to requested changes;
4. participate in integration testing/public testing if requested;
5. receive explicit approval;
6. publish a release with the approved user agent/version and enabled server submissions.

A technically complete implementation is not the same as an approved Hardcore client.

## Milestone 8 — production release

Release only after approval.

Production checklist:

- reproducible ARM64 build;
- no unapproved debug/test functionality accessible in Hardcore;
- no ROM or ROM-derived data in release artifacts;
- exact rcheevos revision recorded;
- client version visible;
- RA server user agent unique;
- offline/online unlock behavior tested;
- Hardcore state unmistakable;
- game reset semantics tested;
- PortMaster package updated;
- documentation updated;
- regression test on real RG40XX H/KNULLI.

## Engineering structure

Prefer a narrow integration boundary:

```text
starfox_pc
   |
   +-- RetroAchievementsBridge
          |
          +-- GameIdentity
          |     +-- rcheevos hash
          |
          +-- MemoryReader
          |     +-- MapVm::peek_ram_byte
          |
          +-- Runtime
          |     +-- rc_client / achievement evaluation
          |
          +-- HardcorePolicy
          |     +-- centrally blocks restricted functionality
          |
          +-- Transport
                +-- added only after offline proof
```

Keep RA logic out of simulation code wherever possible. The simulation should expose truthful state; the RA bridge should observe it.

## Definition of done

The project is complete only when all of the following are true:

- Sternenfuchs identifies the correct original Star Fox RA game.
- Existing Star Fox achievement logic evaluates correctly.
- All required features work.
- All Hardcore restrictions are enforced and regression-tested.
- RetroAchievements has explicitly accepted the client/integration for Hardcore.
- An approved public Sternenfuchs build can legitimately unlock Hardcore Star Fox achievements.

Anything before RA approval is a development/test implementation and must not claim official Hardcore support.
