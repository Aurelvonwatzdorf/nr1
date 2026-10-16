#!/bin/bash
# Cloud-Sitzungen: Godot 4.7.2 (offizieller Build, ca. 80 MB) bereitstellen,
# damit `./game/tools/run_tests.sh` sofort läuft. Auf dem Mac passiert nichts.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GODOT_VERSION="4.7.2-stable"
INSTALL_DIR="$HOME/.local/godot/$GODOT_VERSION"
BINARY="$INSTALL_DIR/Godot_v${GODOT_VERSION}_linux.x86_64"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"

# Schon ein passendes Godot da? Dann nichts tun.
if command -v godot >/dev/null 2>&1 && godot --version 2>/dev/null | grep -q "^4\.7\."; then
  exit 0
fi

if [ ! -x "$BINARY" ]; then
  mkdir -p "$INSTALL_DIR"
  tmp_zip="$(mktemp --suffix=.zip)"
  curl -sSL --retry 3 --max-time 600 -o "$tmp_zip" "$URL"
  unzip -q -o "$tmp_zip" -d "$INSTALL_DIR"
  rm -f "$tmp_zip"
  chmod +x "$BINARY"
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$BINARY" "$HOME/.local/bin/godot"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
echo "Godot bereit: $("$BINARY" --version 2>/dev/null | head -n 1)" >&2
