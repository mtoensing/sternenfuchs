# Local RetroAchievements validation — 2026-10-08

## Result after the NAS follow-up

**ROM identity PASS; live achievement compatibility BLOCKED by a measured WRAM semantic mismatch.** The local Hardcore negative tests pass in the instrumented ARM64 desktop runtime after fixing a laser-cheat leak. Handheld validation and supported-SNES parity remain unverified. No official Hardcore support is claimed.

## Inputs

- Sternenfuchs baseline: `6f6518b36553edc55c51ba345879ef7ed72c09ce`; first report/script-mode fix: `3f0f431`.
- Star Fox Enhanced: `6612cb05e4bda0a5e25e8e805d64d0e3db50896a`.
- rcheevos: `1433173220a7eaede6a9ed7a18e94117be1821e0` (v12.5).
- All required handoff documents were read in full; acceptance criteria for #13, #16, #17, #8, #9 and #6 were read.
- User-authorized source: NAS `base/emulation/roms/Nintendo SNES Nointro [Full Set]`, accessed through `ssh nas`. Only `Star Fox (USA).7z` was extracted into private local scratch storage outside the Sternenfuchs checkout. Neither archive nor extracted ROM enters Git.
- The user's prohibition on committing ROM hashes overrides the handoff's hash-publication instruction. Hash results are local only; this report contains no ROM hash.

## Phase A — build and regression baseline

ARM64 Ubuntu 22.04 foundation PASS (exit 0):

```text
rcheevos=12.5 console=Super Nintendo Entertainment System
activated 39/39 real Star Fox achievement definitions
triggered real single-value achievement 5158 via synthetic WRAM
triggered real delta/prior achievement 851 across two frames
triggered real multi-address achievement 880 via synthetic WRAM
cadence proof: a real delta achievement can miss a one-phase transient at 20 Hz
Star Fox synthetic-WRAM rcheevos proof: PASS
```

Hardcore-policy, bridge, identity and account tests passed. The separate WRAM adapter test passed both on ARM64 Linux and natively on macOS.

Full ARM64 build with PGO disabled completed using the exact pinned upstream and downstream patches/transforms, producing an aarch64 ELF and both normal ZIP layouts before any ROM was supplied to the runtime. Temporary read-only transition/state logging was added only to the isolated validation copy. The final production source was rebuilt successfully in a fresh output volume without that instrumentation (aarch64 ELF; build exit 0); the only runtime-code change is laser normalization below. Source-only build snapshots and dedicated Docker volumes preserve the user's existing `.work` and `dist`.

The final normal runtime also booted without RA configuration and activated 39 definitions in Casual. Its short 120-frame smoke run encountered the same GLX teardown error described below; a clean GUI exit is not claimed.

Initial blockers corrected or recovered:

- RA build/hash helpers had Git mode 100644, causing `permission denied` under the handoff's direct calls; corrected to 100755 in `3f0f431`.
- The initial Colima build attempt became unresponsive during SDL checkout. The stop request returned `tried to kill container, but did not receive an exit event`. The VM later recovered; Linux Docker volumes allowed the build to finish. Other services were not restarted.
- The macOS default SDK failed helper linking with `tapi error: malformed file` / `unknown architecture` (`arm64e.x1-macos`). Selecting the installed MacOSX26.5 SDK allowed the official rcheevos helper to run, without repository changes.

## Phase B — ROM identity (#13)

The original local `Star Fox (USA) (Rev 1).sfc` hashed reproducibly but did not match game 351's supported list. The user then supplied the NAS collection.

`Star Fox (USA).sfc` from that NAS archive:

