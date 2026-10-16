#!/usr/bin/env bash
# Startet alle Prüfungen des Spiels mit einem Befehl (Mac, Linux, Cloud):
#   ./game/tools/run_tests.sh          (vom Ordner nr1 aus)
# Godot wird so gesucht: Umgebungsvariable GODOT, dann `godot` im PATH, dann
# die Mac-App unter /Applications. Ergebnis: Exit 0 = alles grün.

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

echo "Godot: $("$godot_bin" --version 2>/dev/null | head -n 1)"
log_dir="$(mktemp -d)"
failed=0

echo "1/4 Import und Skriptfehler …"
# Der erste Import nach einem Godot-Wechsel bricht manchmal ab; dann einmal neu.
if ! "$godot_bin" --headless --path . --import >"$log_dir/import.log" 2>&1; then
	"$godot_bin" --headless --path . --import >"$log_dir/import.log" 2>&1
fi
"$godot_bin" --headless --path . --quit >"$log_dir/load.log" 2>&1
if grep -E "SCRIPT ERROR|Parse Error" "$log_dir/import.log" "$log_dir/load.log" >/dev/null; then
	echo "   FEHLER: Skriptfehler gefunden:"
	grep -hE "SCRIPT ERROR|Parse Error" "$log_dir/import.log" "$log_dir/load.log" | head -n 10
	failed=1
else
	echo "   ok"
fi

step=2
for test in smoke_test city_test reality_test; do
	echo "$step/4 $test …"
	"$godot_bin" --headless --path . "res://tests/$test.tscn" >"$log_dir/$test.log" 2>&1
	code=$?
	if [ $code -eq 0 ]; then
		echo "   ok ($(grep -c '^\[OK\]' "$log_dir/$test.log") Prüfungen)"
	else
		echo "   FEHLER (Exit $code):"
		grep -E "^\[FEHLER\]|SCRIPT ERROR|Parse Error" "$log_dir/$test.log" | head -n 10
		failed=1
	fi
	step=$((step + 1))
done

echo ""
if [ $failed -eq 0 ]; then
	echo "ALLES GRÜN – du kannst committen."
	rm -rf "$log_dir"
else
	echo "NICHT GRÜN – nicht committen. Logs: $log_dir"
fi
exit $failed
