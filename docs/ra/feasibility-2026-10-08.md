# RA feasibility decision — 2026-10-08

## Decision

**Existing Star Fox game-351 set + current direct WRAM bridge: NO.** The compatibility investigation #7 can exit with its expressly permitted evidence-backed negative result. This does not mean achievement compatibility was implemented, and it does not satisfy the remaining evaluator/cadence/client issues.

**Local achievements: technically plausible, but not established by these tests.** A robust solution would need a general retail-state compatibility layer, including value/pointer semantics and timing, or a separately designed local set. Neither is a small address-offset fix. No such layer or new set is implemented here.

**Official RA Hardcore: not a realistic delivery promise under the currently published rules.** RA's [Standalone Support policy](https://docs.retroachievements.org/general/standalone-support.html), checked on 2026-10-08, explicitly excludes decompilations, recompilations and other unofficial ports from standalone sets. Its approval is also discretionary. That is a published category restriction, not an individual rejection of Sternenfuchs. A future explicit RA determination would be required before treating this native port as eligible through an emulator-style integration; we have no such determination. Merely linking rcheevos or hashing the retail input does not establish eligibility.

## Technical evidence

The bounded adapter and all 39 synthetic definitions work. Their success establishes mechanics, not semantic compatibility. [The retail reference comparison](reference-comparison-2026-10-08.md) proves a real bomb-inventory mismatch.

A further 6000-frame retail SNES reference run used the same documented input recipe and observed:

```text
reference dialogue phase=4412 ra=0x00189C value=23299 matches-real-definition=1
reference dialogue-summary changes=9 real-definition-matches=1
```

The matched value is already part of the committed real definition #5153, `It's Not Easy Being Green`. This observation is a matching operand, not a claimed rcheevos event: the reference harness does not evaluate achievements.

In the existing 7200-phase native Corneria trace, direct `0x00189C` never matched any of the ten dialogue constants used by the nine embedded definitions. Independent inputs/game events are not frame-aligned, so this alone does not prove all nine achievements impossible. The pinned native source separately binds its dialogue state to `FRIENDS_MSG` at `0x001920`, and `dialogue_state()` reconstructs message addresses from that word and the `MESSAGES` bank. Thus a general solution must examine both relocated storage and message-pointer meaning, not simply shift all operands by the bomb-field offset.

The native symbol at retail boss-clear flag `0x0015BA` is `SVAR_BYTE4`; retail stage/boss operands and dialogue constants are still unverified. The inventory's other readable addresses must not be labeled compatible merely because they fall inside WRAM.

## Work boundary

Keep the existing pinned integration and conservative preserved-phase hook. The proved bug is retail-state incompatibility, not a reason to fabricate achievement-specific aliases or triggers. Do not proceed with network unlocks, leaderboards, Rich Presence or official-credit claims.

- #7: completed negative feasibility investigation under its YES/NO exit criterion.
- #8: evaluator mechanics pass; retail semantic parity remains blocked.
- #9: concrete restrictions fixed; exhaustive fixture/device/resume validation remains open.
- #17: native live timing evidence remains incomplete; existing hook is a conservative engineering choice.
- #10/#11/#6: client delivery/official support cannot presently be promised; technical and eligibility gates remain unmet.

The useful next work is finishing local enforcement validation and defining the compatibility approach before spending effort on the authenticated client. An offline local set could be a separate product direction, but has not been authorized as a replacement for the existing RA set.

No ROM, ROM hash, generated assets, images, dumps, copyrighted bulk data or credentials are included in this decision.
