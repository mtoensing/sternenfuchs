# Exact references

## Star Fox Enhanced
- https://github.com/kandowontu/starfox-enhanced
- pinned commit: `6612cb05e4bda0a5e25e8e805d64d0e3db50896a`
- build: `docs/BUILDING.md`
- root build logic: `CMakeLists.txt`
- settings/controller handling: `src/app/runtime_input.cpp`
- runtime: `src/app/starfox_pc.cpp`

## PortMaster
- https://github.com/PortsMaster/PortMaster-New
- mandatory AI guidance: `AGENTS.md`
- packaging docs: https://portmaster.games/packaging.html
- SDL3/SDL2 reference ports:
  - `ports/openchaos/Open Chaos.sh`
  - `ports/openchaos/README.md`
  - `ports/insaniquarium/Insaniquarium Deluxe.sh`
  - `ports/insaniquarium/README.md`
- native-decomp reference:
  - https://github.com/monkeyx-net/PortMaster-Build-Templates
  - `new_ports/spaghettikart/`
  - `recipes/ports/spaghettikart/build.sh`
  - `.github/workflows/build_recipe.yml`

## SDL3 -> device SDL2 shim
- https://github.com/bmdhacks/SDL
- branch origin: `sdl2-backend`
- pinned commit: `6057d79baf8321bf190479a699655f06cc2a962f`
- The shim delegates video/audio/gamepad to the target device's SDL2.
