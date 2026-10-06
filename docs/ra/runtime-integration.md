# Sternenfuchs live RetroAchievements runtime integration

Status: offline/runtime foundation only. No public RetroAchievements unlock submission is enabled.

## Build integration

The Sternenfuchs ARM64 build:

1. applies the account-menu source transform;
2. applies the live RA runtime transform;
3. builds pinned rcheevos v12.5 as a static archive;
4. links the offline RA bridge into the real `starfox_pc` target;
5. produces the normal PortMaster ARM64 runtime and ZIP layouts.

Pinned rcheevos revision:

`1433173220a7eaede6a9ed7a18e94117be1821e0`

Successful ARM64 build evidence:

https://github.com/mtoensing/sternenfuchs/actions/runs/37506330247

## Offline evaluator

For the Original Star Fox experience, the runtime creates one
`RetroAchievementsBridge` backed by the existing `MapVm`.

Memory reads use the bounded logical-WRAM adapter:

```text
RA 0x000000..0x01FFFF
        |
        + 0x7E0000
        v
SNES 0x7E0000..0x7FFFFF
        |
        v
MapVm::peek_ram_byte()
```

All 39 analyzed current Star Fox definitions are activated locally.

The evaluator is intentionally not enabled for the Star Fox EX experience.

## Evaluation cadence

The call to `rc_runtime_do_frame` occurs once per preserved SNES/video phase,
immediately after `game.present_frame()`.

It is not tied to host presentation FPS or interpolation frames.

This follows the prior cadence proof that a real delta-based Star Fox
achievement can miss a one-phase transition when sampled only at the 20 Hz
logic cadence.

## Local events

The bridge exposes:

- achievement trigger callbacks;
- raw rcheevos runtime state events;
- measured achievement progress;
- reset/deactivation support.

The runtime currently logs local events only.

No HTTP transport, login request, server unlock submission, leaderboard
submission or public Hardcore credit is enabled.

## Hardcore session transition

The host owns one `HardcorePolicy` outside the runtime-restart loop.

```text
Casual session
    |
    | user enables HARDCORE
    v
persist account input in process memory
    |
    v
request BOOT reconstruction
    |
    v
clean runtime instance
    |
    v
HardcorePolicy -> hardcore
    |
    v
normalize gameplay state
```

Disabling Hardcore is allowed in-place and changes the policy to Casual.

A later transition back to Hardcore again requires the clean restart path.

## Enforced Hardcore restrictions

Current pinned-runtime enforcement includes:

- save-state save/load/slot UI rejected;
- host God Mode shortcut rejected;
- God Mode cleared when entering Hardcore;
- infinite bombs cleared and blocked;
- infinite boost cleared and blocked;
- infinite lives cleared and blocked;
- selected cheat/direct level reset;
- Cheats-page mutation blocked;
- frame freeze/frame-step controls blocked;
- slowdown/test/super-speed playback paths blocked conservatively;
- scripted test input blocked;
- scripted state actions blocked.

The pinned Star Fox Enhanced revision does not contain the later upstream
Planet Select Cheat, so it is not part of this pinned-runtime enforcement list.

## Credentials

Username/password editing is available from:

```text
OPTIONS -> RETROACHIEVEMENTS
```

The password is masked in the menu.

Credentials survive an in-process clean Hardcore restart only through host
process memory. They are not added to Star Fox save-state serialization.

Future authenticated integration should exchange the password for a
server-issued token and persist the token rather than the raw password.

## Remaining gates

A ROM/device is still required to complete:

- #13: real user ROM -> official rcheevos hash -> RA game identity;
- #16: live real achievement condition against Sternenfuchs WRAM;
- #17: live confirmation of the preserved-phase cadence decision;
- #8: parity validation against a supported SNES RA environment;
- #9: live negative tests of every Hardcore restriction.

External RetroAchievements eligibility/approval remains an independent gate.
