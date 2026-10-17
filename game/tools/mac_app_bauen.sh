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

# z. B. „4.7.2.stable.official.ed1daf0bf“ → Ordner „4.7.2.stable“, Tag „4.7.2-stable“
full_version="$("$godot_bin" --version 2>/dev/null | head -n 1)"
version="$(echo "$full_version" | cut -d. -f1-4)"
tag="$(echo "$version" | sed 's/\.\([a-z]*\)$/-\1/')"
if [ "$(uname)" = "Darwin" ]; then
	template_dir="$HOME/Library/Application Support/Godot/export_templates/$version"
else
	template_dir="$HOME/.local/share/godot/export_templates/$version"
fi

echo "== 2. Export-Vorlagen für Godot $version =="
if [ -f "$template_dir/macos.zip" ]; then
	echo "   schon da"
else
	echo "   Lade einmalig ca. 1,3 GB herunter, das dauert ein paar Minuten …"
	tmp="$(mktemp -d)"
	url="https://github.com/godotengine/godot/releases/download/$tag/Godot_v${tag}_export_templates.tpz"
	if ! curl -fL --progress-bar -o "$tmp/templates.tpz" "$url"; then
		echo "   FEHLER: Download fehlgeschlagen ($url)"
		rm -rf "$tmp"
		exit 1
	fi
	unzip -o -q "$tmp/templates.tpz" "templates/macos.zip" "templates/version.txt" -d "$tmp"
	mkdir -p "$template_dir"
	cp "$tmp/templates/macos.zip" "$tmp/templates/version.txt" "$template_dir/"
	rm -rf "$tmp"
	echo "   fertig"
fi

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
