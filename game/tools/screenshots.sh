#!/usr/bin/env bash
# Macht Screenshots von festen Orten im Spiel (Mac, Linux, Cloud):
#   ./game/tools/screenshots.sh            alle Bilder
#   SHOT=schrein ./game/tools/screenshots.sh   nur Bilder, deren Name "schrein" enthält
# Die Bilder landen in nr1/screenshots/mac/ bzw. nr1/screenshots/cloud/. Auf dem Mac öffnet sich dafür kurz ein
# Spielfenster (nicht anklicken, es schließt sich selbst).

set -u
cd "$(dirname "$0")/.." || exit 1   # in den Ordner game/

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

"$godot_bin" --headless --path . --import >/dev/null 2>&1
if [ "$(uname)" = "Linux" ] && [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
	# Cloud ohne Bildschirm: virtueller Bildschirm, einfacher Grafikmodus.
	xvfb-run -a -s "-screen 0 1600x900x24" "$godot_bin" --path . --rendering-driver opengl3 \
		--resolution 1600x900 res://tools/screenshot_tour.tscn 2>&1 | grep -E "Bild gespeichert|SCREENSHOTS|SCRIPT ERROR"
else
	"$godot_bin" --path . --resolution 1600x900 res://tools/screenshot_tour.tscn 2>&1 | grep -E "Bild gespeichert|SCREENSHOTS|SCRIPT ERROR"
fi
