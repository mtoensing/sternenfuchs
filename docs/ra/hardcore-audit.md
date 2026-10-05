# RetroAchievements Hardcore runtime audit

Parent: https://github.com/mtoensing/sternenfuchs/issues/19

This audit identifies runtime features in the pinned Star Fox Enhanced revision that can invalidate RetroAchievements Hardcore eligibility.

Pinned upstream revision: `6612cb05e4bda0a5e25e8e805d64d0e3db50896a`

## Summary

The current runtime exposes several gameplay/state manipulation paths that must be centrally governed before Hardcore can be enabled.

The important finding is that these features are not isolated to one subsystem. They span:

- game-state serialization;
- runtime options;
- timing controls;
- cheat flags;
- test/diagnostic input;
- direct-entry/test execution.

Therefore Hardcore should be enforced by one authoritative policy object/state, not by scattered individual checks.

## Audit table

| Feature | Source file / symbol | Production accessible? | Hardcore action required | Regression test |
|---|---|---:|---|---|
| Save-state load | `src/app/starfox_pc.cpp` state-slot flow; `GameSimulation::load_state` / component load-state paths | Yes | Reject while Hardcore is active | Attempt load during Hardcore; verify state is unchanged and Hardcore remains valid |
| Save-state creation | `GameSimulation::save_state()` in `src/simulation/game_state.cpp` | Yes | Clarify policy; safest initial implementation is disable user save-state operations in Hardcore | Attempt save in Hardcore and verify policy result |
| Frame freeze / frame advance | host frame-debug flow in `src/app/starfox_pc.cpp` | Yes | Disable/reject in Hardcore | Enter frame-debug and request step; verify no frame stepping |
| Playback speed / fast-forward | `playback_speed_multiplier` in `include/starfox/timing/fixed_step.hpp` | Yes | Allow only behavior explicitly permitted by current RA rules; disallow slowdown and test super-speed | Verify prohibited speed modes cannot activate in Hardcore |
| Test super-speed | `playback_speed_multiplier(... super_speed ...)` supports 20x | Primarily developer/test path | Disable in Hardcore and preferably production RA builds | Set triggering input/environment; verify ignored/rejected |
| Host god mode | `GameSimulation::set_god_mode(bool)` | Runtime API; exposed by host/test paths | Disable and force false before Hardcore starts | Enable before transition; entering Hardcore must clear it/reset |
| Infinite bombs | `infinite_bombs_`; runtime options in `src/simulation/game_simulation.cpp` and `src/app/runtime_input.cpp` | Yes | Disable and force false | Toggle during Hardcore must be rejected |
| Infinite boost | `infinite_boost_`; runtime options | Yes | Disable and force false | Toggle during Hardcore must be rejected |
| Infinite lives | `infinite_lives_`; runtime options | Yes | Disable and force false | Toggle during Hardcore must be rejected |
| Planet-select cheat | `planet_select_cheat_`, `set_planet_select_cheat` | Yes | Disable and force false | Toggle must be rejected; pre-existing value cleared on Hardcore reset |
| Default laser / gameplay-altering startup state | runtime options and saved settings in `src/app/runtime_input.cpp` / `GameSimulation` | Yes | Audit individually; gameplay-altering non-stock starting state should not survive Hardcore entry unless RA approves it | Enter Hardcore from altered starting configuration and verify canonical state |
| Scripted gameplay input | `STARFOX_TEST_PRESSES` consumed by runtime test infrastructure | Test/diagnostic | Must never participate in a Hardcore-eligible session | Set env var and launch Hardcore; verify input injection disabled or session forced Casual |
| Scripted state actions | `STARFOX_TEST_STATE_ACTIONS` used by save-state/runtime tests | Test/diagnostic | Must never participate in Hardcore | Set env var and verify Hardcore is refused or action path disabled |
| Direct stage/test entry | CLI map/direct-entry and test environment paths in `starfox_pc` and tools | Mixed | A session started outside normal boot flow should be Casual/non-eligible unless explicitly proven equivalent | Launch direct stage and verify Hardcore unavailable |
| Test god-mode environment | `STARFOX_GOD_MODE` in diagnostic executables such as `src/app/stage_trace.cpp` | Test/diagnostic | No Hardcore eligibility in diagnostic binaries | Diagnostic executable must never submit unlocks |
| Runtime options menu cheats | cheat rows in `src/simulation/game_simulation.cpp` | Yes | Hide, disable, or reject cheat rows while Hardcore is active | Open menu in Hardcore and verify cheat state cannot change |
| Resume / restored process state | save-state continuation infrastructure | Potentially | Resumed non-clean sessions must become Casual unless RA explicitly supports the mechanism | Restore state/process and verify Hardcore flag is not retained |
| Debug/memory inspection tools | project diagnostic tools | Developer tools | Keep outside eligible runtime path; never allow writes to eligible live session | Eligible production binary exposes no memory editor/write API through RA integration |

