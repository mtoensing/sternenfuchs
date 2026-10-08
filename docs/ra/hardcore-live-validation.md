# Hardcore live validation

Session: 2026-10-08. Baseline `6f6518b36553edc55c51ba345879ef7ed72c09ce`.

**Live validation not completed.** The real ROM failed the game-351 supported-identity gate, so the explicit Phase B stop rule prevented runtime tests. Isolated ARM64 policy tests passed, but cannot establish any live row below. Official Hardcore support is not claimed.

| Test | Live result | Reason |
|---|---|---|
| Entering Hardcore performs a clean BOOT reconstruction | NOT RUN | Phase B identity gate |
| God Mode cannot be enabled | NOT RUN | Phase B identity gate |
| Infinite Bombs cannot be enabled | NOT RUN | Phase B identity gate |
| Infinite Boost cannot be enabled | NOT RUN | Phase B identity gate |
| Infinite Lives cannot be enabled | NOT RUN | Phase B identity gate |
| Selected/direct cheat level is OFF | NOT RUN | Phase B identity gate |
| Save state is rejected | NOT RUN | Phase B identity gate |
| Load state is rejected | NOT RUN | Phase B identity gate |
| Slot selector/state UI cannot bypass restrictions | NOT RUN | Phase B identity gate |
| Frame freeze/frame step is rejected | NOT RUN | Phase B identity gate |
| Accelerated/test playback cannot affect eligible session | NOT RUN | Phase B identity gate |
| Scripted test input is blocked | NOT RUN | Phase B identity gate |
| Scripted state actions are blocked | NOT RUN | Phase B identity gate |
| Disabling Hardcore switches to Casual | NOT RUN | Phase B identity gate |
| Re-enabling Hardcore requires another clean restart | NOT RUN | Phase B identity gate |

See [session report](local-validation-2026-10-08.md) for concrete build, ROM identity and device results. No restrictions were weakened.
