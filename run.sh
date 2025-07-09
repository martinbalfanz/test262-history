#!/usr/bin/env sh

set -e

mkdir -p data
mkdir -p docs
mkdir -p snapshots

SUBMODULE_DIR="data-source"
SNAPSHOT_DIR="snapshots"

HISTORY_FILE="${SUBMODULE_DIR}/history.json"
OLD_HASH=""
if [ -f "$HISTORY_FILE" ]; then
  OLD_HASH=$(sha256sum "$HISTORY_FILE" | cut -d ' ' -f1)
fi

TODAY=$(date +%Y-%m-%d)
TODAY_SNAPSHOT="${SNAPSHOT_DIR}/${TODAY}"

git submodule update --remote --merge

NEW_HASH=$(sha256sum "$HISTORY_FILE" | cut -d ' ' -f1)
LATEST_SNAPSHOT=$(find "$SNAPSHOT_DIR" -type d -maxdepth 1 -mindepth 1 | sort | tail -n 1)

if [ -n "$LATEST_SNAPSHOT" ]; then
    echo "Comparing to latest snapshot: $LATEST_SNAPSHOT"
    if diff -qr "$SUBMODULE_DIR" "$LATEST_SNAPSHOT" --exclude=".git" >/dev/null; then
        echo "No changes in data — no snapshot created."
    fi
else
    echo "No previous snapshot found — creating first one."
fi

echo "Creating new snapshot at $TODAY_SNAPSHOT..."
mkdir -p "$TODAY_SNAPSHOT"
rsync -a --exclude='.git' "$SUBMODULE_DIR/" "$TODAY_SNAPSHOT/"

echo "Snapshot saved!"

source .venv/bin/activate && python app.py

if [ "$OLD_HASH" != "$NEW_HASH" ] || [ -d "snapshots/$TODAY" ]; then
  git add data/ docs/ snapshots/
  git commit -m "$(date +'%Y-%m-%d') data update"
  git push
  echo "Changes committed and pushed."
else
  echo "No changes to history.json — skipping commit."
fi
