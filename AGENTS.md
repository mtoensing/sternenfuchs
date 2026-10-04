# AGENTS.md

## Commit attribution

Every commit in this repository must be authored as the repository owner
(the local `git config user.name`/`user.email`, using the GitHub noreply
address), never as "claude" or any AI assistant identity.
Do not add a `Co-Authored-By: Claude ...` (or similar AI) trailer to commit
messages or pull request descriptions in this repo, even if a default
attribution convention would otherwise add one.

## Branching in this repo

Changes to this repository (`mtoensing/sternenfuchs`) are pushed straight to
`main`. Do not open pull requests against it.

## Publishing the port (PortMaster-MV)

The port is distributed through the PortMaster-MV repository, not through this
one. The page https://portmaster.games/detail.html?name=sternenfuchs is built
from that repository's `ports/sternenfuchs/` folder (`port.json` for title,
description and "Instructions"; `README.md` for the Notes, Controls and
Compiling sections). Editing files here changes nothing on the page until the
same change is merged there.

- Upstream: `PortsMaster-MV/PortMaster-MV-New`. Our fork:
  `mtoensing/PortMaster-MV-New`. Locally it is cloned in
  `~/Documents/Dev/mv-pr/repo` (`origin` = fork, add `upstream` = the repo
  above).
- Sources of truth for the port files are in this repo under
  `portmaster/sternenfuchs/`. They map to `ports/sternenfuchs/` in the MV repo:
  `README.md`, `port.json`, `Sternenfuchs.sh`, `gameinfo.xml`, `cover.png` and
  `screenshot.png` go to the top level; everything else (binaries, `libs.aarch64`,
  `licenses/`, `prototype-pregame.cfg`, `your rom here.txt`) goes to the inner
  `ports/sternenfuchs/sternenfuchs/` folder.
- To update the page: branch from `upstream/main` in the clone, copy only the
  files that changed, push the branch to the fork and open a PR with
  `gh pr create --repo PortsMaster-MV/PortMaster-MV-New --head mtoensing:<branch>`.
  Earlier PRs (#154-#157, #160) are good examples: short description, list of
  what changed, what was tested.
- Do not overwrite MV-only differences when copying (for example
  `"availability"` in `port.json` and the binaries). Diff before copying.
- Binary releases are built with `scripts/build-arm64.sh`, which also produces
  `dist/sternenfuchs-pr.zip` (the submission layout).
- Author and attribution rules above apply to the MV PRs as well.

## ROM and user-facing text

- No ROM or ROM-derived data is ever committed. Users supply their own
  Star Fox/Starwing `.sfc`/`.smc` in `ports/sternenfuchs/` on the device.
- `portmaster/sternenfuchs/your rom here.txt` marks that spot and is shipped
  in the port folder. Keep it, `port.json` ("inst") and the port README in sync
  when the ROM instructions change.
- Link Star Fox Enhanced at its current upstream,
  https://github.com/kandowontu2/starfox-enhanced. The old
  `kandowontu/starfox-enhanced` repository was deleted; do not link it or the
  Software Heritage archive.
