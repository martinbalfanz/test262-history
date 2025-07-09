#!/usr/bin/env sh

set -e

mkdir -p data
mkdir -p docs

HISTORY_FILE="data/history.json"
OLD_HASH=""
if [ -f "$HISTORY_FILE" ]; then
  OLD_HASH=$(sha256sum "$HISTORY_FILE" | cut -d ' ' -f1)
fi

wget -q -O "$HISTORY_FILE" https://raw.githubusercontent.com/test262-fyi/data/refs/heads/gh-pages/history.json
NEW_HASH=$(sha256sum "$HISTORY_FILE" | cut -d ' ' -f1)

source .venv/bin/activate && python app.py

if [ "$OLD_HASH" != "$NEW_HASH" ]; then
  git add data/
  git commit -m "$(date +'%Y-%m-%d') data update"
  git push
  echo "Changes committed and pushed."
else
  echo "No changes to history.json — skipping commit."
fi
