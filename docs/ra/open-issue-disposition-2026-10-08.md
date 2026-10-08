# Remaining RA issue disposition — 2026-10-08

This records the outstanding acceptance gates after the completed negative compatibility investigation #7 and mismatch investigation #16. Open issues are not closed merely to make the list empty.

| Issue | Locally completed work | Remaining blocker / next prerequisite |
|---|---|---|
| #8 offline evaluator | 39 definitions activate; bounded adapter/synthetic regression tests pass; actual retail reference triggers #5153 offline | Native state semantics diverge. Faithful native/reference parity needs an independently verified general compatibility approach, not an achievement-specific alias. |
| #9 Hardcore enforcement | Six cheats normalized; save/load/slots, stepping, scripted input/state actions and playback blocked; extra QA mutation-site regression passes | RG40XX H input/audio/render and KNULLI suspend/resume checks require an accessible device. Current device address requested from user. |
| #17 cadence | Existing preserved-phase hook retained; synthetic transient proof and real 28-operand native transition traces analyzed | No achievement-significant between-tick native transient or full reference parity established. Incompatible operand semantics prevent treating present sampling as correct retail evaluation. |
| #10 rc_client/UX | Session-only account/menu foundation compiles; raw password not persisted | Technical compatibility/eligibility gates unmet. Handoff explicitly defers public submissions, leaderboards and Rich Presence. Do not implement an authenticated client around known-wrong memory. |
| #11 approval | Architecture, privacy boundary, hashes-without-publication, restriction evidence and reproducible build/validation documented | Technical package incomplete; published RA Standalone policy excludes unofficial ports. No individual exception/eligibility determination exists. No review request sent. |
| #6 official support | Parent and dependencies updated with concrete evidence | Depends on the unresolved technical and official eligibility gates above. No official Hardcore credit is claimed. |

The native trace analyzed for cadence contains no repeated change of the same operand within one source logic frame. That absence in the tested BOOT/Corneria samples does not prove all stages/definitions safe at 20 Hz. The recommended after-`game.present_frame()` preserved-phase hook is unchanged.

The device was checked again: `knulli.local` fails name resolution, and TCP port 22 at historical `192.168.178.76` is not reachable within the bounded check. The historical IP is not treated as the current device identity. No network scan, deployment or ROM transfer to an unknown host was performed.

Build: PASS — latest changed runtime was fully compiled/linked as ARM64; this iteration adds test helper/documentation only.
ROM identity: PASS — accepted retail identity established earlier; no ROM hash stored here.
Live trigger: FAIL native / PASS reference — actual retail rcheevos event #5153; no native trigger proven.
Cadence: INCOMPLETE — phase hook retained, retail parity unproven.
Hardcore: PASS for exercised local enforcement paths / INCOMPLETE platform validation.
Device: NOT RUN — current SSH access unavailable.

No ROMs, ROM hashes, generated assets, screenshots, dumps, tokens or credentials are committed. The query probe logs only fixed QA option names/counts.
