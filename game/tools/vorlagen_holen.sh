#!/usr/bin/env bash
# Lädt die Export-Vorlagen von Godot (einmalig ca. 1,3 GB) und legt die
# gewünschten Plattformen dorthin, wo Godot sie sucht. Wird von
# mac_app_bauen.sh und iphone_bauen.sh benutzt:
#   ./game/tools/vorlagen_holen.sh <godot-programm> macos ios
set -u
godot_bin="$1"
shift

# z. B. „4.7.2.stable.official.ed1daf0bf“ → Ordner „4.7.2.stable“, Tag „4.7.2-stable“
full_version="$("$godot_bin" --version 2>/dev/null | head -n 1)"
version="$(echo "$full_version" | cut -d. -f1-4)"
tag="$(echo "$version" | sed 's/\.\([a-z]*\)$/-\1/')"
if [ "$(uname)" = "Darwin" ]; then
	template_dir="$HOME/Library/Application Support/Godot/export_templates/$version"
else
	template_dir="$HOME/.local/share/godot/export_templates/$version"
fi

missing=()
for platform in "$@"; do
	[ -f "$template_dir/$platform.zip" ] || missing+=("templates/$platform.zip")
done
if [ ${#missing[@]} -eq 0 ]; then
	echo "   Vorlagen für Godot $version: schon da"
	exit 0
fi

echo "   Lade einmalig die Vorlagen für Godot $version (ca. 1,3 GB, ein paar Minuten) …"
tmp="$(mktemp -d)"
url="https://github.com/godotengine/godot/releases/download/$tag/Godot_v${tag}_export_templates.tpz"
if ! curl -fL --progress-bar -o "$tmp/templates.tpz" "$url"; then
	echo "   FEHLER: Download fehlgeschlagen ($url)"
	rm -rf "$tmp"
	exit 1
fi
unzip -o -q "$tmp/templates.tpz" "${missing[@]}" "templates/version.txt" -d "$tmp"
mkdir -p "$template_dir"
cp "$tmp"/templates/* "$template_dir/"
rm -rf "$tmp"
echo "   fertig"
