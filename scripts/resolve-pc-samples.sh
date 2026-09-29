#!/usr/bin/env bash
# Aggregates a STARFOX_TRACE_PC sample file (from the device) by phase and
# symbol. Phases: 0 other, 1 logic tick, 2 audio, 3 background, 4 world,
# 5 composite, 6 present. The binary must be the exact one that produced the
# samples (unstripped).
# Usage: resolve-pc-samples.sh samples.txt starfox.aarch64 [top-N]
set -euo pipefail
SAMPLES="${1:?samples file}"; BIN="$(cd "$(dirname "${2:?binary}")" && pwd)/$(basename "$2")"; TOP="${3:-12}"
NM="$(mktemp)"; trap 'rm -f "$NM"' EXIT
docker run --rm -v "$(dirname "$BIN")":/b sternenfuchs-dev:22.04 \
  nm -C -n --defined-only "/b/$(basename "$BIN")" > "$NM"
python3 - "$SAMPLES" "$NM" "$TOP" <<'PY'
import sys, bisect, collections
samples, nmfile, top = sys.argv[1], sys.argv[2], int(sys.argv[3])
addrs, names = [], []
for line in open(nmfile):
    p = line.rstrip("\n").split(" ", 2)
    if len(p) == 3 and p[1] in "tTwW":
        addrs.append(int(p[0], 16)); names.append(p[2])
phase_names = {0:"other",1:"logic-tick",2:"audio",3:"background",4:"world",5:"composite",6:"present"}
per = collections.defaultdict(collections.Counter); total = collections.Counter()
for line in open(samples):
    f = line.split(" ", 3)
    if len(f) < 4: continue
    phase, mod, off, sym = int(f[0]), f[1], int(f[2], 16), f[3].strip()
    if mod.startswith("starfox"):
        i = bisect.bisect_right(addrs, off) - 1
        sym = names[i] if i >= 0 else "?"
    else:
        sym = f"[{mod}] {sym}"
    per[phase][sym[:110]] += 1; total[phase] += 1
grand = sum(total.values())
print(f"{grand} samples (~{grand} ms of game-thread CPU)")
for ph in sorted(total, key=lambda k: -total[k]):
    print(f"\n== {phase_names.get(ph, ph)}: {total[ph]} samples ({100*total[ph]/grand:.0f}%)")
    for sym, n in per[ph].most_common(top):
        print(f"  {100*n/total[ph]:5.1f}%  {n:6d}  {sym}")
PY
