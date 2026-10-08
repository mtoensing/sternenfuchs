# Retail SNES reference comparison — 2026-10-08

## Result

**NO: the existing game-351 set cannot currently be reused faithfully through direct WRAM offsets.** Issue #16's permitted alternative, an exact reproducible mismatch, is satisfied. This is not a successful local achievement trigger or a completed compatibility/cadence gate.

The user's accepted base USA ROM was used locally in both runtimes. No ROM, generated assets, images, memory dumps or ROM hashes are included here.

## Reference execution

A local headless libretro harness built `libretro/snes9x` at commit `fae2fea08f74180759ef540ee94259213f503480` on ARM64 Ubuntu 22.04. It loads the retail ROM directly, calls `retro_run()` once per frame and reads byte `0x0015AF` from `RETRO_MEMORY_SYSTEM_RAM`. It does not modify memory or use save states/cheats. This is a SNES-core reference, not an authenticated RA-client or official compliance test.

Input recipe (zero-based frames, joypad port 0): Start for five frames every 180 frames from 180 through 2399; A for three frames at 3600, 4000 and 4400; stop after 6000 frames. Private visual inspection at frame 6000 confirms regular Corneria gameplay. The first A input did not consume a bomb; the latter two did.

Concise observed changes:

```text
reference phase=4004 ra=0x0015AF old=3 new=2
reference phase=4404 ra=0x0015AF old=2 new=1
```

Compare the prior real Sternenfuchs Corneria run:

```text
scripted-input: frame=1201 pressed=128 bombs=3->2
scripted-input: frame=1501 pressed=128 bombs=2->1
scripted-input: frame=1801 pressed=128 bombs=1->0
```

Its RA `0x0015AF` stayed at 3 throughout. These are independent runs, not frame-aligned inputs or complete state parity. They establish the relevant semantic difference: the retail address tracks bomb inventory; the same direct native offset does not.

## Concrete source cause

The pinned runtime's `src/app/starfox_pc.cpp` asset-loading path constructs `payload.original_rom` using `apply_bps_patch(retail_rom, embedded_resource(101))`, then attaches `embedded_text_resource(102)` symbols. `src/app/asset_builder.cpp` uses the same transformation. Even the **Original** experience therefore runs a patched/generated cartridge layout, not the untouched retail layout used by the RA identity/set.

The native symbols identify `FIRECNT` at `0x0015AF` and `SPECWEPCNT` at `0x001634`. `GameSimulation` binds its special-weapon inventory to `SPECWEPCNT`. This explains why a bounded adapter can read valid WRAM while exposing the wrong retail meaning. It does not establish a general relocation map for the remaining operands, nor authorize a one-achievement address alias.

## Compatibility matrix

The complete 28-operand inventory remains in [starfox-addresses.md](starfox-addresses.md). All are structurally readable inside 128 KiB WRAM. Semantic status:

| Operand group | Evidence | Status |
|---|---|---|
| `0x0015AF` / #5158 | retail reference decreases on bomb use; native direct address remains 3 | **incompatible** |
| `0x00189C` / nine dialogue definitions | native small values observed; no retail dialogue comparison | **unverified** |
| Remaining 26 operands | bounded adapter and synthetic definitions pass; selected native transitions recorded | **unverified**, not proven compatible |

## Issue gates

- #16 can close as a completed mismatch investigation under its explicit acceptance criteria.
- #7/#8 remain open: general retail-state compatibility and evaluator parity are not established.
- #17 remains open: this reference does not prove achievement-significant between-tick transients in the native runtime. Retain the existing preserved-phase hook.
- #10/#11/#6 remain gated. Do not implement server submissions, leaderboards or Rich Presence, or request official credit before technical proof.

The next compatibility work requires a general, independently verified retail-state mapping or an explicit project decision about an alternative set. Neither a hard-coded #5158 alias nor manufacturing a trigger resolves this evidence.
