#!/usr/bin/env bash
# Upstream was deleted on 2026-09-28; the pinned commit is archived at
# https://archive.softwareheritage.org/swh:1:rev:6612cb05e4bda0a5e25e8e805d64d0e3db50896a;origin=https://github.com/kandowontu/starfox-enhanced
# Point STARFOX_REPO at a local clone or mirror that contains the commit.
STARFOX_REPO="${STARFOX_REPO:-https://github.com/kandowontu/starfox-enhanced.git}"
STARFOX_COMMIT="6612cb05e4bda0a5e25e8e805d64d0e3db50896a"

SDL_SHIM_REPO="https://github.com/bmdhacks/SDL.git"
SDL_SHIM_COMMIT="6057d79baf8321bf190479a699655f06cc2a962f"

SPIRV_CROSS_REPO="https://github.com/KhronosGroup/SPIRV-Cross.git"
