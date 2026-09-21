# Sternenfuchs — implementation task

Do not restart broad research. The architecture decisions are already made.

## Goal

Create/use `mtoensing/sternenfuchs` and get the pinned Star Fox Enhanced source running as a native aarch64 PortMaster prototype on the real Anbernic RG40XX H.

## Fixed inputs

- GitHub owner: `mtoensing`
- Repository: `mtoensing/sternenfuchs`
- Target: Anbernic RG40XX H
- SoC: H700
- Architecture: aarch64
- RAM: 1 GB
- Display: 640x480
- Firmware on test device: KNULLI
- Test device: `192.168.178.76`
- SSH: `root@192.168.178.76:22`
- KNULLI default root password: `linux`
- If that password fails, read the current password on the device at:
  `System Settings -> Security -> Root password`
- SSH must be enabled at:
  `System Settings -> Services -> SSH`
- Persistent KNULLI storage: `/userdata`
- Prototype PortMaster path: `/userdata/roms/ports`

Pinned revisions are in `scripts/versions.sh`. Do not update them during bring-up.

## Execute

1. Put these bootstrap files in a git working tree.
2. Run `./scripts/create-github-repo.sh`.
3. Push branch `prototype/rg40xx`.
4. Make `.github/workflows/build-arm64.yml` pass.
5. Download/extract its artifact so `dist/sternenfuchs.zip` exists locally.
6. Run `./scripts/setup-ssh.sh` once for key-based access.
7. Run `./scripts/deploy-rg40xx.sh`.
8. Ensure the user's legally obtained supported Star Fox/Starwing `.sfc` or `.smc`
   ROM is in `/userdata/roms/ports/sternenfuchs/`.
   Never commit ROMs or `Starfox-Assets.BIN`.
9. Run `./scripts/smoke-rg40xx.sh`.
10. Run `./scripts/fetch-rg40xx-log.sh`.
11. Fix only the smallest real CI/device blocker and repeat.
12. Once the automated smoke starts cleanly, launch from KNULLI's Ports menu and
    verify menu, controller, audio and one playable level.

## Decisions already made

- Use a native ARM64 GitHub runner with an Ubuntu 22.04 container to avoid an
  unnecessarily new glibc baseline.
- Start at 640x480, 4:3, software renderer, render scale 1x, 60 FPS presentation,
  expensive effects off.
- The initial `pregame.cfg` is supplied by this bootstrap.
- Prefer PortMaster's patched device SDL2 via the pinned `bmdhacks/SDL`
  SDL3-to-SDL2 backend shim.
- Do not begin with Vulkan.
- Do not begin with WestonPack.
- Do not bundle/replace SDL2, libc, libstdc++, graphics drivers, libGL/libEGL,
  or other CFW core libraries.
- Do not add controller hacks unless native SDL gamepad input actually fails.
- Do not refactor unrelated upstream code.
- Do not submit a PortMaster PR before real hardware gameplay works.

## If blocked

Read `SOURCES.md`, then inspect only the exact source relevant to the observed error.

## Keep responses tiny

```text
Build: PASS/FAIL — <one line>
Deploy: PASS/FAIL — <one line>
Device: PASS/FAIL — <one line>
Changed: <files/commit>
Next: <single next action>
```
