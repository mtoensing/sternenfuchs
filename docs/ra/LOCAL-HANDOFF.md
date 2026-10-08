# RetroAchievements local validation handoff

This is the execution guide for the next AI with local access to the Sternenfuchs working tree, a user-owned supported Star Fox/Starwing ROM, and optionally the RG40XX-H over SSH.

Do not restart broad research. Read this file, then execute the steps in order.

## Latest local evidence — 2026-10-08

Read [local-validation-2026-10-08.md](local-validation-2026-10-08.md) before continuing. The user's base USA NAS ROM passes the game-351 identity gate, but real bomb throws decrement native `SPECWEPCNT` while RA `0x0015AF` stays at 3. Do not assume WRAM bounds imply retail memory parity, and do not add an achievement-specific alias. All 39 embedded definitions use 28 unique operands; the old inventory omitted `0x00189C`. A live default-laser Hardcore leak was fixed and the desktop negative matrix re-tested. Device/reference parity remains open. ROM hashes must not be committed under this user's stricter instruction.

The follow-up [retail-core reference comparison](reference-comparison-2026-10-08.md) confirms the mismatch during regular Corneria gameplay. #16 is complete under its explicit mismatch alternative; a live local trigger is still not proven. Additional Hardcore QA mutation paths were guarded; their evidence and remaining coverage are in the negative-test matrix.

## Fixed project state

Repository: `mtoensing/sternenfuchs`

Pinned Star Fox Enhanced revision:

`6612cb05e4bda0a5e25e8e805d64d0e3db50896a`

Pinned rcheevos revision:

`1433173220a7eaede6a9ed7a18e94117be1821e0` (v12.5.0)

RetroAchievements Star Fox game ID: **351**

Current offline achievement snapshot:

- 39 achievements
- 28 unique logical RA addresses
- 28/28 inside ordinary SNES WRAM

The live ARM64 runtime already contains:

- official rcheevos SNES hashing support;
- `RetroAchievementsBridge`;
- bounded `MapVm` WRAM adapter;
- all 39 offline Star Fox definitions;
- preserved-video-phase evaluation (~60 Hz);
- local runtime event/trigger logging;
- local Hardcore policy;
- in-game username/password/Hardcore menu;
- no network unlock submission.

Known green full ARM64 build:

https://github.com/mtoensing/sternenfuchs/actions/runs/37506330247

## Safety rules

Never commit:

- ROM files;
- ROM dumps;
- `Starfox-Assets.BIN`;
- memory dumps containing ROM-derived data;
- RetroAchievements password;
- RetroAchievements access token.

Do not enable public achievement submission.

Do not claim official Hardcore support.

Do not change pinned upstream revisions unless a concrete blocker requires it and the reason is documented.

Changes to `mtoensing/sternenfuchs` go directly to `main`, per `AGENTS.md`.

## Start here

Read:

1. `AGENTS.md`
2. `docs/RETROACHIEVEMENTS.md`
3. `docs/ra/runtime-integration.md`
4. `docs/ra/cadence-analysis.md`
5. `docs/ra/starfox-addresses.md`
6. issues #13, #16 and #17

Then inspect only the concrete runtime code needed for the validation.

## Phase A — verify the local tree

Run:

```bash
git status
git rev-parse HEAD
./scripts/build-rcheevos-arm64.sh
```

If building the full runtime locally is supported on the machine, also run:

```bash
STARFOX_PGO_PHASE=none ./scripts/build-arm64.sh
```

Expected baseline:

- rcheevos smoke test passes;
- 39/39 definitions activate;
- synthetic WRAM tests pass;
- bridge/policy/hash/account tests pass;
- no RA network submission occurs.

If the baseline fails, fix only the smallest real regression before continuing.

## Phase B — #13: identify the real user ROM

Use the user's legally obtained Star Fox/Starwing `.sfc` or `.smc`.

Do not copy it into the repository.

Use the prepared helper:

```bash
./scripts/ra-hash-rom.sh /absolute/path/to/StarFox.sfc
```

It prints only the official RA hash, file size and copier-header detection. It does not copy or modify the ROM.

The production path remains rcheevos:

```text
rc_hash_initialize_iterator
    ->
rc_hash_generate(..., RC_CONSOLE_SUPER_NINTENDO, ...)
```

Record only:

- filename if non-sensitive;
- file size;
- resulting 32-character RA hash;
- whether a 512-byte copier header is present;
- the resolved RA game identity.

Do not publish ROM bytes.

### #13 success

Evidence must show:

```text
user-owned ROM
    -> official rcheevos SNES hash
    -> RetroAchievements Star Fox / game 351
```

If the hash is not recognized as game 351, stop and document the exact hash/result. Do not hard-code around it.

## Phase C — #16: prove one real live achievement condition

Start with a simple real condition.

Preferred first candidate:

