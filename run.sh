#!/usr/bin/env sh

set -e

git pull

mkdir -p data
mkdir -p docs
mkdir -p snapshots

SUBMODULE_DIR="data-source"
SNAPSHOT_DIR="snapshots"

OLD_HASH=$(git -C data-source rev-parse HEAD)

TODAY=$(date +%Y-%m-%d)
TODAY_SNAPSHOT="${SNAPSHOT_DIR}/${TODAY}"

git pull
git submodule update --remote

NEW_HASH=$(git -C data-source rev-parse HEAD)

if [ "$OLD_HASH" != "$NEW_HASH" ]; then
  mkdir -p "$TODAY_SNAPSHOT"
  rsync -a --quiet --exclude='.git' "$SUBMODULE_DIR/" "$TODAY_SNAPSHOT/"

  . .venv/bin/activate && python app.py
  git add data/ docs/ snapshots/ data-source/
  git commit -m "$(date +'%Y-%m-%d') data update"
  git push
  echo "Changes committed and pushed."
else
  echo "No changes in data source — skipping commit."
fi
