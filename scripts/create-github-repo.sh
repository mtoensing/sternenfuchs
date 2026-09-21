#!/usr/bin/env bash
set -euo pipefail
OWNER="mtoensing"
REPO="sternenfuchs"

command -v gh >/dev/null || { echo "GitHub CLI (gh) is required."; exit 1; }
gh auth status

if ! gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  gh repo create "$OWNER/$REPO" --public \
    --description "ARM64 Linux / PortMaster prototype for Star Fox Enhanced"
fi

git init
git checkout -B prototype/rg40xx
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$OWNER/$REPO.git"
git add .
git commit -m "chore: bootstrap sternenfuchs RG40XX prototype" || true
git push -u origin prototype/rg40xx
