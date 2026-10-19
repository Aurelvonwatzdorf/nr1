#!/usr/bin/env bash
# Baut das Spiel als echte Mac-App (die fertige Version ohne Testhilfen):
#   ./game/tools/mac_app_bauen.sh          (vom Ordner nr1 aus)
# Holt den neuesten Stand, lädt beim ersten Mal die Export-Vorlagen von Godot
# (ca. 1,3 GB, nur einmal), baut build/Spiegelrealitäten.app und startet sie.
# Auf Linux (Cloud) entsteht stattdessen build/Spiegelrealitaeten.zip.

set -u
cd "$(dirname "$0")/../.." || exit 1   # in den Ordner nr1/

if [ -n "${GODOT:-}" ]; then
	godot_bin="$GODOT"
elif command -v godot >/dev/null 2>&1; then
	godot_bin="godot"
elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
	godot_bin="/Applications/Godot.app/Contents/MacOS/Godot"
else
	echo "Godot nicht gefunden. Setze z. B.: export GODOT=/Pfad/zu/Godot"
	exit 2
fi

echo "== 1. Neuesten Stand holen =="
git pull --ff-only || echo "   (Holen ging nicht, ich baue den Stand, der hier liegt.)"

echo "== 2. Export-Vorlagen =="
./game/tools/vorlagen_holen.sh "$godot_bin" macos || exit 1

echo "== 3. Spiel bauen =="
mkdir -p build
"$godot_bin" --headless --path game --import >/dev/null 2>&1
if [ "$(uname)" = "Darwin" ]; then
	target="build/Spiegelrealitäten.app"
	rm -rf "$target"
else
	target="build/Spiegelrealitaeten.zip"
fi
# Der Pfad ist relativ zum Ordner game/.
if ! "$godot_bin" --headless --path game --export-release "macOS" "../$target" >build/export.log 2>&1 || [ ! -e "$target" ]; then
	echo "   FEHLER beim Bauen. Die letzten Zeilen:"
	grep -iE "error|fehler" build/export.log | tail -n 10
	exit 1
fi
echo "   fertig: $target"

if [ "$(uname)" = "Darwin" ]; then
	xattr -cr "$target" 2>/dev/null
	echo "== 4. Spiel starten =="
	open "$target"
	echo ""
	echo "FERTIG. Die App liegt in nr1/build/. Du kannst sie in den Ordner"
	echo "„Programme“ ziehen und von dort wie jedes Spiel starten."
fi
