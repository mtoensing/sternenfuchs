# Star Fox RetroAchievements memory-address inventory

Source snapshot: RetroAchievements game **351 / Star Fox**, mirrored at `hoanghdtv/achievements@b5e0e0f1e880dcb367abb08b9ea3b583ab846f10`.
The live RetroAchievements game page currently exposes **39** core achievements; regenerate this inventory if the set changes.

This file deliberately stores only the address inventory, not ROM data.

The embedded definitions in `ra/starfox_achievements.hpp` were re-scanned on 2026-10-08: the earlier 27-address inventory omitted `0x00189C`. The correct count is 28; all remain in WRAM.

## Result

- Achievements scanned: **39**
- Unique logical RA addresses: **28**
- Ordinary SNES WRAM range expected by rcheevos: `0x000000..0x01FFFF`
- Mapping used by Sternenfuchs: `SNES = 0x7E0000 + RA logical address`

**All referenced addresses are inside ordinary 128 KiB SNES WRAM.** This establishes readable bounds only. A retail-core comparison proves that `0x0015AF` has incompatible semantics in the native runtime; see [reference comparison](reference-comparison-2026-10-08.md).

## Addresses

| RA address | SNES WRAM address | Width(s) used | Referenced by |
|---:|---:|---|---|
| `0x00002a` | `0x7E002A` | 8-bit | #853 Cosmic Climax; #858 Riding a Thin Line |
| `0x0000fd` | `0x7E00FD` | 8-bit | #5164 Twin Powers Activate!; #5165 BioShock |
| `0x00033a` | `0x7E033A` | 8-bit | #5138 The Peppy Special; #5160 Look Pepper, No Wings! |
| `0x000396` | `0x7E0396` | 8-bit | #853 Cosmic Climax; #858 Riding a Thin Line; #877 The Final Goal |
| `0x0014d8` | `0x7E14D8` | bit6, bit5, bit7 | #853 Cosmic Climax; #854 Star Fox's Beginner Victory; #858 Riding a Thin Line; #860 Star Fox's Intermediate Victory; #877 The Final Goal; #878 Star Fox's Expert Victory |
| `0x0014d9` | `0x7E14D9` | bit0 | #5164 Twin Powers Activate! |
| `0x0014da` | `0x7E14DA` | bit4 | #5165 BioShock |
| `0x001503` | `0x7E1503` | 8-bit | #5138 The Peppy Special |
| `0x00157a` | `0x7E157A` | 16-bit | #5167 Jackpot! |
| `0x0015af` | `0x7E15AF` | 8-bit | #5158 Powerful Payload |
| `0x0015ba` | `0x7E15BA` | 8-bit | #851 Crushing the Crusher I; #849 Shoot the Core!; #850 Our Last Dance; #852 Phantron of the Space Opera; #855 Crushing the Crusher II; #856 Hangar Out to Dry; #857 Lean, Mean, Lernaean Machine; #859 More than Scrap Metal; #872 Cutting-Edge Technology; #873 Protect Your Necks; #874 Particle Acceleration; #875 Now In Rotation; #876 Taking Command; #5161 Corneria Champion |
| `0x0016bd` | `0x7E16BD` | 8-bit | #5167 Jackpot! |
| `0x0016be` | `0x7E16BE` | 8-bit | #5167 Jackpot! |
| `0x0016d8` | `0x7E16D8` | 8-bit | #880 Welcome to Warp Zone!; #892 1993: A Strange Odyssey; #2362 Hare-Raising Endurance; #5167 Jackpot! |
| `0x0016da` | `0x7E16DA` | 8-bit | #880 Welcome to Warp Zone!; #892 1993: A Strange Odyssey; #2362 Hare-Raising Endurance; #5167 Jackpot! |
| `0x0016db` | `0x7E16DB` | 8-bit | #880 Welcome to Warp Zone!; #892 1993: A Strange Odyssey; #2362 Hare-Raising Endurance; #5167 Jackpot!; #5163 Roger, Falco |
| `0x0016f9` | `0x7E16F9` | 16-bit | #853 Cosmic Climax; #858 Riding a Thin Line |
| `0x00175f` | `0x7E175F` | 8-bit | #2362 Hare-Raising Endurance |
| `0x00189c` | `0x7E189C` | 16-bit | #5153; #5154; #5155; #5162; #5156; #5157; #5159; #5179; #5163 |
| `0x001fbf` | `0x7E1FBF` | 8-bit | #5161 Corneria Champion; #5166 Liberator of Lylat |
| `0x001fc0` | `0x7E1FC0` | 8-bit | #5166 Liberator of Lylat |
| `0x001fc1` | `0x7E1FC1` | 8-bit | #5166 Liberator of Lylat |
| `0x001fc2` | `0x7E1FC2` | 8-bit | #5166 Liberator of Lylat |
| `0x001fc3` | `0x7E1FC3` | 8-bit | #5166 Liberator of Lylat |
| `0x001fc4` | `0x7E1FC4` | 8-bit | #877 The Final Goal; #5166 Liberator of Lylat |
| `0x001fc5` | `0x7E1FC5` | 8-bit | #5166 Liberator of Lylat |
| `0x001ff9` | `0x7E1FF9` | 16-bit | #851 Crushing the Crusher I; #849 Shoot the Core!; #850 Our Last Dance; #852 Phantron of the Space Opera; #853 Cosmic Climax; #854 Star Fox's Beginner Victory; #855 Crushing the Crusher II; #856 Hangar Out to Dry; #857 Lean, Mean, Lernaean Machine; #859 More than Scrap Metal; #858 Riding a Thin Line; #860 Star Fox's Intermediate Victory; #872 Cutting-Edge Technology; #873 Protect Your Necks; #874 Particle Acceleration; #875 Now In Rotation; #876 Taking Command; #877 The Final Goal; #878 Star Fox's Expert Victory; #5161 Corneria Champion |
| `0x00a05a` | `0x7EA05A` | 8-bit | #5138 The Peppy Special; #880 Welcome to Warp Zone!; #892 1993: A Strange Odyssey; #2362 Hare-Raising Endurance; #5167 Jackpot! |

## Implication for Quick Win #14

The current set does not require a second RA memory region: every observed achievement operand is within the standard logical SNES WRAM window. The minimal adapter can therefore remain bounded to `0x000000..0x01FFFF` for the first proof.

## Regeneration note

The achievement set is external, mutable data. Before official release or Hardcore approval, fetch the live set through an approved RetroAchievements API/client flow and compare its address inventory with this snapshot.
