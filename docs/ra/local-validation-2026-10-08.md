# Local RetroAchievements validation — 2026-10-08

Result: **BLOCKED at Phase B (real ROM identity)**. This session does not establish live gameplay compatibility or official Hardcore support.

## Inputs and scope

- Sternenfuchs baseline: `6f6518b36553edc55c51ba345879ef7ed72c09ce` (clean `main`, fast-forwarded from `084c8ce`).
- Star Fox Enhanced: `6612cb05e4bda0a5e25e8e805d64d0e3db50896a`.
- rcheevos: `1433173220a7eaede6a9ed7a18e94117be1821e0` (v12.5).
- Read in full: `AGENTS.md`, `docs/ra/LOCAL-HANDOFF.md`, `docs/RETROACHIEVEMENTS.md`, `docs/ra/runtime-integration.md`, `docs/ra/cadence-analysis.md`, `docs/ra/starfox-addresses.md`. Read acceptance criteria for #13, #16, #17, #8, #9 and #6.
- User ROM: `Star Fox (USA) (Rev 1).sfc`, used in place outside the repository. Size: 1,048,576 bytes; no 512-byte copier header.
- The user's instruction forbids committing ROM hashes, overriding the handoff's request to record the exact hash. No hash is included here or in issue comments.

## Phase A — baseline

The literal `./scripts/build-rcheevos-arm64.sh` failed with `permission denied`: Git recorded mode 100644. The ROM helper had the same mode. Both are corrected to 100755; script content is unchanged.

Executed on the existing local ARM64 Ubuntu 22.04 container image:

```sh
docker run --rm -v /Users/marc/Documents/Dev/starfox:/repo -w /repo   sternenfuchs-dev:22.04 bash scripts/build-rcheevos-arm64.sh
```

PASS, exit 0:

```text
rcheevos=12.5 console=Super Nintendo Entertainment System
activated 39/39 real Star Fox achievement definitions
triggered real single-value achievement 5158 via synthetic WRAM
triggered real delta/prior achievement 851 across two frames
triggered real multi-address achievement 880 via synthetic WRAM
cadence proof: a real delta achievement can miss a one-phase transient at 20 Hz
Star Fox synthetic-WRAM rcheevos proof: PASS
```

Hardcore-policy, bridge, game-identity and account-session executables also completed with exit 0. `file` confirmed ARM aarch64 ELF executables. The separate read-only WRAM adapter test passed natively on macOS (exit 0).

The full `STARFOX_PGO_PHASE=none bash scripts/build-arm64.sh` was started in a separate source-only snapshot in the same container image. This avoided the script's deletion of the pre-existing `.work` and `dist` directories in the user's checkout. It checked out the pinned upstream, then stopped making progress at `Cloning into '/repo/.work/SDL'...`. Docker exec and Colima status also became unresponsive. No completed current full runtime artifact was obtained. This is an infrastructure blocker, not a demonstrated compiler failure. No VM restart was attempted because the VM hosts other containers. A stop request failed: `tried to kill container, but did not receive an exit event` (validation container `b954a2072e95`); cleanup completion could not be confirmed. The waiting local clients were terminated, without restarting the shared VM.

## Phase B — real ROM identity

The helper's production path (`ra/game_identity.cpp`: `rc_hash_initialize_iterator` -> `rc_hash_generate`, SNES console) was compiled against the exact pinned rcheevos sources and run twice on the existing local ROM. Both runs succeeded and returned identical 32-character hashes.

The macOS default SDK initially failed to link with `tapi error: malformed file` / `unknown architecture` (`arm64e.x1-macos`). Selecting the installed MacOSX26.5 SDK allowed the helper to link and run; this did not require repository changes.

**FAIL for game 351 identification:** the resulting hash does not match any of the three supported entries on the [official Star Fox game-351 hash list](https://retroachievements.org/game/351/hashes), checked on 2026-10-08. The page lists base USA plus French and Portuguese compatibility translations; the supplied Rev 1 ROM did not match. This is a supported-list comparison, not an authenticated RA API resolution. It does not prove the ROM belongs to another RA game.

Hash output stayed in local scratch storage only. No ROM was patched, copied into the repository or replaced. No custom hashing, hard-coded game-identity bypass, login or public unlock submission was used.

## Remaining phases

| Phase | Result | Evidence / blocker |
|---|---|---|
| C — #16 live trigger | NOT RUN | Phase B stop rule; synthetic #5158 is not real gameplay evidence. |
| D — #17 live cadence | NOT RUN | Phase B stop rule; synthetic cadence proof does not establish real transients or SNES parity. |
| E — Hardcore negative tests | NOT RUN | Phase B stop rule; isolated policy tests do not prove runtime enforcement. See separate matrix. |
| F — RG40XX-H | NOT RUN | `knulli.local` did not resolve; historical `192.168.178.76:22` timed out. Current device address requested. No deployment. |
| #8 supported SNES parity | NOT RUN | No accepted ROM identity/live session or reference-client comparison. |

No runtime session was started in this validation, so no live no-submission observation is claimed. The exercised offline hash/tests contain no server-unlock transport; no credentials were used and no unlock was submitted.

## Next action

Obtain an existing user-owned ROM that matches the official game-351 supported list, without distributing ROMs or patching around identity. Re-run Phase B first, then proceed with C–F when the identity gate passes. Restore the build VM's responsiveness separately before repeating the full build. Keep #13, #16, #17, #8, #9 and #6 open.
