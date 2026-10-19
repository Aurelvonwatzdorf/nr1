#!/usr/bin/env bash
# Baut das Spiel fürs iPhone als Xcode-Projekt und öffnet es in Xcode:
#   ./game/tools/iphone_bauen.sh               (vom Ordner nr1 aus)
#   TEAM_ID=ABCDE12345 ./game/tools/iphone_bauen.sh   (Team gleich eintragen)
# Danach in Xcode: iPhone anschließen, oben das iPhone wählen, ▶ drücken.
# Braucht Xcode (kostenlos im App Store) und eine Apple-ID.

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

if [ "$(uname)" = "Darwin" ] && [ ! -d "/Applications/Xcode.app" ]; then
	echo "Xcode fehlt. Bitte zuerst „Xcode“ aus dem App Store installieren"
	echo "(kostenlos, groß), einmal starten, Bedingungen bestätigen, dann diesen"
	echo "Befehl noch einmal ausführen."
	exit 2
fi

echo "== 1. Neuesten Stand holen =="
git pull --ff-only || echo "   (Holen ging nicht, ich baue den Stand, der hier liegt.)"

echo "== 2. Export-Vorlagen =="
./game/tools/vorlagen_holen.sh "$godot_bin" ios || exit 1

echo "== 3. Xcode-Projekt bauen =="
rm -rf build/ios
mkdir -p build/ios
"$godot_bin" --headless --path game --import >/dev/null 2>&1
# Der Pfad ist relativ zum Ordner game/.
if ! "$godot_bin" --headless --path game --export-release "iOS" "../build/ios/Spiegelrealitaeten.ipa" >build/ios_export.log 2>&1 \
		|| [ ! -d "build/ios/Spiegelrealitaeten.xcodeproj" ]; then
	echo "   FEHLER beim Bauen. Die letzten Zeilen:"
	grep -iE "error|fehler" build/ios_export.log | tail -n 10
	exit 1
fi
project="build/ios/Spiegelrealitaeten.xcodeproj/project.pbxproj"
# Zum Ausprobieren auf dem eigenen iPhone reicht die Entwickler-Signatur.
sed -i.bak 's/"Apple Distribution"/"Apple Development"/g' "$project"
if [ -n "${TEAM_ID:-}" ]; then
	sed -i.bak "s/DEVELOPMENT_TEAM = [A-Za-z0-9]*;/DEVELOPMENT_TEAM = $TEAM_ID;/g" "$project"
	echo "   Team $TEAM_ID eingetragen"
fi
rm -f "$project.bak"
echo "   fertig: build/ios/Spiegelrealitaeten.xcodeproj"

if [ "$(uname)" = "Darwin" ]; then
	echo "== 4. Xcode öffnen =="
	open "build/ios/Spiegelrealitaeten.xcodeproj"
	echo ""
	echo "In Xcode: links das blaue Projekt „Spiegelrealitaeten“ anklicken →"
	echo "„Signing & Capabilities“ → bei „Team“ dein Konto wählen. iPhone per Kabel"
	echo "anschließen, oben in der Leiste das iPhone auswählen, dann ▶ drücken."
fi