- #5158 — Powerful Payload
- RA address `0x0015AF`
- upstream symbol `FIRECNT`

Before testing, verify the exact embedded/current definition from `ra/starfox_achievements.hpp`. Do not rely on old examples in documentation if they differ.

Run the game with local RA event logging enabled.

Observe only the small set of addresses required by the chosen definition. Prefer concise transition logging such as:

```text
phase=<n> ra=0x0015AF value=<v>
ra-event id=<id> type=<type> value=<value>
ra-local-trigger id=<id>
```

Do not dump all WRAM.

### #16 success

A convincing proof is:

1. the real definition is active;
2. the bridge reads the expected live `MapVm` address;
3. real gameplay changes the value as expected;
4. rcheevos emits the expected local trigger;
5. no server submission occurs.

If #5158 is awkward to trigger manually, use another simple current definition from `ra/starfox_achievements.hpp`. Document why.

## Phase D — #17: validate cadence against real gameplay

The working architecture decision is already:

**evaluate once per preserved SNES/video phase (~60 Hz).**

Do not move RA evaluation to render FPS or 20 Hz logic ticks.

For the 28 RA-referenced addresses, instrument a compact transition trace during representative gameplay.

Goal:

- identify whether any RA-referenced address changes between 20 Hz logic ticks;
- identify one- or two-phase transient values;
- confirm the existing preserved-phase hook observes them.

A useful trace record is:

```text
source_logic_frame=<n>
video_phase=<n>
address=<hex>
old=<v>
new=<v>
```

Only log changes.

If a between-tick transition appears, preserve a minimal trace as text with no ROM-derived bulk data.

### #17 success

Close #17 when real gameplay evidence confirms that the current preserved-phase hook is correct and no later/earlier hook is required.

## Phase E — live Hardcore negative tests

With Hardcore enabled, verify on the actual runtime:

- entering Hardcore performs a clean BOOT reconstruction;
- God Mode cannot be enabled;
- Infinite Bombs cannot be enabled;
- Infinite Boost cannot be enabled;
- Infinite Lives cannot be enabled;
- selected/direct cheat level is OFF;
- save state is rejected;
- load state is rejected;
- slot selector/state UI cannot be used to bypass the restriction;
- frame freeze/frame step is rejected;
- accelerated/test playback cannot affect an eligible session;
- scripted test input/state actions do not execute in Hardcore;
- disabling Hardcore changes the session to Casual;
- re-enabling Hardcore requires another clean restart.

Record PASS/FAIL for each row in `docs/ra/hardcore-live-validation.md`.

Do not weaken a restriction merely to make a test pass.

## Phase F — RG40XX-H validation if device is available

Existing device workflow is documented in `AGENT_TASK.md`.

Do not assume the old IP is still valid.

If SSH access is available:

1. build or download the current ARM64 artifact;
2. deploy through the existing Sternenfuchs scripts;
3. leave the user's ROM on the device only;
4. launch from KNULLI Ports;
5. verify:
   - OPTIONS -> RETROACHIEVEMENTS opens;
   - username editing works;
   - password is masked;
   - Hardcore toggle causes the expected reset;
   - game boots and remains playable;
   - controller/audio/rendering remain correct;
   - local RA logs are emitted;
   - no network unlock submission occurs.

## Required issue updates

Update the issues with direct evidence:

- #13 — ROM hash / game identity
- #16 — first real live achievement trigger
- #17 — live cadence proof
- #8 — live evaluator parity evidence
- #9 — Hardcore live negative-test matrix
- #6 — parent summary

Close an issue only when its stated acceptance criteria are actually satisfied.

## Do not do yet

Do not:

- enable public unlock submission;
- implement leaderboards;
- implement Rich Presence;
- persist raw passwords;
- claim official Hardcore;
- ask RetroAchievements to credit this as approved before the technical live proof is complete;
- redesign the memory model;
- introduce achievement-specific gameplay hooks.

## Output format for the local AI

After each meaningful iteration, report:

```text
Build: PASS/FAIL — <one line>
ROM identity: PASS/FAIL/NOT RUN — <one line>
Live trigger: PASS/FAIL/NOT RUN — <one line>
Cadence: PASS/FAIL/NOT RUN — <one line>
Hardcore: PASS/FAIL/NOT RUN — <one line>
Device: PASS/FAIL/NOT RUN — <one line>
Changed: <files/commit>
Next: <single next action>
```

## Definition of done for the local-validation session

The ideal local session ends with evidence for all of:

1. user-owned ROM resolves through official rcheevos hashing to Star Fox game 351;
2. at least one real existing achievement triggers locally from real gameplay;
3. preserved-video-phase cadence is validated against real gameplay transitions;
4. Hardcore negative tests pass;
5. no public/server unlock is emitted;
6. documentation and issues are updated;
7. no ROM/credentials/ROM-derived bulk data enter Git.