## Confirmed source evidence

### Save states

`src/simulation/game_state.cpp` implements:

```cpp
std::vector<std::uint8_t> GameSimulation::save_state() const
```

and the runtime has corresponding load/slot behavior. Supporting subsystems also expose `load_state`, including MapVm, audio, objects, dust and particles.

Hardcore implication: loading an arbitrary previous state is fundamentally incompatible with Hardcore progression unless explicitly handled by RA policy. The policy layer must intercept the user-facing operation, not merely individual component loaders.

### Speed controls

`include/starfox/timing/fixed_step.hpp` exposes `playback_speed_multiplier` and documents accelerated modes:

- 2x total;
- 3x total;
- 5x total;
- separate 20x test mode.

The Hardcore policy must distinguish permitted fast-forward from disallowed slowdown/debug stepping according to the then-current RA rules.

### Gameplay cheats

`include/starfox/simulation/game_simulation.hpp` exposes state for:

- `infinite_bombs`;
- `infinite_lives`;
- `infinite_boost`;
- `planet_select_cheat`;
- host god mode.

`src/simulation/game_simulation.cpp` contains runtime-option toggles for these features.

`src/app/runtime_input.cpp` also persists/parses cheat-related settings such as:

- `INFINITE_BOMBS`;
- `INFINITE_BOOST`;
- `INFINITE_LIVES`;
- `PLANET_SELECT_CHEAT`.

Hardcore implication: simply hiding menu rows is insufficient because saved configuration can pre-enable these states. Hardcore entry must validate and normalize the authoritative game state.

### Scripted/test input

The upstream test infrastructure uses `STARFOX_TEST_PRESSES` to inject controller state and `STARFOX_TEST_STATE_ACTIONS` to exercise save/load and runtime state operations.

These are valuable regression facilities and should stay in the source tree.

They must, however, be structurally separated from an eligible Hardcore session. Recommended behavior:

```text
test/diagnostic environment detected
        |
        +--> Casual / development session only
        |
        +--> no server-side Hardcore submission
```

Do not rely only on UI visibility.

## Required policy architecture

Recommended conceptual interface:

```cpp
enum class AchievementMode {
    disabled,
    casual,
    hardcore
};

class HardcorePolicy {
public:
    bool can_load_state() const;
    bool can_frame_advance() const;
    bool can_use_cheats() const;
    bool can_use_test_input() const;
    bool can_change_playback_rate(...) const;
};
```

The exact API may differ, but all eligibility-changing behavior should consult one source of truth.

## Entering Hardcore

Casual -> Hardcore should be treated as a clean-session transition.

Proposed sequence:

```text
request Hardcore
      |
      +--> reject if diagnostic/test mode is active
      +--> clear gameplay-altering cheat settings
      +--> disable frame-debug state
      +--> cancel state-slot/load interactions
      +--> restore canonical playback/timing settings
      +--> perform full game reset
      +--> initialize RA Hardcore session
```

Do not attempt to preserve an already-running Casual game when switching into Hardcore.

## Leaving Hardcore

Hardcore -> Casual may be implemented without a full reset if allowed by current RA requirements.

Once a session becomes Casual, it must not silently regain Hardcore eligibility without the complete Hardcore-entry/reset sequence.

## Test matrix for Phase 3

The later implementation should have automated negative tests for at least:

1. load-state request is rejected;
2. frame-step request is rejected;
3. disallowed speed/slowdown request is rejected;
4. god mode cannot be enabled;
5. infinite bombs cannot be enabled;
6. infinite boost cannot be enabled;
7. infinite lives cannot be enabled;
8. planet-select cheat cannot be enabled;
9. scripted input cannot affect an eligible session;
10. scripted state actions cannot affect an eligible session;
11. Casual -> Hardcore performs a clean reset;
12. restored/resumed state does not retain Hardcore;
13. Hardcore -> Casual is explicit and irreversible without another reset;
14. RA-disabled mode preserves current Sternenfuchs behavior.

## Remaining policy questions

These require checking the then-current RetroAchievements compliance rules before implementation is declared complete:

- whether user-visible fast-forward is permitted and under what limits;
- whether save-state creation itself is allowed if loading is blocked;
- exact suspend/resume requirements on PortMaster/KNULLI;
- whether modified starting options such as default laser affect eligibility;
- whether Sternenfuchs is eligible for approval as a client/emulator-style integration at all.

## Conclusion

No architectural blocker was found.

The known Hardcore-incompatible features are identifiable and can be governed centrally. The recommended implementation is therefore a policy layer around existing host/runtime controls, not a rewrite of Star Fox Enhanced.

The largest remaining risk is external approval/eligibility, not the ability to technically disable local cheats and state manipulation.