- size: 1,048,576 bytes;
- copier header: absent;
- official rcheevos SNES path: `rc_hash_initialize_iterator` -> `rc_hash_generate`;
- two repeated runs: identical valid 32-character results;
- matches the base USA entry on the [official supported-hash list for Star Fox / game 351](https://retroachievements.org/game/351/hashes).

**PASS** by official supported-list comparison. This is not an authenticated RA API exchange. No ROM patch, custom hash, identity bypass, login or unlock submission was used.

## Phase C — real live condition (#16)

Exact embedded candidate: #5158, Powerful Payload, `0xH0015af=5`. Its public meaning is having five Nova Bombs at once ([official RA set entry](https://retroachievements.org/achievement/5165), which lists this neighboring achievement).

The real ARM64 game ran with the accepted ROM in Original experience under Xvfb, the pinned SDL3-to-SDL2 shim and native renderer fallback. All containers that executed gameplay had `--network none`. Audio was dummy; this does not validate actual audio or handheld controls.

A real Corneria run used ordinary controller-button input only, without cheats or state writes. A separate bomb test used SNES A (`128`) at presentation frames 1200, 1500 and 1800, after the intro. Actual gameplay consumed three bombs:

```text
scripted-input: frame=1201 pressed=128 bombs=3->2
scripted-input: frame=1501 pressed=128 bombs=2->1
scripted-input: frame=1801 pressed=128 bombs=1->0
```

The bridge's RA address `0x0015AF` changed from 0 to 3 at video phase 940, then remained 3 throughout these bomb throws. The native gameplay counter and the RA operand therefore diverged. No local achievement trigger occurred.

Concrete source diagnosis in the pinned upstream:

- `assets/symbols/ultrastarfox.txt`: `FIRECNT = 0x0015AF`, `SPECWEPCNT = 0x001634`.
- `GameSimulation` binds `special_weapon_count_` to `SPECWEPCNT`.
- `MapVm::read_native_word` uses the same CPU memory interface; the RA adapter reads bounded WRAM through `peek_ram_byte`.

This demonstrates a semantic/layout incompatibility for the tested bomb counter, rather than proving that ordinary WRAM bounds imply achievement compatibility. No achievement-specific alias or gameplay hook was added to conceal it. **FAIL for live compatibility / trigger proof.** Investigate the pinned generated-runtime layout against retail/reference SNES WRAM before rc_client or server integration.

## Phase D — live cadence (#17)

The embedded 39 definitions reference **28**, not 27, unique logical addresses. The earlier inventory omitted 16-bit `0x00189C`, used by nine dialogue-related definitions; the inventory and current handoff counts are corrected. All 28 remain inside ordinary WRAM.

Temporary instrumentation observed only these 28 operands (16-bit where needed), once at the existing preserved-phase hook immediately after `game.present_frame()`, and logged changes only. No WRAM dump was produced.

| Run | Trace records, including initial samples | Last observed changed phase | Changed addresses after initialization | Local triggers |
|---|---:|---:|---|---:|
| BOOT with Start presses | 32 | 394 | `0x15AF`, `0x189C` | 0 |
| Corneria, 7200 presentation frames, ordinary B/fire input | 700 | 7198 | `0x033A`, `0x157A`, `0x15AF`, `0x16BD`, `0x189C` | 0 |
| Corneria bomb throws, 2400 presentation frames | 177 | 2398 | `0x157A`, `0x15AF`, `0x16BD`, `0x189C` | 0 |

No sampled operand changed twice within the same source-logic frame; no achievement-significant one-/two-phase transient was established. These limited runs do not prove the whole set is 20 Hz-safe or that this hook matches a supported SNES core. The conservative preserved-phase hook remains unchanged. **PARTIAL / NOT PROVEN** for #17; reference parity still required.

## Phase E — Hardcore enforcement (#9)

Tests used the actual compiled `starfox_pc` application, real menu navigation and keyboard events, with temporary read-only state logging. See [complete live matrix](hardcore-live-validation.md).

A real bug was reproduced before the fix:

```text
Casual: god=1 bombs=1 boost=1 lives=1 laser=1 level=11
Hardcore after clean restart: god=0 bombs=0 boost=0 lives=0 laser=1 level=0
```

The active default-laser cheat survived Hardcore entry. `scripts/apply-ra-runtime.py` now adds `set_default_laser(0U)` to `GameSimulation::set_ra_hardcore_active` normalization. Repeating the same menu actions after rebuilding produced:

```text
Hardcore after clean restart: god=0 bombs=0 boost=0 lives=0 laser=0 level=0
ra-validation-scripts input=0 state=0
ra-validation-speed effective=1
ra-validation-reject save-state key=58
ra-validation-reject save-state key=59
ra-validation-reject save-state key=60
ra-hardcore: switched to casual
ra-hardcore: clean restart requested
```

All Hardcore menu mutation attempts left the six state values at zero. The host God Mode shortcut was attempted. F5/F6/F7 were attempted; the runtime remained unfrozen and subsequent menu/tick progression continued. The inherited test-fast-forward request was reduced to factor 1. Configured scripted input and state actions had nonzero counts in Casual and zero counts after Hardcore reconstruction. Disabling Hardcore was in-place; re-enabling caused a second clean reconstruction.

**PASS for the enumerated negative tests in this ARM64 desktop test environment after the fix.** This does not validate actual device controls/audio/rendering, exhaustive unlisted bypasses or official RA compliance.

## Runtime/environment failure and Phase F

The Xvfb/Mesa runs ended with exit 1 during GLX teardown:

```text
X Error of failed request: GLXBadContext
Major opcode: 150 (GLX)
Minor opcode: 4 (X_GLXDestroyContext)
```

Gameplay and menu evidence were captured before teardown; a clean graphical process exit is not established in this virtual environment. The first UI attempt used the wrong menu offset; correct navigation from Options' selected Cheats row uses three Up presses to reach RetroAchievements, and subsequent lifecycle/negative tests succeeded.

The real device was unavailable: `knulli.local` did not resolve; historical `192.168.178.76:22` timed out and later returned `No route to host`. Current IP was requested. **NOT RUN** for RG40XX-H deployment, controller, audible audio, device rendering and RA account-menu UX.

## Privacy and remaining gates

No ROM, archive, ROM hash, generated asset bundle, screenshot, bulk memory trace or credential is added to Git. Only small scalar observations, allowed source addresses, documentation and the one-line laser fix are committed. Local runtime containers had networking disabled; no server unlock was emitted.

#13 can close on the real accepted-ROM proof. #16, #17, #8, #9 and #6 remain open: the measured bomb-counter mismatch blocks achievement parity; the cadence/reference and real-device gates remain incomplete. The next technical action is a supported-SNES/reference comparison of the retail bomb counter and the pinned runtime's WRAM layout, followed by a truthful general compatibility fix if feasible. Do not add an achievement-specific alias or enable public submission.
