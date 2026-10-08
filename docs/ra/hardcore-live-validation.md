# Hardcore live validation — 2026-10-08

Environment: actual ARM64 `starfox_pc`, pinned upstream/rcheevos, accepted user-owned ROM, Ubuntu 22.04 + Xvfb + SDL shim/native renderer fallback, network disabled. State/rejection logging was temporary in the isolated validation source and is not shipped. This is local enforcement evidence, not official Hardcore approval or RG40XX-H validation.

Before enabling Hardcore, the real Cheat menu enabled God Mode, all three infinite options, laser and level 11. After the laser fix, the clean BOOT reconstruction cleared all six; subsequent menu/host-key attempts and mode lifecycle were checked from actual runtime logs.

| Test | Result | Evidence |
|---|---|---|
| Entering Hardcore performs clean BOOT reconstruction | PASS | Clean restart log, active Hardcore runtime, BOOT setup render. |
| God Mode cannot be enabled | PASS | Cheat-menu mutation and Ctrl+Alt+F12 attempted; god remains 0. |
| Infinite Bombs cannot be enabled | PASS | Cheats row 3 activated; bombs remains 0. |
| Infinite Boost cannot be enabled | PASS | Cheats row 4 activated; boost remains 0. |
| Infinite Lives cannot be enabled | PASS | Cheats row 5 activated; lives remains 0. |
| Selected/direct cheat level is OFF | PASS | Casual level 11 becomes 0 on reconstruction; row 1 cannot enable it. |
| Save state is rejected | PASS | Ctrl+F1: explicit runtime reject, scancode 58. |
| Load state is rejected | PASS | Ctrl+F2: explicit runtime reject, scancode 59. |
| Slot selector/state UI cannot bypass restriction | PASS | Ctrl+F3: explicit runtime reject, scancode 60. |
| Frame freeze/frame step is rejected | PASS | F5/F6/F7 attempted; frozen=0 and following menu/tick progression continues. |
| Accelerated/test playback cannot affect eligible session | PASS | STARFOX_TEST_FAST_FORWARD requested; effective factor 1 in Hardcore. |
| Scripted test input does not execute | PASS | 21 configured input entries become 0 after Hardcore reconstruction. |
| Scripted state actions do not execute | PASS | 4 configured actions become 0 after Hardcore reconstruction. |
| Disabling Hardcore switches to Casual | PASS | switched to casual; active changes to 0 without restart. |
| Re-enabling Hardcore requires another clean restart | PASS | Second clean restart request followed by active=1, normalized flags. |
| Previously enabled default laser is cleared | FAIL → PASS | Before fix laser=1 survived; set_default_laser(0U) makes identical re-test laser=0. |

The process ended with `GLXBadContext` during virtual graphical teardown. Actual device audio/controller/rendering and exhaustive unlisted bypasses remain unverified; #9 stays open. See [session report](local-validation-2026-10-08.md).

## Follow-up: additional QA mutation paths — 2026-10-08

A source audit of the pinned runtime found three additional execution sites that were not covered by the original input/state-vector guards:

- the ending fixture writes route/boss history, enables God Mode and starts the ending map;
- the startup QA block can preroll gameplay, force revival, send messages, create objects, skip bosses and start clear/Titania sequences;
- scheduled revival writes lives and changes the player's strategy during the runtime loop.

`scripts/apply-ra-runtime.py` now gates all three with the authoritative policy's `can_use_scripted_input()` result, resolved after Hardcore restart/normalization. Hardcore also clears presentation history, rejects its F12 toggle and disables `STARFOX_TEST_UNPACED`. RA-disabled and Casual execution retain the existing QA behavior.

Full ARM64 `starfox_pc` compile/link: **PASS** with the pinned sources and all downstream patches, GCC 11.4 / Ubuntu 22.04, PGO disabled.

A local ARM64 `getenv` interposer delayed the ending fixture until its second startup query, so the initial Casual menu could perform the real clean Hardcore restart. This modifies only the private test process, not the production binary or ROM:

| Observation | Previous build | Fixed build |
|---|---|---|
| Initial Casual ending-fixture query | 1 | 1 |
| Real menu requests clean restart | observed | observed |
| 39 definitions activate in Hardcore | observed | observed |
| Ending-fixture query after Hardcore becomes active | **2 — unsafe path reached** | **absent — blocked before query** |

The interposer returns `1` on the second `STARFOX_TEST_ENDING` query and an invalid `STARFOX_TEST_ENDING_PREROLL` value, making accidental execution detectable. The old process reached the second query and exited; the fixed process did not query the fixture in Hardcore. Both encounter the previously documented Xvfb/Mesa `GLXBadContext` shutdown limitation, so a clean exit is **not** claimed. The other two mutation sites and unpaced/history guards have source/compile coverage; individual live activation of each fixture remains unverified. Issue #9 remains open for that coverage and device/resume checks.

## Extended execution-site regression — 2026-10-08

The diagnostic-only helper `tests/ra_runtime_qa_query_probe.c` intercepts just twelve named QA environment queries, returns NULL for those names and reports their counts at process exit. It does not intercept credentials, write game memory, supply controller input or ship in the production binary. Compile it separately as an ARM64 shared library (`cc -shared -fPIC ... -ldl`) and use it only through `LD_PRELOAD` in the private runtime test process.

Both old and fixed binaries ran the same real menu recipe: direct Casual Corneria; scripted state action `30:6`; controller presses `60:128,90:2048,120:2048,150:2048,180:128,210:1024,240:1024,270:128`; 1100 presentation frames per runtime. Both logged the clean restart and activated the Hardcore runtime. The old binary predates the extra QA guards; the fixed binary is built from ea37089. Network was disabled.

| QA query | Old count | Fixed count | Interpretation |
|---|---:|---:|---|
| ENDING | 2 | 1 | No Hardcore startup fixture query |
| NUCLEUS_DEFEAT | 4 | 2 | Both mutation-site queries limited to Casual startup |
| PREROLL_TICKS | 2 | 1 | No Hardcore test preroll |
| MESSAGE | 2 | 1 | No Hardcore injected-message path |
| UPGRADE_FLASH | 2 | 1 | No Hardcore fixture object creation |
| EX_CROSSHAIR | 2 | 1 | No Hardcore fixture WRAM write |
| TITANIA_END | 2 | 1 | No Hardcore fixture map skip/God Mode |
| CLEAR | 2 | 1 | No Hardcore fixture map skip/God Mode |
| UNPACED | 2 | 1 | No Hardcore unpaced environment query |
| REVIVAL | 1374 | 273 | Queries stop at clean Hardcore restart, including scheduled loop path |
| SCRAMBLE_WIPE | 1373 | 1372 | Startup mutation query removed; remaining per-frame query is read-only trace logging |

The scheduled revival frame query is not reached because this probe returns NULL for REVIVAL. Its entire mutation path is guarded before that first query; the count comparison verifies that execution-site boundary, not an actual forced death. Likewise this probe proves the startup fixture sites do not execute in Hardcore, rather than activating every possible fixture payload. The earlier delayed ending-payload probe separately verifies a non-NULL fixture case.

These results extend live coverage to all three newly identified mutation sites and unpaced playback. The source audit confirms the remaining SCRAMBLE_WIPE loop only prints interpolated wipe information; it does not write state. The Xvfb/Mesa teardown error remains. Device controls/audio/rendering and KNULLI process suspend/resume remain unverified; #9 stays open for those external checks.
